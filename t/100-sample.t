use strict;
use warnings;

use Path::Class;
use Test::More;
use Plack::Test;
use Plack::Util;
use HTTP::Request;

my $app_name;

BEGIN{
    $app_name ="SampleApp";
    dir($app_name)->rmtree if( -d $app_name);
}

system("amon2-setup.pl $app_name");

system("cd $app_name; ../amon2-tt2tx.pl");

chdir $app_name;

my $app = Plack::Util::load_psgi("app.psgi");

test_psgi $app, sub {
    my $cb = shift;

    my $req = HTTP::Request->new(GET => 'http://localhost/');
    my $res = $cb->($req);

    is $res->code, 200;
};

chdir '..';

done_testing();


