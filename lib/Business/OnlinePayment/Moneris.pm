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
#  $Header: /home/cvs/moneris_payment/lib/Business/OnlinePayment/Moneris.pm,v 0.4 2004/09/29 02:47:52 cvs Exp $
#
#  $Log: Moneris.pm,v $
#  Revision 0.4  2004/09/29 02:47:52  cvs
#  Added customer info and OnlinePayment version
#
#  Revision 0.3  2004/09/28 15:46:02  cvs
#  Version one
#
#  Revision 0.2  2004/09/28 14:43:00  cvs
#  Integrating with Interchange
#
#
#
################################################################################

package Business::OnlinePayment::Moneris;

use strict;

use Business::OnlinePayment;
use Business::OnlinePayment::Moneris::Adaptor;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require AutoLoader;
require Exporter;

@ISA = qw(Exporter AutoLoader Business::OnlinePayment);
@EXPORT = qw();
@EXPORT_OK = qw();

'$Revision: 0.4 $' =~ /([0-9]{1,}\.[0-9]{1,})/;
$VERSION = $1;


sub submit {

   my $self  = shift;

    my %content = $self->content();

	my $error_message;

	# Adjust values for Moneris
	#
	my ($month,$year) = split('/',$content{expiration} );
	my $exp = sprintf('%02d%02d', $year, $month);


	# Create Moneris Adaptor object
	#
	my $mpg = new Business::OnlinePayment::Moneris::Adaptor($content{login},$content{password}, $self->test_transaction() );


	if ( lc( $content{action} ) eq 'normal authorization' ) {

		$mpg->Purchase(
						{
							order_id	=> $content{order_number},  
							amount		=> $content{amount},  
							cc_num		=> $content{card_number},  
							cc_exp		=> $exp,  
							first_name	=> $content{first_name}, 
							last_name	=> $content{last_name}, 
							company_name=> $content{company_name},
							address		=> $content{address},
							city		=> $content{city}, 
							province	=> $content{province},
							postal_code	=> $content{postal_code}, 
							country		=> $content{country},
							phone_number=> $content{phone_number}
						}
				);

    } 
    elsif ( lc( $content{action} ) eq 'authorization only' ) {

		$mpg->PreAuth(
						{
							order_id	=> $content{order_number},  
							amount		=> $content{amount},  
							cc_num		=> $content{card_number},  
							cc_exp		=> $exp,  
						}
				);
    } 
    elsif ( lc( $content{action} ) eq 'post authorization' ) {

		$mpg->Completion(
						{
							txn_number	=> $content{auth_code},  
							order_id	=> $content{order_number},  
							amount		=> $content{amount},  
						}
				);

    } 
    elsif ( lc( $content{action} ) eq 'void' ) {


		$mpg->Void(
						{
							txn_number	=> $content{auth_code},  
							order_id	=> $content{order_number},  
						}
				);
    } 
	else {

        $error_message = "Moneris can't handle action: ".  $content{action};

    }

	# If there's no error message, 

	if ( ! $error_message ) {


		if ( $mpg->getTimedOut() ne 'false' ) {

			$self->is_success(0);
			$self->result_code( $mpg->getResponseCode() );
			$self->error_message( $mpg->getMessage() );
		}
		elsif ( $mpg->getResponseCode() < 50 ) {

			$self->is_success(1);
			$self->result_code( $mpg->getResponseCode() );
			$self->authorization( $mpg->getTxnNumber() );
		}
		else {

			$self->is_success(0);
			$self->result_code( $mpg->getResponseCode() );
			$self->error_message( $mpg->getMessage() );
		}


	}

}
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

