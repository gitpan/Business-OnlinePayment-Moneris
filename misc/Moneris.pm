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
#  $Header: /home/cvs/moneris_payment/misc/Moneris.pm,v 0.3 2004/10/10 15:49:10 cvs Exp $
#
#  $Log: Moneris.pm,v $
#  Revision 0.3  2004/10/10 15:49:10  cvs
#  Clean up and add documentation
#
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


( $VERSION ) = '$Revision: 0.3 $ ' =~ /\$Revision:\s+([^\s]+)/;


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

#########################################################################################33
# End of class

1;
__END__



=head1 AUTHOR

Duane Hinkley, <F<duane@dhwd.com>>

L<http://www.dhwd.com>

If you have any questions, comments or suggestions please feel free 
to contact me.

=head1 COPYRIGHT

Copyright 2004, Down Home Web Design, Inc.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AVAILABILITY

The latest version of this module is likely to be available from CPAN
as well as:

http://www.dhwd.com/


1;

