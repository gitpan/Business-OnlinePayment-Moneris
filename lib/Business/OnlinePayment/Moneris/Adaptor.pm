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
#  $Header: /home/cvs/moneris_payment/lib/Business/OnlinePayment/Moneris/Adaptor.pm,v 0.4 2004/09/29 02:47:52 cvs Exp $
#
#  $Log: Adaptor.pm,v $
#  Revision 0.4  2004/09/29 02:47:52  cvs
#  Added customer info and OnlinePayment version
#
#  Revision 0.2  2004/09/28 14:43:00  cvs
#  Integrating with Interchange
#
#  Revision 0.01  2004/09/27 19:44:33  cvs
#  This version works
#
#
#
################################################################################

package Business::OnlinePayment::Moneris::Adaptor;

use Business::OnlinePayment::Moneris::mpgTransaction;
use Business::OnlinePayment::Moneris::mpgHttpsPost;
use Business::OnlinePayment::Moneris::mpgCustInfo;

use strict;
use vars qw($VERSION);

'$Revision: 0.4 $' =~ /([0-9]{1,}\.[0-9]{1,})/;
$VERSION = $1;



sub new {

   my $type  = shift;
   my ($storeid,$apitoken,$test_mode) = @_;
   my $self  = {};

   $self->{'_storeid'}	= $storeid;
   $self->{'_apitoken'}	= $apitoken;
   $self->{'_testmode'}	= $test_mode;

   bless $self, $type;
}
sub Purchase {

   my $self  = shift;
   my ($obj) = @_;
   $self->{obj} = $obj;

	## step 1) create transaction hash ###
	my %txnArray=( 
					type		=> 'purchase',
					order_id	=> $obj->{order_id},
					cust_id		=> $obj->{cust_id},  ### this field is optional
					amount		=> $obj->{amount},
					pan			=> $obj->{cc_num},
					expdate		=> $obj->{cc_exp},
					crypt_type	=> '7'
	);

	$self->process_transaction(\%txnArray);

}
sub PreAuth {

   my $self  = shift;
   my ($obj) = @_;
   $self->{obj} = $obj;

	## step 1) create transaction hash ###
	my %txnArray=( 
					type		=> 'preauth',
					order_id	=> $obj->{order_id},
					cust_id		=> $obj->{cust_id},  ### this field is optional
					amount		=> $obj->{amount},
					pan			=> $obj->{cc_num},
					expdate		=> $obj->{cc_exp},
					crypt_type	=> '7'
	);

	$self->process_transaction(\%txnArray);


}
# Capture
#
sub Completion {

   my $self  = shift;
   my ($obj) = @_;
   $self->{obj} = $obj;

	## step 1) create transaction hash ###
	my %txnArray=( 
					type		=> 'completion',
					txn_number	=> $obj->{txn_number},
					order_id	=> $obj->{order_id},  
					comp_amount	=> $obj->{amount},
					crypt_type	=> '7'
	);

	$self->process_transaction(\%txnArray);

}
# This is a refund not a cancel to a preauthorization
#
sub Refund {

   my $self  = shift;
   my ($obj) = @_;
   $self->{obj} = $obj;

	## step 1) create transaction hash ###
	my %txnArray=( 
					type		=> 'refund',
					txn_number	=> $obj->{txn_number},
					order_id	=> $obj->{order_id},  
					amount		=> $obj->{amount},
					crypt_type	=> '7'
	);

	$self->process_transaction(\%txnArray);

}

sub Void {

   my $self  = shift;
   my ($obj) = @_;
   $self->{obj} = $obj;

	## step 1) create transaction hash ###
	my %txnArray=( 
					type		=> 'purchasecorrection',
					txn_number	=> $obj->{txn_number},
					order_id	=> $obj->{order_id},  
					crypt_type	=> '7'
	);

	$self->process_transaction(\%txnArray);

}
sub VoidPreAuth {

   my $self  = shift;
   my ($obj) = @_;
   $self->{obj} = $obj;

   $self->Completion( {
					txn_number	=> $obj->{txn_number},
					order_id	=> $obj->{order_id},  
					amount		=> $obj->{amount},
   } );


   $self->Void( {
					txn_number	=> $self->getTxnNumber(),  # Use the txn_number from the previous Completion
					order_id	=> $obj->{order_id},  
   } );


}
sub customer_info() {

	my $self = shift; 

	my $obj	= $self->{obj};

	my $mpgCustInfo = new Business::OnlinePayment::Moneris::mpgCustInfo();


	$mpgCustInfo->setEmail( $obj->{email} );

	$mpgCustInfo->setInstructions( $obj->{description} );

	my %billing = ( first_name	=> $obj->{first_name}, 
                  last_name		=> $obj->{last_name}, 
                  company_name	=> $obj->{company_name},
                  address		=> $obj->{address},
                  city			=> $obj->{city}, 
                  province		=> $obj->{province},
                  postal_code	=> $obj->{postal_code}, 
                  country		=> $obj->{country},
                  phone_number	=> $obj->{phone_number}
	);

	$mpgCustInfo->setBilling(\%billing);

	return $mpgCustInfo;
}

sub process_transaction {

 my $self = shift; 
 my ($txnRef) = @_;

	## step 2) create a transaction  object passing the hash (by reference) created in
	## step 1.



	my $mpgTxn = new Business::OnlinePayment::Moneris::mpgTransaction($txnRef);

	$mpgTxn->setCustInfo( $self->customer_info() );

	## step 3) create mpgHttpsPost object which does an https post ##
	my $mpgHttpPost = new Business::OnlinePayment::Moneris::mpgHttpsPost($self->{'_storeid'},$self->{'_apitoken'},$mpgTxn,$self->{'_testmode'});

	## step 4) get an mpgResponse object ##
	my $mpgResponse = $mpgHttpPost->getMpgResponse();

	$self->{mpgResponse} = $mpgResponse;

	## step 5) retrieve data using get methods

	 # print ("\nCardType = " . $self->getCardType());
	# print("\nTransAmount = " . $self->getTransAmount());
	# print("\nTxnNumber = " . $self->getTxnNumber());
	# print("\nReceiptId = " . $self->getReceiptId());
	# print("\nTransType = " . $self->getTransType());
	# print("\nReferenceNum = " . $self->getReferenceNum());
	# print("\nResponseCode = " . $self->getResponseCode());
	# print("\nISO = " . $self->getISO());
	# print("\nMessage = " . $self->getMessage());
	# print("\nAuthCode = " . $self->getAuthCode());
	# print("\nComplete = " . $self->getComplete());
	# print("\nTransDate = " . $self->getTransDate());
	# print("\nTransTime = " . $self->getTransTime());
	# print("\nTicket = " . $self->getTicket());
	# print("\nTimedOut = " . $self->getTimedOut());

}
sub getTerminalIDs(){

 my $self = shift; 
 return (keys(%{$self->{mpgResponse}->{termIDHash}}) );
 
}


sub getCreditCards($ecr_no){
 
 my $self = shift;
 my $ecr_no = shift;
 return (@{$self->{mpgResponse}->{cardHash}->{$ecr_no}});
}




sub getCardType(){

 my $self = shift;  
 return ($self->{mpgResponse}->{responseData}->{'CardType'});

}

sub getTransAmount(){

 my $self = shift;  
 return ($self->{mpgResponse}->{responseData}->{'TransAmount'});

}

sub getTxnNumber(){

 my $self = shift;  
 return ($self->{mpgResponse}->{responseData}->{'TransID'});

}

sub getReceiptId(){

 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'ReceiptId'});

}

sub getTransType(){
 
 my $self = shift;  
 return ($self->{mpgResponse}->{responseData}->{'TransType'});

}

sub getReferenceNum(){
 
 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'ReferenceNum'});

}

sub getResponseCode(){
 
 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'ResponseCode'});

}

sub getISO(){
 
 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'ISO'});

}

sub getBankTotals(){
 
 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'BankTotals'});

}

sub getMessage(){
 
 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'Message'});

}

sub getAuthCode(){
 
 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'AuthCode'});

}

sub getComplete(){
 
 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'Complete'});

}

sub getTransDate(){
 
 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'TransDate'});

}

sub getTransTime(){
 
 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'TransTime'});

}

sub getTicket(){
 
 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'Ticket'});

}

sub getTimedOut(){

 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'TimedOut'});

}


sub getRecurSuccess(){

 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'RecurSuccess'});

}

#########################################################################################33
# End of class

1;
__END__

=head1 NAME

Business::OnlinePayment::Moneris - Online Payment Module Moneris
} 

=head1 SYNOPSIS

    use Business::OnlinePayment::Moneris;




=head1 DESCRIPTION

none

=head1 REQUIREMENTS

none

=head1 COMMON METHODS

The methods described in this section are available for all 
C<Business::OnlinePayment::MonerisL> objects.

=over 4

=item new($userid,$userid_pass,$access_key,$origin_country)

none

=back

=head1 ERRORS/BUGS

=over 4

=item none

none

=back

=head1 IDEAS/TODO

none

=head1 AUTHOR

Duane Hinkley, <F<jpowers@cpan.org>>

L<http://www.dhwd.com>

Copyright (c) 2004 Down Home Web Design, Inc.

All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself

If you have any questions, comments or suggestions please feel free 
to contact me.

=head1 SEE ALSO

none

=cut

1;

