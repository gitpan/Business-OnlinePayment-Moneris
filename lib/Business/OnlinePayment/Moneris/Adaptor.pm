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
#  $Header: /home/cvs/moneris_payment/lib/Business/OnlinePayment/Moneris/Adaptor.pm,v 0.5 2004/10/10 15:49:10 cvs Exp $
#
#  $Log: Adaptor.pm,v $
#  Revision 0.5  2004/10/10 15:49:10  cvs
#  Clean up and add documentation
#
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

=pod

=head1 NAME $RCSFile$ 

Business::OnlinePayment::Moneris::Adaptor - Moneris Online Payment Adaptor 

=head1 SYNOPSIS

use Business::OnlinePayment::Moneris::Adaptor;

$mpg = new Business::OnlinePayment::Moneris::Adaptor($storeid,$apitoken,'true');

$mpg->Purchase(
					{
						order_id	=> '2345678',  
						cust_id		=> 'bjones',  
						amount		=> '1.01',  
						cc_num		=> '4242424242424242',  
						cc_exp		=> '0303',  
					}
			);

if ( $mpg->getResponseCode() ne 'null' && $mpg->getResponseCode() < 50 ) {
	
	print "Success";
}
else {
	
	print "Error: " . $mpg->getMessage();
}

=head1 DESCRIPTION 

This module is an adaptor between the Business::OnlinePayment module and the 
modules provided by Moneris.  This adaptor is also used to interface with 
Interchange (www.icdevgroup.org)

=head1 METHODS

The methods described in this section are available for all 
C<Business::OnlinePayment::Moneris::Adaptor> objects.

=cut


package Business::OnlinePayment::Moneris::Adaptor;

use Business::OnlinePayment::Moneris::mpgTransaction;
use Business::OnlinePayment::Moneris::mpgHttpsPost;
use Business::OnlinePayment::Moneris::mpgCustInfo;

use strict;
use vars qw($VERSION);

( $VERSION ) = '$Revision: 0.5 $ ' =~ /\$Revision:\s+([^\s]+)/;


=over

=item new(%hash)

The new method is the constructor.  It uses the store id and api token provide
by Moneris

$mpg = new Business::OnlinePayment::Moneris::Adaptor($storeid,$apitoken,'true');

=cut


sub new {

   my $type  = shift;
   my ($storeid,$apitoken,$test_mode) = @_;
   my $self  = {};

   $self->{'_storeid'}	= $storeid;
   $self->{'_apitoken'}	= $apitoken;
   $self->{'_testmode'}	= $test_mode;

   bless $self, $type;
}

=item $t->Purchase(%hash)

This method accepts the following hash and processes a purchase transaction

			%hash =	{
						order_id	=> $auth_order_id,  
						cust_id		=> 'bjones',  
						amount		=> '1.01',  
						cc_num		=> '4242424242424242',  
						cc_exp		=> '0303',  
					}

=cut

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
=item $t->PreAuth(%hash)

This method accepts the following hash and processes a pre-authorization
transaction

			%hash =	{
						order_id	=> $auth_order_id,  
						cust_id		=> 'bjones',  
						amount		=> '1.01',  
						cc_num		=> '4242424242424242',  
						cc_exp		=> '0303',  
					}

=cut

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

=item $t->Completion(%hash)

This method accepts the following hash and processes a completion (capture)
transaction

			%hash =	{
						txn_number	=> $TxnNumber,  
						order_id	=> $auth_order_id,  
						amount		=> '1.01',  
					}

=cut

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

=item $t->Refund(%hash)

This method accepts the following hash and processes a refund to to a customer
for previously completed purchase.  This is not a cancel to a previous 
preathorization.

			%hash =	{
						txn_number	=> $TxnNumber,  
						order_id	=> $auth_order_id,  
						amount		=> '1.01',  
					}

=cut

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

=item $t->Void(%hash)

This method accepts the following hash and voids a previously completed 
purchase. 

			%hash =	{
						txn_number	=> $TxnNumber,  
						order_id	=> $auth_order_id,  
						amount		=> '1.01',  
					}

=cut

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

=item $t->VoidPreAuth(%hash)

This method accepts the following hash and voids a previously authorized 
purchase. 

			%hash =	{
						txn_number	=> $TxnNumber,  
						order_id	=> $auth_order_id,  
						amount		=> '1.01',  
					}

=cut

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

=item $t->getTerminalIDs()

=cut

sub getTerminalIDs(){

 my $self = shift; 
 return (keys(%{$self->{mpgResponse}->{termIDHash}}) );
 
}


=item $t->getCreditCards()

=cut


sub getCreditCards($ecr_no){
 
 my $self = shift;
 my $ecr_no = shift;
 return (@{$self->{mpgResponse}->{cardHash}->{$ecr_no}});
}


=item $t->getCardType()

=cut

sub getCardType(){

 my $self = shift;  
 return ($self->{mpgResponse}->{responseData}->{'CardType'});

}

=item $t->getTransAmount()

=cut


sub getTransAmount(){

 my $self = shift;  
 return ($self->{mpgResponse}->{responseData}->{'TransAmount'});

}

=item $t->getTxnNumber()

=cut


sub getTxnNumber(){

 my $self = shift;  
 return ($self->{mpgResponse}->{responseData}->{'TransID'});

}

=item $t->getReceiptId()

=cut


sub getReceiptId(){

 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'ReceiptId'});

}

=item $t->getTransType()

=cut


sub getTransType(){
 
 my $self = shift;  
 return ($self->{mpgResponse}->{responseData}->{'TransType'});

}

=item $t->getReferenceNum()

=cut


sub getReferenceNum(){
 
 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'ReferenceNum'});

}

=item $t->getResponseCode()

=cut


sub getResponseCode(){
 
 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'ResponseCode'});

}

=item $t->getISO()

=cut


sub getISO(){
 
 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'ISO'});

}

=item $t->getBankTotals()

=cut


sub getBankTotals(){
 
 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'BankTotals'});

}

=item $t->getMessage()

=cut


sub getMessage(){
 
 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'Message'});

}

=item $t->getAuthCode()

=cut


sub getAuthCode(){
 
 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'AuthCode'});

}

=item $t->getComplete()

=cut


sub getComplete(){
 
 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'Complete'});

}

=item $t->getTransDate()

=cut


sub getTransDate(){
 
 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'TransDate'});

}

=item $t->getTransTime()

=cut


sub getTransTime(){
 
 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'TransTime'});

}

=item $t->getTicket()

=cut


sub getTicket(){
 
 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'Ticket'});

}

=item $t->getTimedOut()

=cut


sub getTimedOut(){

 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'TimedOut'});

}


=item $t->getRecurSuccess()

=cut


sub getRecurSuccess(){

 my $self = shift; 
 return ($self->{mpgResponse}->{responseData}->{'RecurSuccess'});

}

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

