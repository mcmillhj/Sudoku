use Sudoku;

# read a single puzzle from STDIN
my $puzzle = <>;

print "\n"; # divider

# print the current (unsolved) puzzle
Sudoku::display_grid ( 
	Sudoku::grid_values(
		$puzzle
	)
);

# solve 
my $answer = Sudoku::solve( $puzzle );

# divider
print "\n\t  |  |  |  |  |  |  |\n";
print "\t  v  v  v  v  v  v  v\n\n";


# print the solved puzzle
Sudoku::display_grid( $answer );