#!/usr/bin/perl
################################################################################
#
#  Script Name : $RCSFile$
#  Version     : $Revision: 0.5 $
#  Company     : Down Home Web Design, Inc
#  Author      : Duane Hinkley ( duane@dhwd.com )
#  Website     : www.DownHomeWebDesign.com
#
#  Description: This module allows the user to interface with the Moneris Online
#               payment service (www.moneris.com) in any Perl program using the 
#               Business::Online::Payment structure.  
#
#               The module includes extra code to make Moneris work with the  
#               Interchange ecommerce software available at www.icdevgroup.org.
#               
#  Copyright (c) 2004 Down Home Web Design, Inc.  All rights reserved.
#
#  $Header: /home/cvs/moneris_payment/lib/Business/OnlinePayment/Moneris.pm,v 0.5 2004/10/10 15:49:10 cvs Exp $
#
#  $Log: Moneris.pm,v $
#  Revision 0.5  2004/10/10 15:49:10  cvs
#  Clean up and add documentation
#
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

=pod

=head1 NAME $RCSFile$ 

Business::OnlinePayment::Moneris - Moneris Online Payment  

=head1 SYNOPSIS

use Business::OnlinePayment;

$tx = new Business::OnlinePayment("Moneris");

$tx->content(

    login          => 'store1',
    password       => 'yesguy',
    order_number   => '999999999',

    action         => 'Normal Authorization',
    description    => 'Business::OnlinePayment visa test',
    amount         => '1.01',
    first_name     => 'Joe',
    last_name      => 'Smith',
    email          => 'Joe@work.com',
    address        => '1 Foobar St',
    city           => 'Marina Del Rey',
    state          => 'CA',
    country        => 'US',
    zip            => '9999',
    card_number    => '4242424242424242',
    expiration     => '06/04',
);

$tx->test_transaction(1); 
$tx->submit();


=head1 DESCRIPTION 

This module allows the user to interface with the Moneris Online payment 
service (www.moneris.com) in any Perl program using the Business::Online::Payment
structure.  

The module includes extra code to make Moneris work with the  Interchange 
ecommerce software available at www.icdevgroup.org.

=head1 METHODS

The methods described in this section are available for all C<FedEx::XML> objects.


=over

=item new

Standard Online Payment new constructor.  

$tx = new Business::OnlinePayment("Moneris");

=cut


###############################################################################
#

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

( $VERSION ) = '$Revision: 0.5 $ ' =~ /\$Revision:\s+([^\s]+)/;


=item $tx->submit()

This method will submit the payment to Moneris.

=cut

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
#########################################################################################33
# End of class

1;
__END__

=item content

Accessor to set the values sent to Moneris.  

$tx->content(

    login          => 'store1',
    password       => 'yesguy',
    order_number   => '01234567890',

    action         => 'Normal Authorization',
    description    => 'Business::OnlinePayment visa test',
    amount         => '1.01',
    invoice_number => '',
    customer_id    => '',
    first_name     => 'Jason',
    last_name      => 'Burns',
    email          => 'test@dhdmedia.com',
    address        => '1 Foobar St',
    city           => 'Marina Del Rey',
    state          => 'CA',
    country        => 'US',
    zip            => '90292',
    card_number    => '4242424242424242',
    expiration     => '06/04',
);


=item test_transaction

Accessor to tell Moneris this will be a test transation.  

$tx->test_transaction(1)


=item is_success

Accessor returns true if the payment was successful  

$tx->is_success()


=item result_code

Accessor to return the result code from Moneris.  Any result code lower than
50 is good.

$tx->result_code()


=item authorization

Accessor to return the authorization code from Moneris.  

$tx->authorization()


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

