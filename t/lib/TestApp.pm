package TestApp;
use strict;
use warnings;

use Exporter 'import';
use File::Temp qw(tempdir);
use Test::Mojo;

our @EXPORT_OK = qw(new_app as);

# The application for a test: its own in-memory database and its own folders,
# gone when the test ends.

my $TOKEN = 'test-token';

# A Test::Mojo over a fresh application, and the folder its files go in.
sub new_app {
    my $dir = tempdir(CLEANUP => 1);
    my $t   = Test::Mojo->new(
        ExpensePortal => {
            api_token      => $TOKEN,
            database       => ':memory:',
            receipt_dir    => "$dir/receipts",
            export_dir     => "$dir/exports",
            approval_limit => 500,
        }
    );
    return ($t, $dir);
}

# The headers of a request made by `employee`.
sub as {
    my ($employee) = @_;
    return {Authorization => "Bearer $TOKEN", 'X-Employee' => $employee};
}

1;
