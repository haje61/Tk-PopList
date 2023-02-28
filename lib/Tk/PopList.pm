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
 my $list= $window->PopList(@options,
    -values => [qw/value1 value2 value3 value4/],
    -widget => $somewidget,
 );
 $list->popUp;

=head1 DESCRIPTION

=head1 OPTIONS

=over 4

=item B<-filter>

Default value 0

Specifies if a filter entry should be added. Practical for a long list of values.

=item B<-motionselect>

Default value 1

When set hoovering over a list item selects it.

=item B<-selectcall>

Callback, called when a list item is selected.

=item B<-values>

Mandatory!

List of possible values.

Only available at create time.

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

	my $values = delete $args->{'-values'};
	die "You need to set the -values option" unless defined $values;

	my $widget = delete $args->{'-widget'};
	die 'You need to set the -widget option' unless defined $widget;

	$self->SUPER::Populate($args);

	$self->{FE} = undef;
	$self->{LIST} = [];
	$self->{VALUES} = $values;
	$self->{WIDGET} = $widget;
	
	$self->overrideredirect(1);
	$self->withdraw;

	my $height = 10;
	if (@$values < $height) { $height = @$values }
	my $listbox = $self->Scrolled('Listbox',
		-borderwidth => 1,
# 		-height => $height,
		-relief => 'sunken',
		-scrollbars => 'oe',
		-listvariable => $self->{LIST},
	)->pack(-fill => 'both');
	$self->Advertise('Listbox', $listbox);
	$listbox->bind('<Return>', [$self, 'Select']);
	$listbox->bind('<ButtonRelease-1>', [$self, 'Select', Ev('x'), Ev('y')]);
	$listbox->bind('<Escape>', [$self, 'popDown']);
	$self->bind('<Motion>', [$self, 'MotionSelect', Ev('x'), Ev('y')]) if $motionselect;

	$self->ConfigSpecs(
		-filter => ['PASSIVE', undef, undef, 0],
		-selectcall => ['CALLBACK', undef, undef, sub {}],
		DEFAULT => [ $listbox ],
	);
}

=item B<filter>I<($filter)>

Filters the list of values on $filter.

=cut

sub filter {
	my ($self, $filter) = @_;
	my $values = $self->{VALUES};
	my @new = ();
	for (@$values) {
		push @new, $_ if $_ =~ /^$filter/;
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
	}
	$self->withdraw;
	$self->grabRelease;
	if (ref $self->{'_BE_grabinfo'} eq 'CODE') {
		$self->{'_BE_grabinfo'}->();
		delete $self->{'_BE_grabinfo'};
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

	my $screenheight = $self->vrootheight;
	my $height = $lb->reqheight;
	my $width = $widget->width;
	
	my $x = $widget->rootx;
	my $origy = $widget->rooty;

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

		$height = $height + $e->reqheight;
		$self->{FE} = $e;
	}

	
	my $y;
	my @filterpack = ();
	if ($origy + $height + $widget->height > $screenheight) {
		$y = $origy - $height;
		@filterpack = (-after => $lb);
	} else {
		$y = $origy + $widget->height;
		@filterpack = (-before => $lb);
	}

	$e->pack(@filterpack,
		-fill => 'x'
	) if defined $e;

	$self->geometry(sprintf('%dx%d+%d+%d', $width, $height, $x, $y));
	$lb->selectionClear(0, 'end');
	$self->deiconify;
	$self->raise;
	$lb->focus;
	$self->{'_BE_grabinfo'} = $self->grabSave;
	$self->grabGlobal;
}

sub Select {
	my ($self, $x, $y) = @_;

	my $list = $self->Subwidget('Listbox');

	my $item = $list->get($list->curselection);
	$self->Callback('-selectcall', $item);
	$self->popDown;
}

=back

=head1 AUTHOR

=over 4

=item Hans Jeuken (hanje at cpan dot org)

=back

=cut

=head1 BUGS

Unknown. If you find any, please contact the author.

=cut

=head1 TODO

=over 4


=back

=cut

=head1 SEE ALSO

=over 4


=back

=cut

1;
__END__

