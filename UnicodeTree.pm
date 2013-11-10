package Graph::Reader::UnicodeTree;

# Pragmas.
use base qw(Graph::Reader);
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8);
use Readonly;

# Constants.
Readonly::Scalar our $EMPTY_STR => q{};
Readonly::Scalar our $GR_LINE => decode_utf8(q{───});
Readonly::Scalar our $GR_TREE => decode_utf8(q{─┬─});

# Version.
our $VERSION = 0.01;

# Read graph subroutine.
sub _read_graph {
	my ($self, $graph, $fh) = @_;
	my @indent = ([0, undef]);
	while (my $line = decode_utf8(<$fh>)) {
		chomp $line;

		# Remove indent.
		my $parseable_line = substr $line, $indent[-1]->[0];

		# Split to vertexes.
		my @new_indent;
		my @vertexes;
		my $new_indent = $indent[-1]->[0];
		my $last_indent;
		foreach my $new_block (split m/$GR_TREE/ms, $parseable_line) {
			if (defined $last_indent) {
				push @new_indent, $last_indent;
				$last_indent = undef;
			}
			my $last_vertex;	
			foreach my $new_vertex (split m/$GR_LINE/ms, $new_block) {
				push @vertexes, $new_vertex;
				$last_vertex = $new_vertex;
			}
			$new_indent += (length $new_block) + 3;
			$last_indent = [$new_indent, $last_vertex];
		}

		# Add vertexes and edges.
		my $first_v;
		if (defined $indent[-1]->[1]) {
			$first_v = $indent[-1]->[1];
		} else {
			$first_v = shift @vertexes;
		}
		$graph->add_vertex($first_v);
		foreach my $second_v (@vertexes) {
			$graph->add_vertex($second_v);
			$graph->add_edge($first_v, $second_v);
			$first_v = $second_v;
		}

		# Update indent.
		my $end_pos = $indent[-1]->[0] - 2;
		if ($end_pos > 0) {
			my $end_char = substr $line, $end_pos, 1;
			if ($end_char eq decode_utf8('└')) {
				pop @indent;
			}
		}
		if (@new_indent) {
			push @indent, @new_indent;
		}
	}
	return;
}

1;
