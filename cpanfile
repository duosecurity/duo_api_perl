requires 'CGI', '4.36';
requires 'Digest::SHA', '2.01';
requires 'JSON', '2.94';
requires 'LWP::UserAgent', '6.26';
requires 'MIME::Base64', '3.15';
requires 'Moo', '2.003004';

on 'test' => sub {
    requires 'Test::More', '1.302086';
    requires 'Test::Spec', '0.54';
    requires 'Test::Exception', '0.43';
    requires 'Test::NoWarnings', '1.04';
}
