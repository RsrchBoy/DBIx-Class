use Test::More;
use lib qw(t/lib);
use DBICTest;
use DBICTest::BasicRels;

require "t/run/25utf8.tl";
run_tests(DBICTest->schema);