#!/usr/bin/perl
################################################################################
#
#  Script Name : 
#  Version     : 1
#  Company     : Moneris Solutions 
#  Author      : Moneris Solutions 
#  Website     : www.moneris.com
#
#  Description: A module provided by Moneris Solutions to interface with
#               the Moneris Solutions 
#               
#  $Header: /home/cvs/moneris_payment/lib/Business/OnlinePayment/Moneris/mpgTransaction.pm,v 1.3 2004/10/10 15:49:10 cvs Exp $
#
#  $Log: mpgTransaction.pm,v $
#  Revision 1.3  2004/10/10 15:49:10  cvs
#  Clean up and add documentation
#
#  Revision 1.2  2004/09/28 14:43:00  cvs
#  Integrating with Interchange
#
#
#
################################################################################

package Business::OnlinePayment::Moneris::mpgTransaction;
use strict;

use vars qw($VERSION);

( $VERSION ) = '$Revision: 1.3 $ ' =~ /\$Revision:\s+([^\s]+)/;

############################### mpgTransaction ########################




sub new{

   my $className = shift;
   my $txn = shift;
   my $self = {txn=>$txn,
               custInfo=>'0',
               recur=>'0'
               };
 
   $self->{txnTypes}={
                      purchase=> ['order_id','cust_id', 'amount', 'pan', 'expdate', 'crypt_type'],
                      refund => ['order_id', 'amount', 'txn_number', 'crypt_type'],
                      ind_refund => ['order_id','cust_id', 'amount','pan','expdate', 'crypt_type'],
                      preauth => ['order_id','cust_id', 'amount', 'pan', 'expdate', 'crypt_type'],
                      completion => ['order_id', 'comp_amount','txn_number', 'crypt_type'],
                      purchasecorrection => ['order_id', 'txn_number', 'crypt_type'],
                      opentotals => ['ecr_number'],
                      batchclose => ['ecr_number'],
                      batchcloseall => [],
		      		  cavv_purchase=> ['order_id','cust_id', 'amount', 'pan', 'expdate', 'cavv'],
                      cavv_preauth => ['order_id','cust_id', 'amount', 'pan', 'expdate', 'cavv'],     
                      reauth => ['order_id', 'amount','txn_number', 'crypt_type']
                      };
 
   bless($self); 

 }
sub setCustInfo(){

   my $self = shift;
   my $custinfo = shift; 
   $self->{custInfo} = $custinfo;
}

sub setRecur()
{
   my $self = shift;
   my $recur = shift; 
   $self->{recur} = $recur;
}

sub getTransaction(){
 
   my $self = shift; 
   return $self;
} 

sub toXML(){
 
   my $self = shift;
   my $txnType = delete($self->{txn}->{type});
   my $type = delete($self->{txn}->{type});
   
   my $xmlString; 
   foreach my $tag(@{$self->{txnTypes}->{$txnType}})
   {
	   if ($self->{txn}->{$tag}) {

			$xmlString .= "<$tag>". $self->{txn}->{$tag}  ."</$tag>";
	   }
   }

   #$xmlString .= 
#	"<recur><recur_unit>ndays</recur_unit><start_now>false</start_now>"            . "<start_date>2003/08/06</start_date><num_recurs>3</num_recurs>"
#       . "<period>1</period></recur>"; 

   if($self->{recur})
   {
	
     $xmlString .= $self->{recur}->toXML(); 
   }

   if($self->{custInfo})
   {
     $xmlString .= $self->{custInfo}->toXML(); 

   }  
   $xmlString = "<$txnType>$xmlString</$txnType>";  

 
}

#end class

1;
