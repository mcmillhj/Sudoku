package Sudoku::Utils;
use Data::Dumper;
use List::MoreUtils qw(all);

sub min_key {
	my ($grid_ref, $squares_ref) = @_;
	
	my $min     = 1_000_000;
	my $min_key = $squares_ref->[0]; # default  value
	
	# search through the grid for the 
	# square with the fewest possibilities
	for my $k ( @$squares_ref ) {
		if( length( $grid_ref->{$k} ) > 1 ) {
			$min_key = $k;
			last;
			#if( length($grid_ref->{$k} ) < $min) {			
			#	$min = length($grid_ref->{$k});
			#	$min_key = $k;
			#}
		}
	}
	
	return $min_key;
}

# flatten
# Takes an Array reference nested at most 1 time and
# returns a flat Array with the same elements
sub flatten {
	my ($arr_ref) = @_;
	my @flattened;

	# iterate through nested array and flatten
	for my $subarray (@$arr_ref) {
		push @flattened, @$subarray;
	}

	return @flattened;
}

sub solved {
	my ($grid_ref, $squares_ref) = @_;
	
	# True
	return 1 if all { length( $grid_ref->{$_} ) == 1 } @$squares_ref; 
	
	# False
	return 0;
}

1; # END