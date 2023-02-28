
use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('Tk::PopList') };

use Test::Tk;

createapp(
	-width => 300,
	-height => 200,
);

my @values = qw(black blue brown cyan green grey magenta orange pink red violet white yellow);

my $poplist;
if (defined $app) {
	my $b = $app->Button(
		-command => sub  { $poplist->popUp },
		-text => 'Color: ',
	)->pack;
	$poplist = $app->PopList(
		-filter => 1,
		-motionselect => 1,
		-values => \@values,
		-selectcall => sub {
			my $val = shift;
			$b->configure(-text => "Color: $val");
		},
		-widget => $b,
	);
}

@tests = (
	[sub { return defined $poplist }, 1, 'Created PopList'],
);
starttesting;


