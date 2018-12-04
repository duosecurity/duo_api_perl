use Test::Spec;
use Test::More;
use Test::Deep;
use Test::Exception;
use URI;
use URI::QueryParam;

use Duo::API;
use LWP::UserAgent;

describe "A duo api client" => sub {
    my $sut;
    my $mock_response;
    my $captured_request;
    my $ikey;
    my $skey;
    my $host;
    before each => sub {
        $mock_response = mock();
        $ikey = 'ikey' . rand();
        $skey = 'skey' . rand();
        $host = 'host' . rand();
        $sut = Duo::API->new($ikey, $skey, $host);

        LWP::UserAgent->stubs(request => sub {
            my ($ua, $req) = @_;
            $captured_request = $req;
            return $mock_response;
        });

        $mock_response->stubs(
            content => '{"stat":"OK", "response": [{"thing": 1}, {"thing": 2}], "metadata": {"next_offset": null}}'
        );
    };

    describe "json_api_call method" => sub {

        it "creates the expected GET request" => sub {
            my $res = $sut->json_api_call('GET', '/admin/v1/admins', {
                limit => 25,
                offset => 0,
                account_id => 'D1234567890123456789',
            });

            is($captured_request->uri->host, $host);
            is($captured_request->uri->path, '/admin/v1/admins');
            is($captured_request->uri->query_param('limit'), "25");
            is($captured_request->uri->query_param('offset'), "0");
            is($captured_request->uri->query_param('account_id'), "D1234567890123456789");
            is($captured_request->method, 'GET');
        };

        it "creates the expected POST request" => sub {
            my $res = $sut->json_api_call('POST', '/admin/v1/admins', {
                limit => 25,
                offset => 0,
                account_id => 'D1234567890123456789',
            });

            my $dummy_uri = URI->new("https://example.com");
            $dummy_uri->query($captured_request->content);
            is($captured_request->uri->host, $host);
            is($captured_request->uri->path, '/admin/v1/admins');
            is($dummy_uri->query_param('limit'), "25");
            is($dummy_uri->query_param('offset'), "0");
            is($dummy_uri->query_param('account_id'), "D1234567890123456789");
            is($captured_request->method, 'POST');
        };

        it "returns the expected data" => sub {
            my $res = $sut->json_api_call('POST', '/admin/v1/admins', {
                limit => 25,
                offset => 0,
                account_id => 'D1234567890123456789',
            });

            cmp_bag($res, [{ thing => 1 }, { thing =>2 }]);
        };
    };

    describe "json_api_call_full" => sub {

        it "creates the expected GET request" => sub {
            my $res = $sut->json_api_call_full('GET', '/admin/v1/admins', {
                limit => 25,
                offset => 0,
                account_id => 'D1234567890123456789',
            });

            is($captured_request->uri->host, $host);
            is($captured_request->uri->path, '/admin/v1/admins');
            is($captured_request->uri->query_param('limit'), "25");
            is($captured_request->uri->query_param('offset'), "0");
            is($captured_request->uri->query_param('account_id'), "D1234567890123456789");
            is($captured_request->method, 'GET');
        };

        it "creates the expected POST request" => sub {
            my $res = $sut->json_api_call_full('POST', '/admin/v1/admins', {
                limit => 25,
                offset => 0,
                account_id => 'D1234567890123456789',
            });

            my $dummy_uri = URI->new("https://example.com");
            $dummy_uri->query($captured_request->content);
            is($captured_request->uri->host, $host);
            is($captured_request->uri->path, '/admin/v1/admins');
            is($dummy_uri->query_param('limit'), "25");
            is($dummy_uri->query_param('offset'), "0");
            is($dummy_uri->query_param('account_id'), "D1234567890123456789");
            is($captured_request->method, 'POST');
        };

        it "returns the expected data" => sub {
            my $res = $sut->json_api_call_full('POST', '/admin/v1/admins', {
                limit => 25,
                offset => 0,
                account_id => 'D1234567890123456789',
            });

            cmp_deeply($res, {
                stat     => 'OK',
                response => bag({ thing => 1 }, { thing =>2 }),
                metadata => { next_offset => undef },
            });
        };
    };

    describe "json_paging_api_call method" => sub {
        my @captured_requests;
        before each => sub {
            @captured_requests = ();
            LWP::UserAgent->stubs(request => sub {
                my ($ua, $req) = @_;
                push @captured_requests, $req;
                return $mock_response;
            });
        };

        it "returns a Duo::Api::Iterator" => sub {
            my $iter = $sut->json_paging_api_call('GET', '/admin/v1/admins', {
                limit => 25,
                offset => 0,
                account_id => 'D1234567890123456789',
            });
            isa_ok($iter, "Duo::API::Iterator");
        };

        it "doesn't make an api call until next is called on the iterator" => sub {
            my $iter = $sut->json_paging_api_call('GET', '/admin/v1/admins', {
                limit => 25,
                offset => 0,
                account_id => 'D1234567890123456789',
            });
            is(scalar(@captured_requests), 0);
        };

        it "creates the expected GET request when next is called" => sub {
            my $iter = $sut->json_paging_api_call('GET', '/admin/v1/admins', {
                limit => 25,
                offset => 0,
                account_id => 'D1234567890123456789',
            });
            $iter->next();

            ($captured_request) = @captured_requests;
            is($captured_request->uri->host, $host);
            is($captured_request->uri->path, '/admin/v1/admins');
            is($captured_request->uri->query_param('limit'), "25");
            is($captured_request->uri->query_param('offset'), "0");
            is($captured_request->uri->query_param('account_id'), "D1234567890123456789");
            is($captured_request->method, 'GET');
        };

        it "retrieves the expected data" => sub {
            my $iter = $sut->json_paging_api_call('GET', '/admin/v1/admins', {
                limit => 25,
                offset => 0,
                account_id => 'D1234567890123456789',
            });
            my @response_data = $iter->all();

            cmp_bag(\@response_data, [{thing => 1}, {thing => 2}]);
        };

        it "dies if the response data isn't a list" => sub {
            $mock_response->stubs(
                content => '{"stat":"OK", "response": {"thing": 1}}'
            );

            my $iter = $sut->json_paging_api_call('GET', '/admin/v1/admins', {
                limit => 25,
                offset => 0,
                account_id => 'D1234567890123456789',
            });

            throws_ok { $iter->next() } qr/Expected response data to be a list/, '';
        };

        it "makes multiple api calls if there is more data to retrieve" => sub {
            $mock_response->stubs(
                content => sub {
                    if (@captured_requests == 1) {
                        return '{"stat":"OK", "response": [{"thing": 1}, {"thing": 2}], "metadata": {"next_offset": 2}}';
                    }

                    return '{"stat":"OK", "response": [{"thing": 3}, {"thing": 4}], "metadata": {"next_offset": null}}';
                }
            );

            my $iter = $sut->json_paging_api_call('GET', '/admin/v1/admins', {
                limit => 25,
                offset => 0,
                account_id => 'D1234567890123456789',
            });
            my @response_data = $iter->all();
            cmp_bag(\@response_data, [
              { thing => 1 },
              { thing => 2 },
              { thing => 3 },
              { thing => 4 }
            ]);

            my ($req1, $req2) = @captured_requests;
            is($req1->uri->host, $host);
            is($req1->uri->path, '/admin/v1/admins');
            is($req1->uri->query_param('limit'), "25");
            is($req1->uri->query_param('offset'), "0");
            is($req1->uri->query_param('account_id'), "D1234567890123456789");
            is($req1->method, 'GET');

            is($req2->uri->host, $host);
            is($req2->uri->path, '/admin/v1/admins');
            is($req2->uri->query_param('limit'), "25");
            is($req2->uri->query_param('offset'), "2");
            is($req2->uri->query_param('account_id'), "D1234567890123456789");
            is($req2->method, 'GET');
        };
    };
};

runtests;
