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
#  $Header: /home/cvs/moneris_payment/lib/Business/OnlinePayment/Moneris/mpgResponse.pm,v 1.3 2004/10/10 15:49:10 cvs Exp $
#
#  $Log: mpgResponse.pm,v $
#  Revision 1.3  2004/10/10 15:49:10  cvs
#  Clean up and add documentation
#
#  Revision 1.2  2004/09/28 14:43:00  cvs
#  Integrating with Interchange
#
#
#
################################################################################

package Business::OnlinePayment::Moneris::mpgResponse;
use strict;

use vars qw($VERSION);

( $VERSION ) = '$Revision: 1.3 $ ' =~ /\$Revision:\s+([^\s]+)/;

################# mpgResponse #################################################



sub new{
 
 my $classname = shift;
 my $xmlString = shift;

  my $self = {
             responseData =>{},
             currentTermID =>"",
             currentTag =>"",
             currentCardType =>"",
             currentTxnType =>"",
             isBankTotals =>0,
             termIDHash =>{}, 
             cardHash =>{},
             purchaseHash =>{},
             correctionHash =>{},
             refundHash =>{},
             responseData =>{} 
             };

 $self->{xmlString} = $xmlString;
   
 bless($self);
 
 $self->readXML(0); 
  
 return ($self);
} 


sub readXML(){

 my $self =shift; 
 my $pos = shift;
 my $xmlString = $self->{xmlString};
 
 pos($xmlString) = $pos;

 if( ($xmlString =~ /<\/([^<>\/]*)>|<([^><\/]*)>|([^><]*)/g) &&
     ($pos < length($xmlString) )
   )
   {    
     if($1) ##end tag
       {
          $self->endHandler($1);
   
       }
     elsif($2) 
       {
          $self->startHandler($2); 
       }
     elsif($3)
       {
         if($3 !~ /^[\n\s]+$/)
            {   
               $self->charDataHandler($3);      

            }
       }
     else
      {
        ##"Default found no match;
      }   

    $self->readXML(pos($xmlString));

   }

}


sub startHandler(){
 
 my $self = shift;
 my $tag = shift;

 $self->{currentTag}=$tag;

 if($tag eq 'BankTotals')
   {
     
      $self->{isBatchTotals} = 1;
   }
  
 if($self->{isBatchTotals})
   {
     if($self->{currentTag} eq "Purchase")
       {
         $self->{currentTxnType} = "Purchase";
       }   
     
     elsif($self->{currentTag} eq "Refund")
       {
         $self->{currentTxnType} = "Refund"; 
       }   
   
      
     elsif($self->{currentTag} eq "Correction")
       {
         $self->{currentTxnType} = "Correction";
       }     
   

   }#end if
 
 
}

sub endHandler(){

  my $self = shift;
  my $tag = shift;
 
  if($tag eq 'BankTotals')
   {

    $self->{isBatchTotals} = 0;
   }

}

sub charDataHandler(){
 
 my $self=shift;
 my $data = shift;

 if($self->{isBatchTotals})
 { 
    if($self->{currentTag} eq "term_id" )
     {
       $self->{currentTermID} = $data;
       $self->{cardHash}->{$data}= []; 
       $self->{purchaseHash}->{$self->{currentTermID}} = {};
       $self->{refundHash}->{$self->{currentTermID}} = {};
       $self->{correctionHash}->{$self->{currentTermID}} = {};

     }
    elsif($self->{currentTag} eq "closed")
     {
      
       $self->{termIDHash}->{$self->{currentTermID}} = $data;    
     }

    elsif($self->{currentTag} eq "CardType")
     {

       push(@{$self->{cardHash}->{$self->{currentTermID}}},$data);
       $self->{currentCardType} = $data;
       $self->{purchaseHash}->{$self->{currentTermID}}->{$self->{currentCardType}} = {};  
       $self->{refundHash}->{$self->{currentTermID}}->{$self->{currentCardType}} = {};     
       $self->{correctionHash}->{$self->{currentTermID}}->{$self->{currentCardType}} = {};   

     } 
    elsif($self->{currentTag} eq "Amount")
     {

        if($self->{currentTxnType} eq "Purchase")
           {
             $self->{purchaseHash}->{$self->{currentTermID}}->{$self->{currentCardType}}->{Amount}=$data;
            
            }

        elsif($self->{currentTxnType} eq "Refund")
           {
             $self->{refundHash}->{$self->{currentTermID}}->{$self->{currentCardType}}->{Amount}=$data;
            
            }

        elsif($self->{currentTxnType} eq "Correction")
           {
             $self->{correctionHash}->{$self->{currentTermID}}->{$self->{currentCardType}}->{Amount}=$data;
            
            }        
      }   
   
    elsif($self->{currentTag} eq "Count")
     {

        if($self->{currentTxnType} eq "Purchase")
           {
             $self->{purchaseHash}->{$self->{currentTermID}}->{$self->{currentCardType}}->{Count}=$data;
            
            }

        elsif($self->{currentTxnType} eq "Refund")
           {
             $self->{refundHash}->{$self->{currentTermID}}->{$self->{currentCardType}}->{Count}=$data;
            
            }

        elsif($self->{currentTxnType} eq "Correction")
           {
             $self->{correctionHash}->{$self->{currentTermID}}->{$self->{currentCardType}}->{Count}=$data;
            
           }        
      }   
 
 }
 else
 {
   $self->{responseData}->{$self->{currentTag}} = $data;
 }

}



sub getPurchaseAmount($ecr_no,$card_type){
 
  my $self = shift;
  my $ecr_no = shift;
  my $card_type = shift;
 
  return ($self->{purchaseHash}->{$ecr_no}->{$card_type}->{'Amount'} eq "" ?
          0:$self->{purchaseHash}->{$ecr_no}->{$card_type}->{'Amount'});
}


sub getPurchaseCount($ecr_no,$card_type){
 
  my $self = shift;
  my $ecr_no = shift;
  my $card_type = shift;
 
  return ($self->{purchaseHash}->{$ecr_no}->{$card_type}->{'Count'} eq "" ?
          0:$self->{purchaseHash}->{$ecr_no}->{$card_type}->{'Count'});
}


sub getRefundAmount($ecr_no,$card_type){
 
  my $self = shift;
  my $ecr_no = shift;
  my $card_type = shift;
 
  return ($self->{refundHash}->{$ecr_no}->{$card_type}->{'Amount'} eq "" ?
          0:$self->{refundHash}->{$ecr_no}->{$card_type}->{'Amount'});
}


sub getRefundCount($ecr_no,$card_type){
 
  my $self = shift;
  my $ecr_no = shift;
  my $card_type = shift;
 
  return ($self->{refundHash}->{$ecr_no}->{$card_type}->{'Count'} eq "" ?
          0:$self->{refundHash}->{$ecr_no}->{$card_type}->{'Count'});
}

sub getCorrectionAmount($ecr_no,$card_type){
 
  my $self = shift;
  my $ecr_no = shift;
  my $card_type = shift;
 
  return ($self->{correctionHash}->{$ecr_no}->{$card_type}->{'Amount'} eq "" ?
          0:$self->{correctionHash}->{$ecr_no}->{$card_type}->{'Amount'});
}

sub getCorrectionCount($ecr_no,$card_type){
 
  my $self = shift;
  my $ecr_no = shift;
  my $card_type = shift;
 
  return ($self->{correctionHash}->{$ecr_no}->{$card_type}->{'Count'} eq "" ?
          0:$self->{correctionHash}->{$ecr_no}->{$card_type}->{'Count'});
}

sub getTerminalStatus($ecr_no){

  my $self = shift;
  my $ecr_no = shift;
  return ($self->{termIDHash}->{$ecr_no});

}

sub getTerminalIDs(){

 my $self = shift; 
 return (keys(%{$self->{termIDHash}}) );
 
}


sub getCreditCards($ecr_no){
 
 my $self = shift;
 my $ecr_no = shift;
 return (@{$self->{cardHash}->{$ecr_no}});
}




sub getCardType(){

 my $self = shift;  
 return ($self->{responseData}->{'CardType'});

}

sub getTransAmount(){

 my $self = shift;  
 return ($self->{responseData}->{'TransAmount'});

}

sub getTxnNumber(){

 my $self = shift;  
 return ($self->{responseData}->{'TransID'});

}

sub getReceiptId(){

 my $self = shift; 
 return ($self->{responseData}->{'ReceiptId'});

}

sub getTransType(){
 
 my $self = shift;  
 return ($self->{responseData}->{'TransType'});

}

sub getReferenceNum(){
 
 my $self = shift; 
 return ($self->{responseData}->{'ReferenceNum'});

}

sub getResponseCode(){
 
 my $self = shift; 
 return ($self->{responseData}->{'ResponseCode'});

}

sub getISO(){
 
 my $self = shift; 
 return ($self->{responseData}->{'ISO'});

}

sub getBankTotals(){
 
 my $self = shift; 
 return ($self->{responseData}->{'BankTotals'});

}

sub getMessage(){
 
 my $self = shift; 
 return ($self->{responseData}->{'Message'});

}

sub getAuthCode(){
 
 my $self = shift; 
 return ($self->{responseData}->{'AuthCode'});

}

sub getComplete(){
 
 my $self = shift; 
 return ($self->{responseData}->{'Complete'});

}

sub getTransDate(){
 
 my $self = shift; 
 return ($self->{responseData}->{'TransDate'});

}

sub getTransTime(){
 
 my $self = shift; 
 return ($self->{responseData}->{'TransTime'});

}

sub getTicket(){
 
 my $self = shift; 
 return ($self->{responseData}->{'Ticket'});

}

sub getTimedOut(){

 my $self = shift; 
 return ($self->{responseData}->{'TimedOut'});

}


sub getRecurSuccess(){

 my $self = shift; 
 return ($self->{responseData}->{'RecurSuccess'});

}
##end class


1;
