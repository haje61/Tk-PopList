package Tk::PopList;

=head1 NAME

Tk::PopList - Popping a selection list relative to a widget

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.09';

use base qw(Tk::Derived Tk::Poplevel);

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

Inherits L<Tk::Poplevel>

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

=back

=head1 KEYBINDINGS

=over 4

 <Down>       Moves selection to the next item in the list.
 <End>        Moves selection to the last item in the list.
 <Escape>     Hides the poplist.
 <Home>       Moves selection to the first item in the list.
 <Return>     Selects the current selection and hides the poplist.
 <Up>         Moves selection to the previous item in the list.

=back

=cut

=head1 METHODS

=over 4

=cut

sub Populate {
	my ($self,$args) = @_;
	
	my $motionselect = delete $args->{'-motionselect'};
	$motionselect = 1 unless defined $motionselect;

	$self->SUPER::Populate($args);

	$self->{FE} = undef;
	$self->{LIST} = [];
	$self->{VALUES} = [];
	
	my $listbox = $self->Scrolled('Listbox',
		-selectmode => 'single',
		-scrollbars => 'oe',
		-listvariable => $self->{LIST},
		-xscrollcommand => sub {},
	)->pack(-expand => 1, -fill => 'both');
	$self->Advertise('Listbox', $listbox);
	$listbox->bind('<ButtonRelease-1>', [$self, 'Select']);
	$listbox->bind('<Down>', [$self, 'NavDown']);
	$listbox->bind('<Escape>', [$self, 'popDown']);
	$listbox->bind('<End>', [$self, 'NavLast']);
	$listbox->bind('<Home>', [$self, 'NavFirst']);
	$listbox->bind('<Return>', [$self, 'Select']);
	$listbox->bind('<Up>', [$self, 'NavUp']);
	$listbox->bind('<Motion>', [$self, 'MotionSelect', Ev('x'), Ev('y')]) if $motionselect;

	$self->ConfigSpecs(
		-background => ['SELF', 'DESCENDATNS'],
		-filter => ['PASSIVE', undef, undef, 0],
		-maxheight => ['PASSIVE', undef, undef, 10],
		-selectcall => ['CALLBACK', undef, undef, sub {}],
		-values => ['METHOD', undef, undef, []],
		DEFAULT => [ $listbox ],
	);
}

sub calculateHeight {
	my $self = shift;
	my $list = $self->{LIST};
	my $lb = $self->Subwidget('Listbox');
	my $lheight = $self->cget('-maxheight');
	if (@$list < $lheight) { $lheight = @$list }
	my $font = $lb->cget('-font');

	my $fontheight = $lb->fontActual($font, '-size');
	$fontheight = $fontheight * -1 if $fontheight < 0;

	my $height = $lheight * $fontheight * 2;
	$height = $height + $self->{FE}->reqheight if defined $self->{FE};
	return $height
}

=item B<filter>I<($filter)>

Filters the list of values on $filter.

=cut

sub filter {
	my ($self, $filter) = @_;
	$filter = quotemeta($filter);
	my $values = $self->{VALUES};
	my @new = ();
	my $len = length($filter);
	for (@$values) {
		push @new, $_ if $_ =~ /$filter/i;
	}
	my $size = @new;
	my $list = $self->{LIST};
	#this is a hack. doing it the crude way somehow gives crashes
	while (@$list) { pop @$list }
	push @$list, @new;
}

sub MotionSelect {
	my ($self, $x, $y) = @_;
	my $list = $self->Subwidget('Listbox');
	$list->selectionClear(0, 'end');
	my $i = $list->index('@' . "$x,$y");
	$list->selectionSet($i);
	$list->selectionAnchor($i);
}

sub popDown {
	my $self = shift;
	return unless $self->ismapped;
	my $e = $self->{FE};
	if (defined $e) {	
		$e->packForget;
		$e->destroy;
		$self->{FE} = undef;
	}
	$self->SUPER::popDown;
}

sub NavDown {
	my $self = shift;
	my $l = $self->Subwidget('Listbox');
	my $val = $self->{VALUES};
	my ($sel) = $l->curselection;
	$sel ++;
	unless ($sel >= @$val) {
		$l->selectionClear(0, 'end');
		$l->selectionSet($sel);
		$l->selectionAnchor($sel);
		$l->see($sel);
	}
}

sub NavFirst {
	my $self = shift;
	my $l = $self->Subwidget('Listbox');
	$l->selectionClear(0, 'end');
	$l->selectionSet(0);
	$l->selectionAnchor(0);
	$l->see(0);
}

sub NavLast {
	my $self = shift;
	my $l = $self->Subwidget('Listbox');
	my $val = $self->{VALUES};
	my $last = $l->index('end') - 1;
	$l->selectionClear(0, 'end');
	$l->selectionSet($last);
	$l->selectionAnchor($last);
	$l->see($last);
}

sub NavUp {
	my $self = shift;
	my $l = $self->Subwidget('Listbox');
	my ($sel) = $l->curselection;
	$sel--;
	unless ($self < 0) { 
		$l->selectionClear(0, 'end');
		$l->selectionSet($sel);
		$l->selectionAnchor($sel);
		$l->see($sel);
	}
}

sub popUp {
	my $self = shift;

	return if $self->ismapped;

	my $values = $self->{VALUES};
	my $list = $self->{LIST};
	#this is a hack. doing it the crude way somehow gives crashes
	while (@$list) { pop @$list }
	push @$list, @$values;
	
	my $e;
	if ($self->cget('-filter')) {
		my $var = 'Filter';
		$e = $self->Entry(
			-textvariable => \$var,
		);
		$e->bind('<FocusIn>', sub { $var = '' });
		$e->bind('<Escape>', [$self, 'popDown']);
		$e->bind('<Key>', sub { $self->filter($e->get) });
		$self->{FE} = $e;
	}

#	$self->calculateHeight;
	$self->SUPER::popUp;

	my $lb = $self->Subwidget('Listbox');
	$lb->selectionClear(0, 'end');
	$lb->selectionSet('@0,0');
	$lb->focus;

	my @filterpack = ();
	my $direction = $self->popDirection;
	if ($direction eq 'up') {
		@filterpack = (-after => $lb);
	} elsif ($direction eq 'down') {
		@filterpack = (-before => $lb);
	}
	$e->pack(@filterpack,
		-fill => 'x'
	) if defined $e;
}

sub Select {
	my $self = shift;

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

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk>

=item L<Tk::Poplevel>

=item L<Tk::Toplevel>

=item L<Tk::Listbox>

=back

=cut

1;
__END__



