use Test::More;
use lib qw(t/lib);
use DBICTest;
use DBICTest::HelperRels;

require "t/run/26might_have.tl";
run_tests(DBICTest->schema);