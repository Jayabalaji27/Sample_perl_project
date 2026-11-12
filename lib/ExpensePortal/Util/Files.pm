package ExpensePortal::Util::Files;
use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(read_receipt save_receipt write_export);

# Receipts and exports on disk.

# The text of a stored receipt. Dies when it cannot be read.
sub read_receipt {
    my ($path) = @_;
    open(my $fh, "<$path") or die "Cannot read the receipt $path: $!\n";
    binmode $fh, ':encoding(UTF-8)';
    local $/ = undef;
    my $text = <$fh>;
    close $fh;
    return $text;
}

# Stores a receipt's text and returns how many characters it holds.
sub save_receipt {
    my ($path, $text) = @_;
    open(my $fh, '>:encoding(UTF-8)', $path) or die "Cannot store the receipt $path: $!\n";
    print {$fh} $text;
    close $fh;
    return length $text;
}

# Writes the lines of an export file and returns how many it wrote.
sub write_export {
    my ($path, $lines) = @_;
    open(my $fh, '>:utf8', $path) or die "Cannot write the export $path: $!\n";
    print {$fh} "$_\n" for @{$lines};
    close $fh;
    return scalar @{$lines};
}

1;
