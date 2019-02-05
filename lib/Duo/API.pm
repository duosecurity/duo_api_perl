package Duo::API;
use strict;
use warnings;

our $VERSION = '1.1';

=head1 NAME

Duo::API - Reference client to call Duo Security's API methods.

=head1 SYNOPSIS

 use Duo::API;
 my $client = Duo::API->new('INTEGRATION KEY', 'SECRET KEY', 'HOSTNAME');
 my $res = $client->json_api_call('GET', '/auth/v2/check', {});

=head1 SEE ALSO

Duo for Developers: L<https://www.duosecurity.com/api>

=head1 COPYRIGHT

Copyright (c) 2013 Duo Security

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DESCRIPTION

Duo::API objects have the following methods:

=over 4

=item new($integration_key, $integration_secret_key, $api_hostname)

Returns a handle to sign and send requests. These parameters are
obtained when creating an API integration.

=item json_api_call($method, $path, \%params)

Make a request to an API endpoint with the given HTTPS method and
parameters. Returns the parsed result if successful or dies with the
error message from the Duo Security service.

=item json_api_call_full($method, $path, \%params)

Makes a request to an API endpoint with the given HTTPS method and
parameters. Returns a hashref of the full parsed response body if successful
or dies with the error message from the Duo Security service. While
C<json_api_call> is convenient for just getting data items from an api call,
this method is required to inspect the response metadata to properly paginate.
The response data can be found in the C<response> key. The response metadata
resides in the C<metadata> key.

=item json_paging_api_call($method, $path, \%params)

Makes successive paginated requests to an API endpoint with the given HTTPS
method and parameters. Returns a C<Duo::Api::Iterator> which allows for
the retrieval of a single page at a time so as to not keep the entire set
of data in memory. The iterator's C<next> method returns the next item in a page.
If no more items exist in a page, the iterator will retrieve the next page of
data and return the first value from that list, if available. If no more data
is available, C<next> returns undef.

Example:

    my $iter = $client->json_paging_api_call('GET', ''/admin/v1/admins'', {});
    while (my $item = $iter->next()) {
        #item processing logic here
    }

Additionally, if having all of the data at once is required, it can be retrieved
by calling C<all> on the interator.

B<NOTE:> Calling C<all> retrieves all remaining items accessible to the iterator.
This means that if C<next> is called prior to calling C<all>, the items
previously returned by C<next> will not be included in the list returned by
C<all>.

Example:

    my $iter = $client->json_paging_api_call('GET', ''/admin/v1/admins'', {});
    my @items = $iter->all();

=item api_call($method, $path, \%params)

Make a request without parsing the response.

=item canonicalize_params(\%params)

Serialize a parameter hash reference to a string to sign or send.

=item sign($method, $path, $canon_params, $date)

Return the Authorization header for a request. C<$canon_params> is the
string returned by L<canonicalize_params>.

=back

=cut

use CGI qw();
use Carp qw(croak);
use Digest::HMAC_SHA1 qw(hmac_sha1_hex);
use JSON qw(decode_json encode_json);
use LWP::UserAgent;
use MIME::Base64 qw(encode_base64);
use POSIX qw(strftime);
use Scalar::Util qw(reftype);

use Duo::API::Iterator;

sub new {
    my($proto, $ikey, $skey, $host, $paging_limit) = @_;
    my $class = ref($proto) || $proto;
    $paging_limit ||= 100;
    my $self = {
        ikey         => $ikey,
        skey         => $skey,
        host         => $host,
        paging_limit => $paging_limit,
    };
    bless($self, $class);
    return $self;
}

sub canonicalize_params {
    my ($self, $params) = @_;

    my @ret;
    foreach my $key (keys %$params) {
        if (reftype($params->{$key}) eq 'ARRAY') {
            foreach my $v (@{$params->{$key}}) {
               push(@ret, join('=', CGI::escape($key), CGI::escape($v)));
            }
        } else {
            push(@ret, join('=', CGI::escape($key), CGI::escape($params->{$key})));
        }
    }
    return join('&', sort(@ret));
}

sub sign {
    my ($self, $method, $path, $canon_params, $date) = @_;
    my $canon = join("\n",
                     $date,
                     uc($method),
                     lc($self->{'host'}),
                     $path,
                     $canon_params);
    my $sig = hmac_sha1_hex($canon, $self->{'skey'});
    my $auth = join(':',
                    $self->{'ikey'},
                    $sig);
    $auth = 'Basic ' . encode_base64($auth, '');
    return $auth;
}

sub api_call {
    my ($self, $method, $path, $params) = @_;
    $params ||= {};

    my $canon_params = $self->canonicalize_params($params);
    my $date = strftime('%a, %d %b %Y %H:%M:%S -0000',
                        gmtime(time()));
    my $auth = $self->sign($method, $path, $canon_params, $date);

    my $ua = LWP::UserAgent->new();
    my $req = HTTP::Request->new();
    $req->method($method);
    $req->protocol('HTTP/1.1');
    $req->header('If-SSL-Cert-Subject' => qr{CN=[^=]+\.duosecurity.com$});
    $req->header('Authorization' => $auth);
    $req->header('Date' => $date);
    $req->header('Host' => $self->{'host'});

    if (grep(/^$method$/, qw(POST PUT))) {
        $req->header('Content-type' => 'application/x-www-form-urlencoded');
        $req->content($canon_params);
    }
    else {
        $path .= '?' . $canon_params;
    }

    $req->uri('https://' . $self->{'host'} . $path);
    if ($ENV{'DEBUG'}) {
        print STDERR $req->as_string();
    }
    my $res = $ua->request($req);
    return $res;
}

sub json_api_call {
    my ($self, @args) = @_;
    my $payload = $self->json_api_call_full(@args);

    return $payload->{response};
}

sub json_api_call_full {
    my ($self, @args) = @_;
    my $res = $self->api_call(@args);
    my $payload = $self->parse_json_response($res);

    return $payload;
}

sub parse_json_response {
    my ($self, $res) = @_;
    my $json = $res->content();
    if ($json !~ /^{/) {
        croak("Expected response body to be a JSON object. Received: $json");
    }
    my $ret = decode_json($json);
    unless ($ret->{stat} && $ret->{stat} eq 'OK') {
        my $msg = "Error $ret->{code}: $ret->{message}";
        if (defined($ret->{message_detail})) {
            $msg .= " ($ret->{message_detail})";
        }
        croak($msg);
    }
    return $ret;
}

sub json_paging_api_call {
    my ($self, $method, $path, $params) = @_;

    $params ||= {};

    # deep copy
    $params = decode_json(encode_json($params));
    $params->{limit}  ||= $self->{paging_limit};

    my @objects;
    $params->{offset} ||= 0;

    return Duo::API::Iterator->new(
        generator => sub {
            if (!@objects && defined($params->{offset})) {
                my $res = $self->json_api_call_full($method, $path, $params);

                # Did they call an endpoint which doesn't produce a list?
                if (reftype($res->{response}) ne 'ARRAY') {
                    my $original = encode_json($res->{response});
                    croak("Expected response data to be a list. Recieved: $original");
                }

                @objects = @{$res->{response}};
                $params->{offset} = $res->{metadata}{next_offset};
            }

            return shift(@objects);
        }
    );
};

1;
