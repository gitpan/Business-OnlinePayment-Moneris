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
#  $Header: /home/cvs/moneris_payment/t/02_online_payment.t,v 0.2 2004/09/29 15:05:15 cvs Exp $
#
#
#
################################################################################

use strict;
use lib qw( ./lib ../lib );


use ExtUtils::MakeMaker qw(prompt);

use Test::More tests => 4;


#testing/testing is valid and seems to work...
#print "ok 1 # Skipped: need a valid DHDMedia login/password to test\n"; exit;

use Business::OnlinePayment;

my $tx = new Business::OnlinePayment("Moneris");
isa_ok( $tx, 'Business::OnlinePayment::Moneris' );

my $auth_order_id = random();
$tx->content(

    login          => 'store1',
    password       => 'yesguy',
    order_number   => $auth_order_id,

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
	user_login     => 'test_client_user',	
	user_password  => 'whattimeisit',	
);

$tx->test_transaction(1); # test, dont really charge
$tx->submit();

ok( $tx->is_success(), "Test Purchase (order: $auth_order_id)" );
ok( $tx->result_code() < 50 , "Good Response Code (order: $auth_order_id)" );
ok( $tx->authorization() ne '' , "Good Authorization Code (order: $auth_order_id)" );


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
