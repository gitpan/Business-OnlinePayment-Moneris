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
#  $Header: /home/cvs/moneris_payment/lib/Business/OnlinePayment/Moneris/mpgGlobals.pm,v 1.3 2004/09/28 15:46:02 cvs Exp $
#
#  $Log: mpgGlobals.pm,v $
#  Revision 1.3  2004/09/28 15:46:02  cvs
#  Version one
#
#  Revision 1.2  2004/09/28 14:43:00  cvs
#  Integrating with Interchange
#
#
#
################################################################################

package Business::OnlinePayment::Moneris::mpgGlobals;
use strict;

use vars qw($VERSION);

'$Revision: 1.3 $' =~ /([0-9]{1,}\.[0-9]{1,})/;
$VERSION = $1;

#################### mpgGlobals ###########################################


sub new{
	my $class = shift;
	my $test_mode	= shift;
	my $self;

	if ( $test_mode ) {

		# Development Enviroment
		#
		$self = {
					MONERIS_PROTOCOL	=> 'https',
					MONERIS_HOST		=> 'esqa.moneris.com',
					MONERIS_PORT		=> '43924',
					MONERIS_FILE		=> '/gateway2/servlet/MpgRequest',
					API_VERSION			=> 'MPG Version 2.02 recur(perl)',
					CLIENT_TIMEOUT		=> '60'
					};
	}
	else {

		# Production Enviroment
		#
		$self = {
					MONERIS_PROTOCOL	=> 'https',
					MONERIS_HOST		=> 'www3.moneris.com',
					MONERIS_PORT		=>'43924',
					MONERIS_FILE		=> '/gateway2/servlet/MpgRequest',
					API_VERSION			=> 'MPG Version 2.02 recur(perl)',
					CLIENT_TIMEOUT		=> '60'
					};
	}
	bless($self);
	return ($self);
} 

##end class


1;
