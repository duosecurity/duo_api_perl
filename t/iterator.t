use Test::Spec;
use Test::More;
use Test::Exception;

use Duo::API::Iterator;

describe "A Duo Api Iterator" => sub {
    describe "it's new method" => sub {
        it "dies when a generator is not supplied" => sub {
            throws_ok {
                my $iter = Duo::API::Iterator->new();
            } qr/Missing required arguments: generator/, '';
        };

        it "dies if the supplied generator is not a sub ref" => sub{
            throws_ok {
              my $iter = Duo::API::Iterator->new(generator => 42);
            } qr/The generator parameter must be a subroutine reference./, '';
        };

        it "returns a new iterator when called with appropriate arguments"
          => sub {
              my $iter = Duo::API::Iterator->new(generator => sub{ return 42 });
          };
    };

    describe "it's next method" => sub {
        my $sut;
        my $items;
        before each => sub {
            my $gen = sub {
                if ($items) {
                    return $items--;
                }

                return;
            };

            $sut = Duo::API::Iterator->new(generator => $gen);
        };

        it "returns the expected number of items" => sub {
            my $expected_count = 42;
            $items = $expected_count;
            my @found;

            while(my $item = $sut->next()) {
                push @found, $item;
            }

            is(scalar(@found), $expected_count);
        };
    };

    describe "it's all method" => sub {
        my $sut;
        my $items;
        before each => sub {
            my $gen = sub {
                if ($items) {
                    return $items--;
                }

                return;
            };

            $sut = Duo::API::Iterator->new(generator => $gen);
        };

        it "returns all data from the beginning" => sub {
            my $expected_count = 42;
            $items = $expected_count;
            my @found = $sut->all();

            is(scalar(@found), $expected_count);
        };

        it "resumes after next" => sub {
            my $expected_count = 42;
            $items = $expected_count + 1;
            $sut->next();
            my @found = $sut->all();

            is(scalar(@found), $expected_count);
        };
    };
};

runtests;
