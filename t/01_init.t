#!/usr/bin/perl -w       
################################################################################
#
#  Script Name : ScriptName
#  Version     : 1
#  Company     : Down Home Web Design, Inc
#  Author      : Duane Hinkley ( duane@dhwd.com )
#  Website     : www.DownHomeWebDesign.com
#
#  Copyright (c) 2004 Down Home Web Design, Inc.  All rights reserved.
#
#  This is free software; you can redistribute it and/or modify it
#  under the same terms as Perl itself.
#
#  Description:
#
#
#  $Header: /home/cvs/moneris_payment/t/01_init.t,v 0.3 2004/09/29 15:05:15 cvs Exp $
#
#
#
################################################################################

use strict;
use lib qw( ./lib ../lib );
use Business::OnlinePayment::Moneris::Adaptor;

use ExtUtils::MakeMaker qw(prompt);

use Test::More tests => 8;

my $storeid	= 'store1';
my $apitoken = 'yesguy';
my $mpg;



# Initialize module
#
$mpg = new Business::OnlinePayment::Moneris::Adaptor($storeid,$apitoken,'true');

isa_ok( $mpg, 'Business::OnlinePayment::Moneris::Adaptor' );

my $auth_order_id = random();
# Run a purchase
#
$mpg->Purchase(
					{
						order_id	=> $auth_order_id,  
						cust_id		=> 'bjones',  
						amount		=> '1.01',  
						cc_num		=> '4242424242424242',  
						cc_exp		=> '0303',  
					}
			);

ok( $mpg->getResponseCode() ne 'null' && $mpg->getResponseCode() < 50, "Test Purchase (order: $auth_order_id)") or diag($mpg->getMessage());

# Make a void
#
$mpg->Void(
					{
						txn_number	=> $mpg->getTxnNumber(),  
						order_id	=> $auth_order_id,  
						amount		=> '1.01',  
					}
			);

ok( $mpg->getResponseCode() ne 'null' && $mpg->getResponseCode() < 50, "Test Void (order: $auth_order_id)") or diag($mpg->getMessage());


# Runa a preauthorization
#
$auth_order_id = random();
$mpg->PreAuth(
					{
						order_id	=> $auth_order_id,  
						cust_id		=> 'bjones',  
						amount		=> '1.01',  
						cc_num		=> '4242424242424242',  
						cc_exp		=> '0303',  
					}
			);

ok( $mpg->getResponseCode() ne 'null' && $mpg->getResponseCode() < 50, "Test PreAuth (order: $auth_order_id)") or diag($mpg->getMessage());


# Complete the preauthorization
#
$mpg->Completion(
					{
						txn_number	=> $mpg->getTxnNumber(),  
						order_id	=> $auth_order_id,  
						amount		=> '1.01',  
					}
			);

ok( $mpg->getResponseCode() ne 'null' && $mpg->getResponseCode() < 50, "Test Capture (order: $auth_order_id)") or diag($mpg->getMessage());


# Make a refund
#
$mpg->Refund(
					{
						txn_number	=> $mpg->getTxnNumber(),  
						order_id	=> $auth_order_id,  
						amount		=> '1.01',  
					}
			);

ok( $mpg->getResponseCode() ne 'null' && $mpg->getResponseCode() < 50, "Test Cancel (order: $auth_order_id)") or diag($mpg->getMessage());



# Runa a preauthorization then a void
#
$auth_order_id = random();
$mpg->PreAuth(
					{
						order_id	=> $auth_order_id,  
						cust_id		=> 'bjones',  
						amount		=> '1.01',  
						cc_num		=> '4242424242424242',  
						cc_exp		=> '0303',  
					}
			);
ok( $mpg->getResponseCode() ne 'null' && $mpg->getResponseCode() < 50, "Test PreAuth before void (order: $auth_order_id)") or diag($mpg->getMessage());

# Void the preauthorization
#
$mpg->VoidPreAuth(
					{
						txn_number	=> $mpg->getTxnNumber(),  
						order_id	=> $auth_order_id,  
						amount		=> '1.01',  
					}
			);

ok( $mpg->getResponseCode() ne 'null' && $mpg->getResponseCode() < 50, "Test PreAuth Void (order: $auth_order_id)") or diag($mpg->getMessage());





sub random {


	# create a random session key
    #srand($$|time);
    my $saltchars = "0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789";

    my $now = time();

    my $sessnum=""; #reset to nothing just in case.
	my ($rand_num,$letter_pos);

    for ( 1 .. 10 ) {

      $rand_num = int(rand($now));
	  ##print "Rand: " . $rand_num . "\n";

	  $letter_pos = substr($rand_num,5,2);
	  ##print "Pos: " . $letter_pos . "\n";

      $sessnum .= substr($saltchars,$letter_pos,1);
	  ##print "Sess: " . $sessnum . "\n";

	  #$saltchars[int(rand($saltchars))];
    }
  return $sessnum;
}
