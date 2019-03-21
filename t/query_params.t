use Test::More;
use strict;
use warnings;

use Test::NoWarnings;

plan(tests => 8);

use_ok('Duo::API');

sub canon_params_is {
    my ($params, $expected, $test_name) = @_;

    my $ikey = 'ikey' . rand();
    my $skey = 'skey' . rand();
    my $host = 'host' . rand();
    my $client = Duo::API->new($ikey, $skey, $host);
    is($client->canonicalize_params($params),
       $expected,
       $test_name);
}

canon_params_is(
    {'realname' => 'First Last', 'username' => 'root'},
    'realname=First%20Last&username=root',
    'simple',
);

canon_params_is(
    {},
    '',
    'zero params',
);

canon_params_is(
    {'realname' => 'First Last'},
    'realname=First%20Last',
    'one param',
);

canon_params_is(
    {
        'digits' => '0123456789',
        'letters' => 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'punctuation' => '!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~',
        'whitespace' => "\t\n\x0b\x0c\r ",
    },
    'digits=0123456789&letters=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ&punctuation=%21%22%23%24%25%26%27%28%29%2A%2B%2C-.%2F%3A%3B%3C%3D%3E%3F%40%5B%5C%5D%5E_%60%7B%7C%7D~&whitespace=%09%0A%0B%0C%0D%20',
    'printable ascii characters'
);

canon_params_is(
    {
        'bar' => "\x{2815}\x{aaa3}\x{37cf}\x{4bb7}\x{36e9}\x{cc05}\x{668e}\x{8162}\x{c2bd}\x{a1f1}",
        'baz' => "\x{0df3}\x{84bd}\x{5669}\x{9985}\x{b8a4}\x{ac3a}\x{7be7}\x{6f69}\x{934a}\x{b91c}",
        'foo' => "\x{d4ce}\x{d6d6}\x{7938}\x{50c0}\x{8a20}\x{8f15}\x{fd0b}\x{8024}\x{5cb3}\x{c655}",
        'qux' => "\x{8b97}\x{c846}-\x{828e}\x{831a}\x{ccca}\x{a2d4}\x{8c3e}\x{b8b2}\x{99be}",
    },
    'bar=%E2%A0%95%EA%AA%A3%E3%9F%8F%E4%AE%B7%E3%9B%A9%EC%B0%85%E6%9A%8E%E8%85%A2%EC%8A%BD%EA%87%B1&baz=%E0%B7%B3%E8%92%BD%E5%99%A9%E9%A6%85%EB%A2%A4%EA%B0%BA%E7%AF%A7%E6%BD%A9%E9%8D%8A%EB%A4%9C&foo=%ED%93%8E%ED%9B%96%E7%A4%B8%E5%83%80%E8%A8%A0%E8%BC%95%EF%B4%8B%E8%80%A4%E5%B2%B3%EC%99%95&qux=%E8%AE%97%EC%A1%86-%E8%8A%8E%E8%8C%9A%EC%B3%8A%EA%8B%94%E8%B0%BE%EB%A2%B2%E9%A6%BE',
    'unicode fuzz values',
);

canon_params_is(
    {
        "\x{469a}\x{287b}\x{35d0}\x{8ef3}\x{6727}\x{502a}\x{0810}\x{d091}\xc8\x{c170}" => "\x{0f45}\x{1a76}\x{341a}\x{654c}\x{c23f}\x{9b09}\x{abe2}\x{8343}\x{1b27}\x{60d0}",
        "\x{7449}\x{7e4b}\x{ccfb}\x{59ff}\x{fe5f}\x{83b7}\x{adcc}\x{900c}\x{cfd1}\x{7813}" => "\x{8db7}\x{5022}\x{92d3}\x{42ef}\x{207d}\x{8730}\x{acfe}\x{5617}\x{0946}\x{4e30}",
        "\x{7470}\x{9314}\x{901c}\x{9eae}\x{40d8}\x{4201}\x{82d8}\x{8c70}\x{1d31}\x{a042}" => "\x{17d9}\x{0ba8}\x{9358}\x{aadf}\x{a42a}\x{48be}\x{fb96}\x{6fe9}\x{b7ff}\x{32f3}",
        "\x{c2c5}\x{2c1d}\x{2620}\x{3617}\x{96b3}F\x{8605}\x{20e8}\x{ac21}\x{5934}" => "\x{fba9}\x{41aa}\x{bd83}\x{840b}\x{2615}\x{3e6e}\x{652d}\x{a8b5}\x{d56b}U",
    },
    '%E4%9A%9A%E2%A1%BB%E3%97%90%E8%BB%B3%E6%9C%A7%E5%80%AA%E0%A0%90%ED%82%91%C3%88%EC%85%B0=%E0%BD%85%E1%A9%B6%E3%90%9A%E6%95%8C%EC%88%BF%E9%AC%89%EA%AF%A2%E8%8D%83%E1%AC%A7%E6%83%90&%E7%91%89%E7%B9%8B%EC%B3%BB%E5%A7%BF%EF%B9%9F%E8%8E%B7%EA%B7%8C%E9%80%8C%EC%BF%91%E7%A0%93=%E8%B6%B7%E5%80%A2%E9%8B%93%E4%8B%AF%E2%81%BD%E8%9C%B0%EA%B3%BE%E5%98%97%E0%A5%86%E4%B8%B0&%E7%91%B0%E9%8C%94%E9%80%9C%E9%BA%AE%E4%83%98%E4%88%81%E8%8B%98%E8%B1%B0%E1%B4%B1%EA%81%82=%E1%9F%99%E0%AE%A8%E9%8D%98%EA%AB%9F%EA%90%AA%E4%A2%BE%EF%AE%96%E6%BF%A9%EB%9F%BF%E3%8B%B3&%EC%8B%85%E2%B0%9D%E2%98%A0%E3%98%97%E9%9A%B3F%E8%98%85%E2%83%A8%EA%B0%A1%E5%A4%B4=%EF%AE%A9%E4%86%AA%EB%B6%83%E8%90%8B%E2%98%95%E3%B9%AE%E6%94%AD%EA%A2%B5%ED%95%ABU',
    'unicode fuzz keys and values',
);
