package Sudoku;

use strict;
use warnings;
use Data::Dumper;
use List::MoreUtils qw(uniq all zip);
use List::Util qw(first);
use Storable qw(dclone);
use lib '../';
use Sudoku::Utils;

# globals
my $digits        = "123456789";
my $letters       = "ABCDEFGHI";
my @block_digits  = ( '123', '456', '789', );
my @block_letters = ( 'ABC', 'DEF', 'GHI', );

my $rows = $letters;
my $cols = $digits;

# Array of every square on the Sudoku board A1 - I9
my @squares = cross( $rows, $cols, 1 );

# build unitlist
# List of all 'units' on the Sudoku board
# A unit is any grouping of 9 squares: vertical, horizontal, or blocks
my @unitlist;

# add vertical lines
push @unitlist, map { cross( $rows, $_ ) } split( //, $cols );

# add horizontal lines
push @unitlist, map { cross( $_, $cols ) } split( //, $rows );

# push individual blocks of 9 into the unitlist
for my $block_l (@block_letters) {
	for my $block_d (@block_digits) {
		push @unitlist, cross( $block_l, $block_d );
	}
}

# build units map
# map of the 'unit' for each square
# $units{'C2'} = [['C1','C2','C3','C4','C5','C6','C7','C8','C9'],
#				  ['A2','B2','C2','D2','E2','F2','G2','H2','I2'],
#				  ['A1','A2','A3','B1','B2','B3','C1','C2','C3']]
my %units;

# pre-initialize every key with an empty array
for my $s (@squares) {
	$units{$s} = [];
}

# iterate through the unitlist for every section of 9
# that contains a square, add those 9 to the unit map for the entry s
for my $u (@unitlist) {
	for my $s (@squares) {
		if ( $s ~~@$u ) {

			# append to existing entry
			push @{ $units{$s} }, [@$u];
		}
	}    # end inner-for
}    # end outer-for

# build peers map
# peers are squares on the grid that are in the same unit as the key
# contains no duplicates or the key itself
# $peers{'C2'} = ['A2', 'B2', 'D2', 'E2', 'F2', 'G2', 'H2', 'I2',
#                 'C1', 'C3', 'C4', 'C5', 'C6', 'C7', 'C8', 'C9',
#                 'A1', 'A3', 'B1', 'B3']
my %peers;

# for each square (each key in %units)
# remove the duplicates and $key from the values in $units{$key}
foreach my $key ( keys %units ) {

	# flatten array at this $key
	# remove duplicates and also this $key from the array
	my @uniq_flat =
	  grep { $_ ne $key } uniq( Sudoku::Utils::flatten( \@{ $units{$key} } ) );

	# add this unique, flat entry to the peers map
	$peers{$key} = \@uniq_flat;
}

# compute the cross product of two Lists
# cross((1,2),(A, B)) = ((1,A), (1,B), (2,A), (2,B))
sub cross {

	# unpack strings
	my ( $A, $B, $merge ) = @_;

	# array to hold products
	my @cross;
	my @out;

	# split strings into arrays
	my @A_array = split( //, $A );
	my @B_array = split( //, $B );

	# glue the characters together and append to output array
	for my $r (@A_array) {
		for my $c (@B_array) {
			push @cross, $r . $c;
		}
	}

	# separate into blocks on 9 to match a Sudoku board
	while (@cross) {
		push @out, [ splice( @cross, 0, 9 ) ];
	}

	# if the merge flag is set, flatten the array
	return Sudoku::Utils::flatten( \@out ) if $merge;

	return @out;
}

# Display the Sudoku board as a 2D grid
sub display_grid {
	my ($grid_ref) = @_;

	unless ($grid_ref) {
		print "Error reading grid.\n";
		return 0;
	}

	# push into grid structure
	my @grid;

	for my $r ( split( //, $rows ) ) {
		my @row;
		for my $c ( split( //, $cols ) ) {
			push @row, $grid_ref->{ $r . $c };
		}
		push @grid, \@row;
	}

	my $count = 1;
	for my $row (@grid) {
		format STDOUT = 
@||| @||| @||| | @||| @||| @||| | @||| @||| @|||
@$row
.
		write;

		# separator
		print "---------------+----------------+---------------\n"
		  if $count < 7 && $count++ % 3 == 0;
	}
	
	# return correct result
	return $grid_ref;
}

sub parse_grid {
	my ($grid) = @_;
	my %values;

	# default possible values for each square to every digit 1 - 9
	for my $s (@squares) {
		$values{$s} = $digits;
	}

# map each square of the Sudoku board to a single character from the board string
# that was passed to this function
	my $grid_ref = grid_values($grid);

	foreach my $key ( keys %{$grid_ref} ) {
		my $d = $grid_ref->{$key};

		if ( index( $digits, $d ) != -1 && not assign( \%values, $key, $d ) ) {
			return 0;    # Fail if we can't assign d to square s
		}
	}

	return \%values;
}

# Convert grid into a dict of {square: char} with '0' or '.' for empties.
sub grid_values {
	my ($grid) = @_;

	# ignore invalid characters
	my @chars = $grid =~ m/([\d.])/g;

	# map squares on the grid to characters from STDIN
	my %grid_hash;
	@grid_hash{@squares} = @chars;

	return \%grid_hash;
}

# Eliminate all the other values (except d) from $values{$s} and propagate.
# Return values, except return False if a contradiction is detected.
sub assign {
	my ( $values_ref, $s, $d ) = @_;

	# other_values is everything from $values_ref->{$s} except for d
	( my $other_values = $values_ref->{$s} ) =~ s/$d//;

	#print "Assign\n";
	#print Dumper($values_ref), "\n";
	#print "s = $s\nd = $d\n\n";
	for my $val ( split( //, $other_values ) ) {
		my $r = eliminate( $values_ref, $s, $val );

		return 0 unless $r;
	}

	#return $values_ref
	#  if all { eliminate( $values_ref, $s, $_ ) } split( //, $other_values );

	# return False if any of the calls to eliminate fail
	return $values_ref;
}

# Eliminate d from $values{$s}; propagate when %values or places <= 2.
# Return %values, except return False if a contradiction is detected.
sub eliminate {
	my ( $values_ref, $s, $d ) = @_;

	if ( index( $values_ref->{$s}, $d ) == -1 ) {
		return $values_ref;    # already eliminated this value
	}

	# replace $d in $values{$s} with nothing: ''
	$values_ref->{$s} =~ s/$d//;    # unless $values_ref->{$s} == $d;

	# (1) If a square s is reduced to one value d2,
	#     then eliminate d2 from the peers.
	if ( length( $values_ref->{$s} ) == 0 ) {
		return 0;                   # False, contradiction
	}
	elsif ( length( $values_ref->{$s} ) == 1 ) {

		# only one possible value, remove this value from all peers
		# since only one value 1-9 can appear
		my $d2 = $values_ref->{$s};

		return 0
		  if not all { eliminate( $values_ref, $_, $d2 ) } @{ $peers{$s} };
	}

	# (2) If a unit u is reduced to only one place for a value d,
	#     then put it there.
	for my $u ( @{ $units{$s} } ) {

		# possible places for a digit
		my @dplaces =
		  map { index( $values_ref->{$_}, $d ) != -1 ? $_ : () } @$u;

		if ( scalar @dplaces == 0 ) {
			return 0;
		}
		elsif ( scalar @dplaces == 1 ) {
			return 0 if not assign( $values_ref, $dplaces[0], $d );
		}
	}

	# return updated hash ref
	return $values_ref;
}

# solve the entire puzzle
# should work for any Sudoku puzzle, regardless of difficulty
sub solve {
	my ($grid) = @_;

	return search( 
		parse_grid($grid) 
	);
}

# Use depth first search and propogation to solve the puzzle
sub search {
	my ($grid_ref) = @_;

	# Failure in earlier piece of program
	return 0 unless $grid_ref;

	# solved, each string is of length 1
	# meaning there is only a single possible digit per square
	#return $grid_ref if all { length( $grid_ref->{$_} ) == 1 } @squares;

	if ( Sudoku::Utils::solved( $grid_ref, \@squares ) ) {
		return $grid_ref;
	}

	# recurse
	# choose the unfilled squares with the least amount of possibilities
	my $min_key = Sudoku::Utils::min_key( $grid_ref, \@squares );

	return List::Util::first { Sudoku::Utils::solved( $_, \@squares ) }
	  map { 
	  	search( assign( dclone($grid_ref), $min_key, $_ ) ) 
	  } split( //, $grid_ref->{$min_key} );
}

# pass references to the Test module for testing
sub grab_refs {
	return ( \@squares, \@unitlist, \%units, \%peers );
}
1;                                                                 # END
