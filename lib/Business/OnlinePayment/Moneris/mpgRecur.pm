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
#  $Header: /home/cvs/moneris_payment/lib/Business/OnlinePayment/Moneris/mpgRecur.pm,v 1.3 2004/10/10 15:49:10 cvs Exp $
#
#  $Log: mpgRecur.pm,v $
#  Revision 1.3  2004/10/10 15:49:10  cvs
#  Clean up and add documentation
#
#  Revision 1.2  2004/09/28 14:43:00  cvs
#  Integrating with Interchange
#
#
#
################################################################################

package Business::OnlinePayment::Moneris::mpgRecur;
use strict;

use vars qw($VERSION);

( $VERSION ) = '$Revision: 1.3 $ ' =~ /\$Revision:\s+([^\s]+)/;

################################# mpgRecur ########################



sub new
{

   my $className = shift;
   my $params = shift;

   if(! defined($params->{period}) )
   {
	$params->{period} = 1;

   }	
   my $self = {
	       params=>$params,
	       recurTemplate=>['recur_unit','start_now',
				'start_date','num_recurs','period','recur_amount']
	      };
	
   
   bless($self); 
}

sub toXML(){

   my $self = shift;
   my ($xmlString);
   
   foreach my $templateElement (@{$self->{recurTemplate}})
   {
	$xmlString .= "<$templateElement>" . $self->{params}->{$templateElement}
		      ."</$templateElement>";	

   }

   return "<recur>$xmlString</recur>";
}
##end class


1;
