package Sudoku::Test;
use Test::More; 
use Sudoku;
use Sudoku::Utils;

my ($squares_ref, $unitlist_ref, $units_ref, $peers_ref) = Sudoku::grab_refs();
my @squares  = @$squares_ref;
my @unitlist = @$unitlist_ref;
my %units    = %$units_ref;
my %peers    = %$peers_ref;
 
sub test_board {
	# unit tests for board creation
	is(@squares,  81, "size of Sudoku grid is 81 squares.");
	is(@unitlist, 27, "there are 27 groups of units.");	
	for my $s (@squares) {
		my @units = @{${units{$s}}};
		my @peers = @{${peers{$s}}};
		is($#units + 1,  3, "Each square has 3 units.");
		is($#peers + 1, 20, "Each square has 20 peers.")
	}
	ok(\@{$units{'C2'}} ~~ [['A2', 'B2', 'C2', 'D2', 'E2', 'F2', 'G2', 'H2', 'I2'],
	                        ['C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7', 'C8', 'C9'],
	                        ['A1', 'A2', 'A3', 'B1', 'B2', 'B3', 'C1', 'C2', 'C3']], 
	                        "Test for units of C2");            
	ok(\@{$peers{'C2'}} ~~ ['A2', 'B2', 'D2', 'E2', 'F2', 'G2', 'H2', 'I2',
	                        'C1', 'C3', 'C4', 'C5', 'C6', 'C7', 'C8', 'C9',
	                        'A1', 'A3', 'B1', 'B3'],
	                        "Test for peers of C2");
}        

sub test_easy_puzzles { 
	my ($display) = @_; # flag to display the solutions
	
	# read easy puzzles from file
	open(my $puzzle_file, "<", "easy_puzzles.txt") 
		or die "cannot open < easy_puzzles.txt: $!";
		
	my $puzzle_string;
	while(my $line = <$puzzle_file>) {
		$puzzle_string .= $line;
	} 
	
	# strip all whitespace 
	$puzzle_string =~ s/\s+//g;
	
	# split into individual puzzles
	my @puzzles = split("========", $puzzle_string);
		
	# test each puzzle
	foreach my $i ( 0 .. $#puzzles ) {
		
		# get the current puzzle
		my $puzzle = $puzzles[$i];

		Sudoku::display_grid(
			Sudoku::grid_values(
					$puzzle
				)
			) if $display; 

		# solve the puzzle	
		my $answer = 
			Sudoku::solve (
				$puzzle
			);
			
		print "\n\t  |  |  |  |  |  |  |\n" if $display;
		print "\t  v  v  v  v  v  v  v\n\n" if $display;
		
		Sudoku::display_grid(
			$answer
		) if $display; 
		
		print "\n\n" if $display;
		is(Sudoku::Utils::solved($answer, $squares_ref), 1, "Puzzle must be solved.");
	}	
	
	# close file
	close $puzzle_file;
}

sub test_hard_puzzles { 
	my ($display) = @_; # flag to display the solutions 
	
	# read hard puzzles from file
	open(my $puzzle_file, "<", "hard_puzzles.txt") 
		or die "cannot open < hard_puzzles.txt: $!";

	my $puzzle_string;
	while(my $line = <$puzzle_file>) {
		$puzzle_string .= $line;
	} 
	
	my @puzzles = split(/\s+/, $puzzle_string);
	
	# test each puzzle
	for my $i ( 0 .. $#puzzles ) {
		# Get the current puzzle
		my $puzzle = $puzzles[$i];
	
		Sudoku::display_grid(
			Sudoku::grid_values(
					$puzzle
				)
			) if $display; 
			
		# solve the puzzle
		my $answer = 
			Sudoku::solve (
				$puzzle
			);

		print "\n\t  |  |  |  |  |  |  |\n" if $display;
		print "\t  v  v  v  v  v  v  v\n\n" if $display;
		
		Sudoku::display_grid(
			$answer
		) if $display; 
		
		print "\n\n" if $display;
		
		is(Sudoku::Utils::solved($answer, $squares_ref), 1, "Puzzle must be solved.");
	}	
	
	# close file
	close $puzzle_file;
}

# use the $display flag to see the actual 
# solved puzzle after the test occurs
sub test_all {
	my $display = 1;
	test_board();
	test_easy_puzzles($display);
	test_hard_puzzles($display);
	done_testing();
}

# test the program
test_all();

1; # END