package Tk::PopList;

=head1 NAME

Tk::PopList - Popping a selection list relative to a widget

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.01';

use base qw(Tk::Derived Tk::Toplevel);

use Tk;
use Tie::Watch;

Construct Tk::Widget 'PopList';

=head1 SYNOPSIS

 require Tk::PopList;
 my $list = $window->PopList(@options,
    -values => [qw/value1 value2 value3 value4/],
    -widget => $somewidget,
 );
 $list->popUp;

=head1 DESCRIPTION

This widget pops a listbox relative to the widget specified in the B<-widget> option.
It aligns its size and position to the widget.

You can specify B<-selectcall> to do something when you select an item. It gets the selected
item as parameter.

You can use the escape key to hide the list.
You can use the return key to select an item.

=head1 OPTIONS

=over 4

=item B<-filter>

Default value 0

Specifies if a filter entry is added. Practical for a long list of values.

=item B<-motionselect>

Default value 1

When set hoovering over a list item selects it.

=item B<-selectcall>

Callback, called when a list item is selected.

=item B<-values>

List of possible values.

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
	
	my $motionselect = delete $args->{'-motionselect'};
	$motionselect = 1 unless defined $motionselect;

	my $widget = delete $args->{'-widget'};
	die 'You need to set the -widget option' unless defined $widget;

	$self->SUPER::Populate($args);

	$self->{FE} = undef;
	$self->{LIST} = [];
	$self->{POPDIRECTION} = '';
	$self->{VALUES} = [];
	$self->{WIDGET} = $widget;
	
	$self->overrideredirect(1);
	$self->withdraw;

	my $listbox = $self->Scrolled('Listbox',
		-borderwidth => 1,
		-relief => 'sunken',
		-scrollbars => 'oe',
		-listvariable => $self->{LIST},
	)->pack(-fill => 'both');
	$self->Advertise('Listbox', $listbox);
	$listbox->bind('<Return>', [$self, 'Select']);
	$listbox->bind('<ButtonRelease-1>', [$self, 'Select', Ev('x'), Ev('y')]);
	$listbox->bind('<Escape>', [$self, 'popDown']);
	$self->bind('<Motion>', [$self, 'MotionSelect', Ev('x'), Ev('y')]) if $motionselect;
	$self->parent->bind('<Button-1>', [$self, 'popDown']);

	$self->ConfigSpecs(
		-filter => ['PASSIVE', undef, undef, 0],
		-selectcall => ['CALLBACK', undef, undef, sub {}],
		'-values' => ['METHOD', undef, undef, []],
		DEFAULT => [ $listbox ],
	);
}

sub ConfigureSizeAndPos {
	my $self = shift;
	my $list = $self->{LIST};
	my $lb = $self->Subwidget('Listbox');
	my $widget = $self->{WIDGET};

	my $screenheight = $self->vrootheight;
	my $height = $lb->reqheight;
	$height = $height + $self->{FE}->reqheight if defined $self->{FE};
	my $width = $widget->width;

	my $lheight = 10;
	if (@$list < $lheight) { $lheight = @$list }
	$lb->configure(-height => $lheight);

	my $x = $widget->rootx;
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

=item B<filter>I<($filter)>

Filters the list of values on $filter.

=cut

sub filter {
	my ($self, $filter) = @_;
	my $values = $self->{VALUES};
	my @new = ();
	for (@$values) {
		push @new, $_ if $_ =~ /^$filter/i;
	}
	my $list = $self->{LIST};
	@$list = @new;
}

sub MotionSelect {
	my ($self, $x, $y) = @_;
	my $list = $self->Subwidget('Listbox');
	$list->selectionClear(0, 'end');
	$list->selectionSet('@' . "$x,$y");
}

=item B<popDown>

Hides the PopList.

=cut

sub popDown {
	my $self = shift;
	return unless $self->ismapped;
	my $e = $self->{FE};
	if (defined $e) {	
		$e->packForget;
		$e->destroy;
		$self->{FE} = undef;
	}
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

	my $values = $self->{VALUES};
	my $list = $self->{LIST};
	@$list = @$values;
	
	my $lb = $self->Subwidget('Listbox');
	my $widget = $self->{WIDGET};

	my $e;
	if ($self->cget('-filter')) {
		my $var = 'Filter';
		$e = $self->Entry(
			-textvariable => \$var,
		);
		$e->bind('<FocusIn>', sub { $var = '' });
		$e->bind('<Escape>', [$self, 'popDown']);
		Tie::Watch->new(
			-variable => \$var,
			-store => sub {
				my ($watch, $value) = @_;
				$watch->Store($value);
				$self->filter($value);
			},
		);
		$self->{FE} = $e;
	}

	$self->ConfigureSizeAndPos;

	my @filterpack = ();
	if ($self->{POPDIRECTION} eq 'up') {
		@filterpack = (-after => $lb);
	} elsif ($self->{POPDIRECTION} eq 'down') {
		@filterpack = (-before => $lb);
	}
	$e->pack(@filterpack,
		-fill => 'x'
	) if defined $e;

	$lb->selectionClear(0, 'end');
	$lb->selectionSet('@0,0');
	$self->deiconify;
	$self->raise;
	$lb->focus;
	$self->{'_BE_grabinfo'} = $self->grabSave;
	$self->parent->grabGlobal;
}

sub Select {
	my ($self, $x, $y) = @_;

	my $list = $self->Subwidget('Listbox');

	my $item = $list->get($list->curselection);
	$self->Callback('-selectcall', $item);
	$self->popDown;
}

sub values {
	my ($self, $new) = @_;
	$self->{VALUES} = $new if defined $new;
	return $self->{VALUES}
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

