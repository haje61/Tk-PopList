package Tk::Poplevel;

=head1 NAME

Tk::PopList - Popping a selection list relative to a widget

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.02';

use base qw(Tk::Derived Tk::Toplevel);

use Tk;

Construct Tk::Widget 'Poplevel';

=head1 SYNOPSIS

 require Tk::Poplevel;
 my $pop = $window->Poplevel(@options,
    -widget => $somewidget,
 );
 $pop->popUp;

=head1 DESCRIPTION

This widget pops a toplevel without ornaments relative to the widget specified in the B<-widget> option.
It aligns its size and position to the widget.

Clicking outside the toplevel will pop it down.

=head1 OPTIONS

Accepts all the options of a Toplevel widget;

=over 4

=item B<-widget>

Mandatory!

Reference to the widget the list should pop relative to.

Only available at create time.

=back

=head1 METHODS

=over 4

=cut

sub Populate {
	my ($self,$args) = @_;
	
	my $widget = delete $args->{'-widget'};
	die 'You need to set the -widget option' unless defined $widget;

	$self->SUPER::Populate($args);

	$self->{POPDIRECTION} = '';
	$self->{WIDGET} = $widget;
	
	$self->overrideredirect(1);
	$self->withdraw;
	$self->parent->bind('<Button-1>', [$self, 'popDown']);
	$self->ConfigSpecs(
		-popdirection => ['PASSIVE', undef, undef, 'up'],
		-confine => ['PASSIVE', undef, undef, 1],
		DEFAULT => [ $self ],
	);
}

=item B<calculateHeight>

For you to overwrite.
Returns the requested height of the B<Polevel>.

=cut

sub calculateHeight {
	return $_[0]->reqheight;
}

=item B<calculateWidth>

For you to overwrite.
Returns the requested width of the B<Polevel>.

=cut

sub calculateWidth {
	return $_[0]->reqwidth;
}

sub ConfigureSizeAndPos {
	my $self = shift;

	my $widget = $self->widget;
	my $screenheight = $self->vrootheight;
	my $screenwidth = $self->vrootwidth;
	my $height = $self->calculateHeight;
	my $confine = $self->cget('-confine');
	my $width;
	if ($confine) {
		$width = $widget->width;
	} else {
		$width = $self->calculateWidth;
	}
	my $x = $widget->rootx;
	unless ($confine) {
		if ($x + $width > $screenwidth) {
			$x = $x - ($width - $widget->width);
		}
	}
	my $origy = $widget->rooty;
	my $y;

	if ($origy + $height + $widget->height > $screenheight) {
		$self->{POPDIRECTION} = 'up';
		$y = $origy - $height;
	} else {
		$self->{POPDIRECTION} = 'down';
		$y = $origy + $widget->height;
	}
	$self->geometry(sprintf('%dx%d+%d+%d', $width, $height, $x, $y));
}

=item B<popDirection>

Returns the direction of the popup. It is '' when not yet calculated. Can be 'up' or 'down'.

=cut

sub popDirection {
	return $_[0]->{POPDIRECTION}
}


=item B<popDown>

Hides the PopList.

=cut

sub popDown {
	my $self = shift;
	return unless $self->ismapped;
	$self->withdraw;
	$self->parent->grabRelease;
	if (ref $self->{'_BE_grabinfo'} eq 'CODE') {
		$self->{'_BE_grabinfo'}->();
		delete $self->{'_BE_grabinfo'};
	}
}

=item B<popFlip>

Hides the PopList if it shown. Shows the PopList if it is hidden.

=cut

sub popFlip {
	my $self = shift;
	if ($self->ismapped) {
		$self->popDown
	} else {
		$self->popUp
	}
}

=item B<popUp>

Shows the PopList.

=cut

sub popUp {
	my $self = shift;

	return if $self->ismapped;

	$self->ConfigureSizeAndPos;
	$self->deiconify;
	$self->raise;
	$self->{'_BE_grabinfo'} = $self->grabSave;
	$self->parent->grabGlobal;
}

sub widget {
	return $_[0]->{WIDGET}
}

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

=over 4

=item Hans Jeuken (hanje at cpan dot org)

=back

=cut

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk>

=item L<Tk::Toplevel>

=item L<Tk::Listbox>

=back

=cut

1;
__END__

