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
#  $Header: /home/cvs/moneris_payment/lib/Business/OnlinePayment/Moneris/mpgHttpsPost.pm,v 1.4 2004/09/29 02:47:52 cvs Exp $
#
#  $Log: mpgHttpsPost.pm,v $
#  Revision 1.4  2004/09/29 02:47:52  cvs
#  Added customer info and OnlinePayment version
#
#  Revision 1.3  2004/09/28 15:46:02  cvs
#  Version one
#
#  Revision 1.2  2004/09/28 14:43:00  cvs
#  Integrating with Interchange
#
#
#
################################################################################

package Business::OnlinePayment::Moneris::mpgHttpsPost;
use strict;

use vars qw($VERSION);

'$Revision: 1.4 $' =~ /([0-9]{1,}\.[0-9]{1,})/;
$VERSION = $1;


###################  mpgHttpsPost ############################################


use LWP::UserAgent;
use Business::OnlinePayment::Moneris::mpgHttpsPost;
use Business::OnlinePayment::Moneris::mpgResponse;
use Business::OnlinePayment::Moneris::mpgGlobals;

sub new{

 my $class = shift;
 my $store_id = shift;
 my $api_token = shift;
 my $requestObject = shift;
 my $test_mode	= shift;

 my $self = {
             responseObj	=> 0,
             store_id		=> $store_id,
             api_token		=> $api_token, 
             requestObject	=> $requestObject,
             responseObject	=> 0   
            };

 $self->{test_mode} = $test_mode;

 bless($self);

 $self->doRequest(); 

 return $self;
}


sub doRequest{
 
 my $self = shift;
 my $xmlStringToSend = $self->toXML();
print "$xmlStringToSend\n";
 my $mpgGlobals = new Business::OnlinePayment::Moneris::mpgGlobals($self->{test_mode});
 
 my  $url= $mpgGlobals->{MONERIS_PROTOCOL} .
           "://" .
           $mpgGlobals->{MONERIS_HOST}.
           ":" .
           $mpgGlobals->{MONERIS_PORT} .
           $mpgGlobals->{MONERIS_FILE}; 


 my $ua = LWP::UserAgent->new;
 $ua->agent($mpgGlobals->{API_VERSION});
 $ua->timeout($mpgGlobals->{CLIENT_TIMEOUT});
 my $req=HTTP::Request->new('POST'=>$url);
 $req->content_type('application/x-www-form-urlencoded');
 $req->content($xmlStringToSend);
 my $res =$ua->request($req);

 if ($res->is_success) 
    { 
      my $returnXML = $res->content(); 
      my $responseObj = new Business::OnlinePayment::Moneris::mpgResponse($returnXML);
      $self->{responseObject} = $responseObj;                
    } 
 else
   {

   ##build message
   my $y="<?xml version=\"1.0\"?><response><receipt>".
          "<ReceiptId>Global Error Receipt</ReceiptId>".
          "<ReferenceNum>null</ReferenceNum><ResponseCode>null</ResponseCode>". 
          "<ISO>null</ISO> <AuthCode>null</AuthCode><TransTime>null</TransTime>".
          "<TransDate>null</TransDate><TransType>null</TransType><Complete>false</Complete>".
          "<Message>null</Message><TransAmount>null</TransAmount>".
          "<CardType>null</CardType>".
          "<TransID>null</TransID><TimedOut>null</TimeOut>".
          "</receipt><Ticket>null</Ticket></response>";
    my $responseObj = new Business::OnlinePayment::Moneris::mpgResponse($y);
    $self->{responseObject} = $responseObj; 
   }

}

sub toXML{

 my $self = shift;
 
 my $header =   "<?xml version=\"1.0\"?>"
              . "<request>"
              . "<store_id>" . $self->{store_id} . "</store_id>"                   
              . "<api_token>" .$self->{api_token} . "</api_token>" ;
              
 my $reqObj = $self->{requestObject};        
 my $reqXMLString=$header. $reqObj->toXML() . "</request>";
     
 return $reqXMLString;
 }

sub getMpgResponse{

 my $self = shift; 
 return $self->{responseObject};
}


##end class


1;
