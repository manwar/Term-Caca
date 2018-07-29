package Term::Caca;
#ABSTRACT: perl interface for libcaca (Colour AsCii Art library)

use 5.20.0;
use strict;
use warnings;
no warnings qw/ uninitialized /;

use experimental qw/
    signatures
    postderef
/;

use parent qw/ Exporter /;

our $VERSION = '2.0_0';

use Carp;
use Const::Fast;
use List::MoreUtils qw/ uniq /;

use Term::Caca::Event::Key::Press;
use Term::Caca::Event::Key::Release;
use Term::Caca::Event::Mouse::Motion;
use Term::Caca::Event::Mouse::Button::Press;
use Term::Caca::Event::Mouse::Button::Release;
use Term::Caca::Event::Resize;
use Term::Caca::Event::Quit;

use Moo;


our @EXPORT_OK;
our %EXPORT_TAGS;

const our %COLORS => (
  BLACK              => 0,
  BLUE               => 1,
  GREEN              => 2,
  CYAN               => 3,
  RED                => 4,
  MAGENTA            => 5,
  BROWN              => 6,
  LIGHTGRAY          => 7,
  DARKGRAY           => 8,
  LIGHTBLUE          => 9,
  LIGHTGREEN         => 10,
  LIGHTCYAN          => 11,
  LIGHTRED           => 12,
  LIGHTMAGENTA       => 13,
  YELLOW             => 14,
  WHITE              => 15,
  DEFAULT            => 16,
  TRANSPARENT        => 32,
);

const our $BLACK              => 0;
const our $BLUE               => 1;
const our $GREEN              => 2;
const our $CYAN               => 3;
const our $RED                => 4;
const our $MAGENTA            => 5;
const our $BROWN              => 6;
const our $LIGHTGRAY          => 7;
const our $DARKGRAY           => 8;
const our $LIGHTBLUE          => 9;
const our $LIGHTGREEN         => 10;
const our $LIGHTCYAN          => 11;
const our $LIGHTRED           => 12;
const our $LIGHTMAGENTA       => 13;
const our $YELLOW             => 14;
const our $WHITE              => 15;
const our $DEFAULT            => 16;
const our $TRANSPARENT        => 32;

$EXPORT_TAGS{colors} = [ map { '$'.$_ } keys %COLORS ];
push @EXPORT_OK, '@COLORS', @{$EXPORT_TAGS{colors}};



const our %EVENTS => (
    NO_EVENT =>          0x0000,
    KEY_PRESS =>     0x0001,
    KEY_RELEASE =>   0x0002,
    MOUSE_PRESS =>   0x0004,
    MOUSE_RELEASE => 0x0008,
    MOUSE_MOTION =>  0x0010,
    RESIZE =>        0x0020,
    QUIT =>          0x0040,
    ANY_EVENT =>           0xffff,
);

const our $NO_EVENT =>          0x0000;
const our $KEY_PRESS =>     0x0001;
const our $KEY_RELEASE =>   0x0002;
const our $MOUSE_PRESS =>   0x0004;
const our $MOUSE_RELEASE => 0x0008;
const our $MOUSE_MOTION =>  0x0010;
const our $RESIZE =>        0x0020;
const our $QUIT =>          0x0040;
const our $ANY_EVENT =>           0xffff;

$EXPORT_TAGS{events} = [ map { '$'.$_ } keys %EVENTS ];
push @EXPORT_OK, '@EVENTS', @{$EXPORT_TAGS{events}};

push @{$EXPORT_TAGS{all}}, uniq map { @$_ } values %EXPORT_TAGS;


sub driver_list {
    return @{ _caca_get_display_driver_list() };
}


sub drivers {
    my %list = @{ _caca_get_display_driver_list() };
    return keys %list;
}


sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  my %arg = @_;

  $self->{display} = $arg{driver} 
                        ? _create_display_with_driver($arg{driver}) 
                        : _create_display();

  croak "couldn't create display" unless $self->{display};

  $self->{canvas}  = _get_canvas($self->{display});

  return $self;
}

sub display($self) {
    return $self->{display};
}

sub canvas($self) {
    return $self->{canvas};
}


sub set_title ( $self, $title ) {
  _set_display_title($self->display, $title);

  return $self;
}


sub refresh($self) {
  _refresh($self->display);
  return $self;
}


sub set_refresh_delay ( $self, $seconds ) {
  _set_delay($self->display,int( $seconds * 1_000_000 ));
  return $self;
}


sub rendering_time($self) {
  return _get_delay($self->display)/1_000_000;
}


sub clear ($self) {
  _clear($self->canvas);
  return $self;
}


sub canvas_size($self) {
    my @d = ( $self->canvas_width, $self->canvas_height );

    return wantarray ? @d : \@d;
}


sub canvas_width($self) {
  return _get_width($self->canvas);
}


sub canvas_height($self) {
  return _get_height($self->canvas);
}



sub mouse_position($self) {
    my @pos = ( _get_mouse_x( $self->display ), _get_mouse_y( $self->display ) );
    return wantarray ? @pos : \@pos;
}

#
sub get_mouse_x {
# my ($self) = @_;
  return _get_mouse_x();
}

#
sub get_mouse_y {
# my ($self) = @_;
  return _get_mouse_y();
}


# TODO: troff seems to trigger a segfault
my @export_formats = qw/ caca ansi text html html3 irc ps svg tga /;


sub export( $self, $format = 'caca' ) {

    croak "format '$format' not supported" unless $format ~~ @export_formats;

    my $export = _export( $self->canvas, $format eq 'text' ? 'ansi' : $format );

    $export =~ s/\e\[?.*?[\@-~]//g if $format eq 'text';
    
    return $export;
}




sub set_ansi_color( $self, $foreground, $background ) {
    _set_ansi_color( $self->canvas, $foreground, $background );

    return $self;
}


sub set_color( $self, $foreground, $background ) {
    if ( exists $COLORS{uc $foreground} ) {
        return $self->set_ansi_color( 
            map { $COLORS{uc $_} } $foreground, $background 
        );
    }

    _set_color( $self->canvas, map { _arg_to_color( $_ ) } $foreground, $background );

    return $self;
}

sub _arg_to_color {
    my $arg = shift;

    return hex $arg unless ref $arg;

    return hex sprintf "%x%x%x%x", @$arg;
}


sub get_feature {
  my ($self, $feature) = @_;
  $feature ||= 0;
  return _get_feature($feature);
}

#
sub set_feature {
  my ($self, $feature) = @_;
  $feature ||= 0;
  _get_feature($feature);
}

#
sub get_feature_name {
  my ($self, $feature) = @_;
  $feature ||= 0;
  return _get_feature_name($feature);
}

sub DESTROY {
    my $self = shift;
  _free_display( $self->{display} ) if $self->{display};
}


sub text ( $self, $coord, $text ) {
    length $text > 1 
        ? _putstr( $self->canvas, @$coord, $text )
        : _putchar( $self->canvas, @$coord, $text );        

    return $self;
}


sub char ( $self, $coord, $char ) {
    _putchar( $self->canvas, @$coord, substr $char, 0, 1 );

    return $self;
}


sub line ( $self, $pa, $pb, $char = undef ) {
    defined ( $char ) 
    ?  _draw_line($self->canvas, @$pa, @$pb, $char)
    : _draw_thin_line($self->canvas,  @$pa, @$pb );

    return $self;
}


sub polyline( $self, $points, $char = undef, $close = 0 ) {
    my @x = map { $_->[0] } @$points;
    my @y = map { $_->[1] } @$points;
    my $n = @x - !$close;

    $char ? _draw_polyline( $self->canvas, \@x, \@y, $n, $char )
          : _draw_thin_polyline( $self->canvas, \@x, \@y, $n );

    return $self;
}


sub circle ( $self, $center, $radius, $char = undef, $fill = undef ) {
    $char //= $fill;

    my @args = ( $self->canvas, @$center, $radius );

    if ( not defined $char ) {
        _draw_thin_ellipse( @args, $radius );
    }
    else {
        if ( defined $fill ) {
            _fill_ellipse( @args, $radius, $char );
        }
        else {
            _draw_circle( @args, $char );
        }
    }

  return $self;
}


sub ellipse ( $self, $center, $rx, $ry, $char = undef, $fill = undef ) {
    $char //= $fill;

    if ( defined $fill ) {
        _fill_ellipse($self->canvas,@$center,$rx,$ry,$char);
    }
    elsif( defined $char ) {
        _draw_ellipse($self->canvas,@$center,$rx,$ry,$char);
    }
    else {
        _draw_thin_ellipse($self->canvas,@$center,$rx,$ry);
    }

  return $self;
}



sub box  ( $self, $center, $width, $height, $char = undef, $fill = undef ){
  $char //= $fill;

  my @args = ( $self->canvas, @$center, $width, $height );

  if ( defined $fill ) {
    _fill_box(@args, $char);
  }
  elsif( defined $char ) {
    _draw_box(@args, $char);
  }
  else {
    _draw_thin_box(@args);
  }

  return $self;
}


sub triangle  ( $self, $pa, $pb, $pc, $char = undef, $fill = undef ){
  $char //= $fill;

  my @args = ( $self->canvas, @$pa, @$pb, @$pc );

  if ( defined $fill ) {
    _fill_triangle(@args, $char);
  }
  elsif( defined $char ) {
    _draw_triangle(@args, $char);
  }
  else {
    _draw_thin_triangle(@args);
  }

  return $self;
}


sub wait_for_event ( $self, $mask = $ANY_EVENT, $timeout = 0 ) {
  my $event = _get_event( $self->display, $mask, int($timeout*1_000_000), defined wantarray )
      or return;

  given ( _get_event_type( $event ) ) {
    when ( $KEY_PRESS ) {
        return Term::Caca::Event::Key::Press->new( event => $event );
    }
    when ( $KEY_RELEASE ) {
        return Term::Caca::Event::Key::Release->new( event => $event );
    }
    when ( $MOUSE_MOTION ) {
        return Term::Caca::Event::Mouse::Motion->new( event => $event );
    }
    when ( $MOUSE_PRESS ) {
        return Term::Caca::Event::Mouse::Button::Press->new( event => $event );
    }
    when ( $MOUSE_RELEASE ) {
        return Term::Caca::Event::Mouse::Button::Release->new( event => $event );
    }
    when ( $RESIZE ) {
        return Term::Caca::Event::Resize->new( event => $event );
    }
    when ( $QUIT ) {
        return Term::Caca::Event::Quit->new( event => $event );
    }
    default {
        return;
    }
  }

}

'end of Term::Caca';

__END__


