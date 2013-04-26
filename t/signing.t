use Test::More;
use strict;
use warnings;

plan(tests => 2);

use_ok('Duo::API');

my $date = 'Fri, 07 Dec 2012 17:18:00 -0000';
my $host = 'foO.BAr52.cOm';
my $method = 'PoSt';
my $path = '/Foo/BaR2/qux';
my $params = {
    "\x{469a}\x{287b}\x{35d0}\x{8ef3}\x{6727}\x{502a}\x{0810}\x{d091}\xc8\x{c170}" => "\x{0f45}\x{1a76}\x{341a}\x{654c}\x{c23f}\x{9b09}\x{abe2}\x{8343}\x{1b27}\x{60d0}",
    "\x{7449}\x{7e4b}\x{ccfb}\x{59ff}\x{fe5f}\x{83b7}\x{adcc}\x{900c}\x{cfd1}\x{7813}" => "\x{8db7}\x{5022}\x{92d3}\x{42ef}\x{207d}\x{8730}\x{acfe}\x{5617}\x{0946}\x{4e30}",
    "\x{7470}\x{9314}\x{901c}\x{9eae}\x{40d8}\x{4201}\x{82d8}\x{8c70}\x{1d31}\x{a042}" => "\x{17d9}\x{0ba8}\x{9358}\x{aadf}\x{a42a}\x{48be}\x{fb96}\x{6fe9}\x{b7ff}\x{32f3}",
    "\x{c2c5}\x{2c1d}\x{2620}\x{3617}\x{96b3}F\x{8605}\x{20e8}\x{ac21}\x{5934}" => "\x{fba9}\x{41aa}\x{bd83}\x{840b}\x{2615}\x{3e6e}\x{652d}\x{a8b5}\x{d56b}U",
};

my $ikey = 'test_ikey';
my $skey = 'gtdfxv9YgVBYcF6dl2Eq17KUQJN2PLM2ODVTkvoT';
my $client = Duo::API->new($ikey, $skey, $host);

$params = $client->canonicalize_params($params);
my $actual = $client->sign($method,
                           $path,
                           $params,
                           $date);
my $expected = 'Basic dGVzdF9pa2V5OmYwMTgxMWNiYmY5NTYxNjIzYWI0NWI4OTMwOTYyNjdmZDQ2YTUxNzg=';
is($actual, $expected);
