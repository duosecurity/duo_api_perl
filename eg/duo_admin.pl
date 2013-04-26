#!/usr/bin/env perl

# Demo of the Duo Admin API
#
# Documentation: http://www.duosecurity.com/docs/adminapi

use Data::Dumper;
use File::Basename qw(basename);

use Duo::API;

main(@ARGV);
exit(0);

sub main {
    my ($ikey, $skey, $host) = @_;
    if (not $host) {
        print STDERR 'Usage: '
          . basename($0)
          . ' <integration key> <secret key> <integration host>'
          . "\n";
        exit(1);
    }

    my $client = Duo::API->new($ikey, $skey, $host);
    my $res = $client->json_api_call('GET',
                                     '/admin/v1/info/authentication_attempts',
                                     {});
    print Data::Dumper->Dump([$res], ['authentication_attempts']);
}
