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
#  $Header: /home/cvs/moneris_payment/lib/Business/OnlinePayment/Moneris/mpgCustInfo.pm,v 1.3 2004/09/29 02:47:52 cvs Exp $
#
#  $Log: mpgCustInfo.pm,v $
#  Revision 1.3  2004/09/29 02:47:52  cvs
#  Added customer info and OnlinePayment version
#
#  Revision 1.2  2004/09/28 14:43:00  cvs
#  Integrating with Interchange
#
#
#
################################################################################

package Business::OnlinePayment::Moneris::mpgCustInfo;
use strict;

use vars qw($VERSION);

'$Revision: 1.3 $' =~ /([0-9]{1,}\.[0-9]{1,})/;
$VERSION = $1;


############### mpgCustInfo #####################################


sub new{

 my $classname = shift;
 my $self = {};
 $self->{level3template}= ['email','instructions','billing','shipping','item'];
 $self->{level3template_details} = 
                        {                  
                          email => '0',

                          instructions => '0',
                         
                          billing =>['first_name', 'last_name', 'company_name', 'address',
                                    'city', 'province', 'postal_code', 'country', 
                                    'phone_number', 'fax','tax1', 'tax2','tax3', 
                                    'shipping_cost'],
                          shipping =>['first_name', 'last_name', 'company_name', 'address', 
                                   'city', 'province', 'postal_code', 'country', 
                                   'phone_number', 'fax','tax1', 'tax2', 'tax3',
                                   'shipping_cost'],
                          item   =>['name', 'quantity', 'product_code', 'extended_amount']
                        };
                                                
          
 $self->{item} = [];               
 $self->{shipping} = [];        
 $self->{billing} = []; 
 $self->{email} = ""; 
 $self->{instructions}= "" ; 
 
 bless($self); 

 }


sub setEmail(){
   
    my $self = shift;
    my $email = shift; 
    $self->{email}=$email;
 }


sub setInstructions(){
 
    my $self = shift;
    my $instructions = shift;
    $self->{instructions}= $instructions;
} 

sub setShipping(){ 

   my $self = shift;
   my $shipping = shift;
   push(@{$self->{shipping}},$shipping);
    
 } 
 
sub setBilling(){
 
   my $self = shift;
   my $billing = shift;
   push(@{$self->{billing}},$billing);
    
 } 
 
sub setItems(){
 
   my $self = shift;
   my $item = shift; 

   push(@{$self->{item}},$item );  
  
 }


sub toXML(){

   my $self = shift;
   my ($xmlString,$beginTag,$endTag,$pcdata);
   
   foreach my $templateElement (@{$self->{level3template}})
   { 
     
     my $tempData = $self->{$templateElement};
     if( ! ref($tempData))
       {
         $beginTag = "<$templateElement>";
         $endTag = "</$templateElement>";
         $pcdata = $self->{$templateElement};

		 if ($pcdata) {

			$xmlString .= $beginTag . $pcdata . $endTag ;  
		 }
		 else {

			$xmlString .= $beginTag .  $endTag ;  
		 }
       }
     else
      {                     

         foreach my $dataHash (@{$tempData})
         {
           $beginTag = "<$templateElement>";
           $endTag = "</$templateElement>";

           my $innerXMLString="";
           foreach my $tag (@{$self->{level3template_details}->{$templateElement}})
           {
			   if ( $dataHash->{$tag} ) {

					$innerXMLString .= "<$tag>$dataHash->{$tag}</$tag>";    
			   }
			   else {

					$innerXMLString .= "<$tag></$tag>";   
			   }

           }
           
          $xmlString .= $beginTag. $innerXMLString .$endTag ;
 
         } 
      } 
     
   }   
   
   $xmlString = "<cust_info>$xmlString</cust_info>";

   return $xmlString;
}

##end class


1;
