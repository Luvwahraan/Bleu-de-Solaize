package LeekWars;
our $VERSION = 0.1;

use Storable qw(store retrieve);
use LWP::UserAgent;
use HTTP::Cookies;
use JSON::Parse 'parse_json';

sub new {
  my $class = shift;
  my $self = {};
  bless($class, $self);

  $self->{'_storableData'} = qw/password cookie_file/;

  $self->{'user'} = $_[0]{'user'} || return -1;
  $self->{'config'} = $_[0]{'config'} || $ENV{'HOME'}."/.config/LeekWars.BdS";

  if ( -d $self->{'config'} ) {
    load($self);
  } else {
    mkdir( $self->{'config'} );
  }

  # On définie (ou pas) les données qui n’ont pas été retrouvées.
  foreach my $data( @{$self->{'_storableData'}} ) {
    unless ( defined $self->{$data} ) {
      $self->{$data} = $_[0]{$data} || undef;
    }
  }

  # Ne peut pas être indéfinie.
  $self->{'cookie_file'} = $self->{'cookie_file'} || "$self->{config}/$self->{user}.cookie";

  $self->{'cookie'}   = $_[0]{'cookie'}   || HTTP::Cookies->new(
      file => $self->{'cookie_file'}, autosave  => 1, ignore_discard => 0
    );
  $self->{'browser'}  = LWP::UserAgent->new(
      'agent' => "Bleu de Solaize $VERSION ($^O)", cookie_jar => $self->{'cookie'},
    );

  return $self;
}

sub save {
  my $self = shift;

  # On ne sauvegarde que ce qui est nécessaire.
  my $config = {};
  foreach my $confKey( @{$self->{'_storableData'}} ) {
    if ( defined $self->{$confKey} ) {
      $confKey->{$confKey} = $self->{$confKey};
    }
  }

  unless ( store( $config, "$self->{config}/config.$self->{user}.pl" ) ) {
    print STDERR "Impossible d’écrire les données : $!\n";
    return 0;
  }
  return 1;
}

sub load {
  my $self = shift;
  my $configFile = "$self->{config}/config.$self->{user}.pl";

  if ( -f $configFile ) {
    my $hashref = retrieve( $configFile );
    foreach my $confKey( @{$self->{'_storableData'}} ) {
      if ( defined $hashref->{$confKey} ) {
        $self->{$confKey} = $hashref->{$confKey};
      }
    }
    return 1;
  }
  return 0;
}

1;
