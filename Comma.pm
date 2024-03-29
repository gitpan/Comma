=head1 NAME

Comma - This module is DEPRECATED.  It has been renamed to L<Tie::Comma>.

=head1 VERSION

This documentation describes version 0.03 of Comma.pm, January 07, 2005

=cut

use strict;
package Comma;
$Comma::VERSION = 0.03;

use Exporter;
use vars qw/@ISA @EXPORT %comma/;
@ISA       = qw/Exporter/;
@EXPORT    = qw/%comma/;

# Defaults
our $thou_sep = ',';
our $deci_sep = '.';
our $grouping = 3;

# Configure for locale
eval
{
    require POSIX;
    my $loc = POSIX::setlocale(POSIX::LC_NUMERIC());
    my $lc  = POSIX::localeconv();
    $thou_sep = $lc->{thousands_sep} || $thou_sep;
    $deci_sep = $lc->{decimal_point} || $deci_sep;
    $grouping = $lc->{grouping}? unpack('c', $lc->{grouping}) : $grouping;
};   # Ignore any errors in this block -- just fall back to the defaults.

# Substitution pattern
my $num_pat = "(" . ("\\d" x $grouping) . ")(?=\\d)(?!\\d*\\$deci_sep)";
my $num_re  = qr/$num_pat/;

# Here's the statement that makes it all happen.
tie our %comma, 'Comma';

# Delay loading Carp.pm until needed.
sub Comma::croak
{
    require Carp;
    goto &Carp::croak;
}

#--->     $string = commify $number;
# commify : Formats a number with commas.
# This version is taken from the Perl Cookbook.
sub commify ($)
{
    my $rev_num = reverse shift;  # The number to be formatted, reversed.
    $rev_num =~ s/$num_re/$1$thou_sep/g;
    return scalar reverse $rev_num;
}

sub TIEHASH
{
    my $class = shift;
    my $dummy;   # not used, but we need a reference.
    bless \$dummy, $class;
}

sub FETCH
{
    my $self = shift;
    my $key  = shift;
    return '' if !defined $key;    # No args? or undef? return empty string.

    my @args = split $;, $key, -1;
    @args > 3  and Comma::croak "Too many arguments to %comma";
    my ($num, $dp, $min_fw) = @args;

    for ($dp, $min_fw)
    {
        next unless defined;
        next unless length;
        s/\Q$deci_sep\E.*//o;  # remove any fractional part
        $_ = 0 unless /^-?\d+$/;
    }
    $min_fw = 0  if (!defined $min_fw  or  length $min_fw == 0);

    # Caller specified number of decimal places?
    $num = sprintf "%.${dp}f", $num  if defined $dp  &&  length $dp;

    my $cnum = commify $num;

    # Pad, if necessary.
    return $cnum if length $cnum >= $min_fw;
    my $spaces = ' ' x ($min_fw - length $cnum);
    return $spaces . $cnum;
}

use subs qw(
 STORE    EXISTS    CLEAR    FIRSTKEY    NEXTKEY  );
*STORE = *EXISTS = *CLEAR = *FIRSTKEY = *NEXTKEY = sub
{
    Comma::croak "Invalid call to Comma internal function";
};


1;
__END__

=head1 SYNOPSIS

 # The usual case; formatting with commas.
 $comma{$number};

 # Format with commas, and to a given number of places.
 $comma{$number, $decimal_places};

 # Format as above, with a minimum field width (right-justified).
 $comma{$number, $decimal_places, $minimum_field_width};

=head1 DESCRIPTION

I<This module is DEPRECATED>.  Use L<Tie::Comma> instead.

This module provides a global read-only hash, C<%comma>, for
formatting numbers with commas.  The tied-hash idiom is quite useful,
since you can use it within a string as easily as outside a string.

The C<%comma> hash may be "passed" one to three "arguments".

=over 4

=item One-argument form

I<$string>C< = $comma{>I<$number>C<};>

Formats I<$number> with commas.

=item Two-argument form

I<$string>C< = $comma{>I<$number>C<, >I<$decimals>C<};>

Formats I<$number> with commas and I<$decimals> decimal places.

=item Three-argument form

I<$string>C< = $comma{>I<$number>C<, >I<$decimals>C<, >I<$min_width>C<};>

Formats I<$number> with commas and I<$decimals> decimal places, and
pads it with spaces on the left (right-justifying the number) so it
takes up at least I<$min_width> characters.  If I<$decimals> is undef,
the I<$number> is formatted with commas but not to any particular
number of decimal places.

=back

=head1 EXAMPLES

 # Simple formatting with commas:
 $a = 1234567.89;
 print "With commas: $comma{$a}";      => "With commas: 1,234,567.89"

 # Specify number of decimal places:
 print "1 decimal:   $comma{$a,1}";    => "1 decimal:   1,234,567.9"
 print "3 decimals:  $comma{$a,3}";    => "3 decimals:  1,234,567.890"

 # Specify field width:
 print "Min width:  '$comma{$a,0,12}'" => "Min width:  '   1,234,568'

 # In-string computations:
 print "Seconds in a year: $comma{365 * 24 * 60 * 60}";
    => "Seconds in a year: 31,536,000";

=head1 EXPORTS

Exports C<%comma>.

=head1 REQUIREMENTS

Uses C<Carp> and C<Exporter>, which of course come with Perl.

=head1 SEE ALSO

Mark Dominus's excellent L<Interpolation> module, which provides a
much more general solution than this special-purpose module.

=head1 AUTHOR / COPYRIGHT

Eric J. Roode, roode@cpan.org

Copyright (c) 2005 by Eric J. Roode.  All Rights Reserved.
This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
