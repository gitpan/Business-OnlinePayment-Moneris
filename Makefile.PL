use ExtUtils::MakeMaker;


WriteMakefile(
  NAME => 'Business::OnlinePayment::Moneris',
  VERSION_FROM => 'lib/Business/OnlinePayment/Moneris.pm',
  PREREQ_PM => {
				'Business::OnlinePayment'	=> 0,
				'LWP::UserAgent'	=> 0,
                'URI'				=> 0,
                'Crypt::SSLeay'		=> 0,
                'Net::SSL'			=> 0,
               },
);

 