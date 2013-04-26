#!/usr/bin/env perl

# Demo of the Duo Admin API
#
# Documentation: http://www.duosecurity.com/docs/adminapi

use File::Basename qw(basename);

use Duo::API;

main(@ARGV);
exit(0);

sub main {
    my ($ikey, $skey, $host, $phone) = @_;
    if (not $phone) {
        print STDERR 'Usage: '
          . basename($0)
          . ' <integration key> <secret key> <integration host>'
          . ' <E.164-formatted phone number>'
          . "\n";
        exit(1);
    }

    my $client = Duo::API->new($ikey, $skey, $host);

    # Start a call.
    my $call_res = $client->json_api_call('POST',
                                          '/verify/v1/call', {
                                              'phone' => $phone,
                                              'message' => 'The PIN is <pin>',
                                          });

    # Poll the txid for the status of the transaction.
    my $txid = $call_res->{'txid'};
    if (not $txid) {
        print STDERR "Could not send PIN!\n";
        exit(1);
    }
    print STDERR 'The PIN is ' . $call_res->{'pin'} . "\n";
    my $state;
    do {
        my $status_res = $client->json_api_call('GET',
                                                '/verify/v1/status', {
                                                    'txid' => $txid,
                                                });
        $state = $status_res->{'state'};
        print STDERR $status_res->{'info'} . "\n";
    } while ($state ne 'ended');
}
