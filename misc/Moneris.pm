#!/usr/bin/perl
################################################################################
#
#  Script Name : Moneris.pm
#  Version     : 1
#  Company     : Down Home Web Design, Inc
#  Author      : Duane Hinkley ( duane@dhwd.com )
#  Website     : www.DownHomeWebDesign.com
#
#  Description: A custom self contained module to calculate UPS rates using the
#               newer XML method.  This module properly calulates rates between
#               and within other non-US countries including Canada.
#               
#  Copyright (c) 2003-2004 Down Home Web Design, Inc.  All rights reserved.
#
#  $Header: /home/cvs/moneris_payment/misc/Moneris.pm,v 0.2 2004/09/29 02:48:02 cvs Exp $
#
#  $Log: Moneris.pm,v $
#  Revision 0.2  2004/09/29 02:48:02  cvs
#  Added customer info and OnlinePayment version
#
#  Revision 0.1  2004/09/28 15:13:06  cvs
#  Initial version
#
#  Revision 0.01  2004/09/27 19:45:47  cvs
#  Setting version
#
#  Revision 0.01  2004/09/27 19:44:33  cvs
#  This version works
#
#
#
################################################################################

package Vend::Payment::Moneris;

use Business::OnlinePayment::Moneris::Adaptor;

use strict;
use vars qw($VERSION);


'$Revision: 0.2 $' =~ /([0-9]{1,}\.[0-9]{1,})/;
$VERSION = $1;


BEGIN {

	eval {
		package Vend::Payment;
		require Business::OnlinePayment::Moneris::Adaptor;
	};

}

package Vend::Payment;
use strict;

sub moneris {

	my ($user, $amount) = @_;

	my $opt;
	my $secret;
	my $test;
	my $auth_code;
	my $total_cost;
	
	if(ref $user) {
		$opt = $user;
		$user = $opt->{id} || undef;
		$secret = $opt->{secret} || undef;
		$test = $opt->{test} || undef;
		$auth_code = $opt->{auth_code} || undef;
		$total_cost = $opt->{total_cost} || undef;
	}
	else {
		$opt = {};
	}
	
	my $actual;

	if ( $opt->{actual }) {

		$actual = $opt->{actual};
	}
	else {
		my (%actual) = map_actual();
		$actual = \%actual;
	}

# ::logDebug("actual map result: " . ::uneval($actual));

	if (! $user ) {
		$user    =  charge_param('id')
						or return (
							MStatus => 'failure-hard',
							MErrMsg => 'No account id',
							);
	}

	$secret    =  charge_param('secret') if ! $secret;


	my $precision = $opt->{precision} 
                    || 2;

	my $referer   =  $opt->{referer}
					|| charge_param('referer');

	my @override = qw/
						order_id
						auth_code
						mv_credit_card_exp_month
						mv_credit_card_exp_year
						mv_credit_card_number
					/;
	for(@override) {
		next unless defined $opt->{$_};
		$actual->{$_} = $opt->{$_};
	}

	## Moneris does things a bit different, ensure we are OK
	$actual->{mv_credit_card_exp_month} =~ s/\D//g;
    $actual->{mv_credit_card_exp_month} =~ s/^0+//;
    $actual->{mv_credit_card_exp_year} =~ s/\D//g;
    $actual->{mv_credit_card_exp_year} =~ s/\d\d(\d\d)/$1/;

    $actual->{mv_credit_card_number} =~ s/\D//g;

    my $exp = sprintf '%02d%02d',
                        $actual->{mv_credit_card_exp_year},
                        $actual->{mv_credit_card_exp_month};

	# Using mv_payment_mode for compatibility with older versions, probably not
	# necessary.
	$opt->{transaction} ||= 'sale';
	my $transtype = $opt->{transaction};

	my %type_map = (
		AUTH_ONLY				=>	'PreAuth',
		CAPTURE_ONLY			=>  'Purchase',
		CREDIT					=>	'Refund',
		PRIOR_AUTH_CAPTURE		=>	'Completion',
		VOID					=>	'Void',
		auth		 			=>	'PreAuth',
		authorize		 		=>	'PreAuth',
		mauthcapture 			=>	'PreAuth',
		mauthonly				=>	'PreAuth',
		return					=>	'Refund',
		settle_prior        	=>	'Completion',
		sale		 			=>	'Purchase',
		settle      			=>  'Completion',
		void					=>	'Void',
	);

	if (defined $type_map{$transtype}) {
        $transtype = $type_map{$transtype};
    }
 ::logDebug("transtype=$transtype");

	$amount = $opt->{total_cost} if $opt->{total_cost};
	
    if(! $amount) {
        $amount = Vend::Interpolate::total_cost();
        $amount = Vend::Util::round_to_frac_digits($amount,$precision);
    }

	my $order_id = gen_order_id($opt);

# ::logDebug("auth_code=$actual->{auth_code} order_id=$opt->{order_id}");

	my $apitoken	= $secret;
	my $storeid		= $user;

 ::logDebug("storeid=$storeid apitoken=$apitoken order_id=$order_id auth_code=$auth_code total_cost=$total_cost transtype=$transtype test=$test");
	my $mpg = new Business::OnlinePayment::Moneris::Adaptor($storeid,$apitoken,$test);

	if ( $transtype eq 'Purchase') {

		$mpg->Purchase(
						{
							order_id	=> $order_id,  
							amount		=> $amount,  
							cc_num		=> $actual->{mv_credit_card_number},  
							cc_exp		=> $exp,  
							first_name	=> $actual->{b_fname}, 
							last_name	=> $actual->{b_lname}, 
							company_name=> $actual->{b_company},
							address		=> $actual->{b_address},
							city		=> $actual->{b_city}, 
							province	=> $actual->{b_state},
							postal_code	=> $actual->{b_zip}, 
							country		=> $actual->{b_country},
							phone_number=> $actual->{phone_day}
						}
				);
	}
	elsif ( $transtype eq 'PreAuth') {

		$mpg->PreAuth(
						{
							order_id	=> $order_id,  
							amount		=> $amount,  
							cc_num		=> $actual->{mv_credit_card_number},  
							cc_exp		=> $exp,  
						}
				);
	}
	elsif ( $transtype eq 'Completion') {

		$mpg->Completion(
						{
							txn_number	=> $auth_code,  
							order_id	=> $order_id,  
							amount		=> $total_cost,  
						}
				);
	}
	elsif ( $transtype eq 'Refund') {

		$mpg->Refund(
						{
							txn_number	=> $auth_code,  
							order_id	=> $order_id,  
							amount		=> $total_cost,  
						}
				);
	}
	elsif ( $transtype eq 'Void') {

		$mpg->VoidPreAuth(
						{
							txn_number	=> $auth_code,  
							order_id	=> $order_id,  
							amount		=> $total_cost,  
						}
				);
	}

	::logDebug("Moneris Query Results:");
	::logDebug("CardType = " . $mpg->getCardType());
	::logDebug("TransAmount = " . $mpg->getTransAmount());
	::logDebug("TxnNumber = " . $mpg->getTxnNumber());
	::logDebug("ReceiptId = " . $mpg->getReceiptId());
	::logDebug("TransType = " . $mpg->getTransType());
	::logDebug("ReferenceNum = " . $mpg->getReferenceNum());
	::logDebug("ResponseCode = " . $mpg->getResponseCode());
	::logDebug("ISO = " . $mpg->getISO());
	::logDebug("Message = " . $mpg->getMessage());
	::logDebug("AuthCode = " . $mpg->getAuthCode());
	::logDebug("Complete = " . $mpg->getComplete());
	::logDebug("TransDate = " . $mpg->getTransDate());
	::logDebug("TransTime = " . $mpg->getTransTime());
	::logDebug("Ticket = " . $mpg->getTicket());
	::logDebug("TimedOut = " . $mpg->getTimedOut());

 

    # Minivend names are on the  left, Moneris on the right
	my %result;

    $result{'pop.status'}            = $mpg->getResponseCode();
    $result{'pop.error-message'}     = $mpg->getMessage();
    $result{'order-id'}              = $mpg->getReceiptId();
    $result{'pop.order-id'}          = $mpg->getReceiptId();
    $result{'pop.auth-code'}         = $mpg->getTxnNumber();
    $result{'pop.avs_code'}          = '';
    $result{'pop.avs_zip'}           = '';
    $result{'pop.avs_addr'}          = '';
    $result{'pop.cvv2_resp_code'}    = '';
   	$result{'x_response_code'}		= $mpg->getResponseCode();
   	$result{'x_response_subcode'}	= '';
   	$result{'x_response_reason_code'}= '';
   	$result{'x_response_reason_text'}= $mpg->getMessage();
   	$result{'x_auth_code'}			= $mpg->getTxnNumber();
   	$result{'x_trans_id'}			= $mpg->getTxnNumber();

::logDebug("Moneris result: " . ::uneval(\%result));

       	
#   ::logDebug(qq{moneris response_reason_text=$result{x_response_reason_text} response_code: $result{x_response_code}});    	
   
#    }

	# If there's no error message, return a one from the response codes
	#
	#if ( $result{x_response_reason_text} eq ""  ) {

	#	$result{x_response_reason_text} = $err_code->[ $result{x_response_code} ]->[ $result{x_response_reason_code} ];
	#}

    
    if ( $mpg->getTimedOut() ne 'false' ) {

 		$result{MErrMsg} = sprintf("Server Error %s: %s", $mpg->getResponseCode(), $mpg->getMessage() );
   }
    elsif ( $mpg->getResponseCode() < 50 ) {

    	$result{MStatus} = 'success';
		$result{'order-id'} ||= $opt->{order_id};
    }
	else {
    	$result{MStatus} = 'failure';
		delete $result{'order-id'};

    	$result{MErrMsg} = sprintf("Moneris error: %s. Please call in your order or try again.", $mpg->getMessage());
    }
# ::logDebug(qq{moneris result=} . uneval(\%result));    	

    return (%result);
}

package Vend::Payment::Moneris;

#########################################################################################33
# End of class

1;
__END__

=head1 NAME

Vend::Payment::Moneris - Interchange Moneris Support

=head1 SYNOPSIS

    &charge=moneris
 
        or
 
    [charge mode=moneris param1=value1 param2=value2]

=head1 PREREQUISITES

  Net::SSLeay
 
    or
  
  LWP::UserAgent and Crypt::SSLeay

Only one of these need be present and working.

=head1 DESCRIPTION

The Vend::Payment::Moneris module implements the moneris() routine
for use with Interchange. It is compatible on a call level with the other
Interchange payment modules -- in theory (and even usually in practice) you
could switch from CyberCash to Moneris with a few configuration 
file changes.

To enable this module, place this directive in C<interchange.cfg>:

    Require module Vend::Payment::Moneris

This I<must> be in interchange.cfg or a file included from it.

Make sure CreditCardAuto is off (default in Interchange demos).

The mode can be named anything, but the C<gateway> parameter must be set
to C<moneris>. To make it the default payment gateway for all credit
card transactions in a specific catalog, you can set in C<catalog.cfg>:

    Variable   MV_PAYMENT_MODE  moneris

It uses several of the standard settings from Interchange payment. Any time
we speak of a setting, it is obtained either first from the tag/call options,
then from an Interchange order Route named for the mode, then finally a
default global payment variable, For example, the C<id> parameter would
be specified by:

    [charge mode=moneris id=YourMonerisID]

or

    Route moneris id YourMonerisID

or 

    Variable MV_PAYMENT_ID      YourMonerisID

The active settings are:

=over 4

=item id

Your Moneris account ID, supplied by Moneris when you sign up.
Global parameter is MV_PAYMENT_ID.

=item secret

Your Moneris account password, supplied by Moneris when you sign up.
Global parameter is MV_PAYMENT_SECRET. This may not be needed for
actual charges.

=item referer

A valid referering url (match this with your setting on secure.Moneris).
Global parameter is MV_PAYMENT_REFERER.

=item transaction

The type of transaction to be run. Valid values are:

    Interchange         Moneris
    ----------------    -----------------
        auth            AUTH_ONLY
        return          CREDIT
        reverse         PRIOR_AUTH_CAPTURE
        sale            AUTH_CAPTURE
        settle          CAPTURE_ONLY
        void            VOID

=item remap 

This remaps the form variable names to the ones needed by Moneris. See
the C<Payment Settings> heading in the Interchange documentation for use.

=item test

Set this to C<TRUE> if you wish to operate in test mode, i.e. set the Moneris
C<x_Test_Request> query paramter to TRUE.i

Examples: 

    Route    moneris  test  TRUE
        or
    Variable   MV_PAYMENT_TEST   TRUE
        or 
    [charge mode=moneris test=TRUE]

=back

=head2 Troubleshooting

Try the instructions above, then enable test mode. A test order should complete.

Disable test mode, then test in various Moneris error modes by
using the credit card number 4222 2222 2222 2222.

Then try a sale with the card number C<4111 1111 1111 1111>
and a valid expiration date. The sale should be denied, and the reason should
be in [data session payment_error].

If nothing works:

=over 4

=item *

Make sure you "Require"d the module in interchange.cfg:

    Require module Vend::Payment::Moneris

=item *

Make sure either Net::SSLeay or Crypt::SSLeay and LWP::UserAgent are installed
and working. You can test to see whether your Perl thinks they are:

    perl -MNet::SSLeay -e 'print "It works\n"'

or

    perl -MLWP::UserAgent -MCrypt::SSLeay -e 'print "It works\n"'

If either one prints "It works." and returns to the prompt you should be OK
(presuming they are in working order otherwise).

=item *

Check the error logs, both catalog and global.

=item *

Make sure you set your payment parameters properly.  

=item *

Try an order, then put this code in a page:

    <XMP>
    [calc]
        my $string = $Tag->uneval( { ref => $Session->{payment_result} });
        $string =~ s/{/{\n/;
        $string =~ s/,/,\n/g;
        return $string;
    [/calc]
    </XMP>

That should show what happened.

=item *

If all else fails, consultants are available to help with integration for a fee.
See http://www.icdevgroup.org/ for mailing lists and other information.

=back

=head1 BUGS

There is actually nothing *in* Vend::Payment::Moneris. It changes packages
to Vend::Payment and places things there.

=head1 AUTHORS

Mark Stosberg <mark@summersault.com>.
Based on original code by Mike Heins <mike@perusion.com>.

=head1 CREDITS

    Jeff Nappi <brage@cyberhighway.net>
    Paul Delys <paul@gi.alaska.edu>
    webmaster@nameastar.net
    Ray Desjardins <ray@dfwmicrotech.com>
    Nelson H. Ferrari <nferrari@ccsc.com>

=cut


1;

