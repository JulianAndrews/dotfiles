use strict;
use Irssi;
use vars qw($VERSION %IRSSI);
 
$VERSION = "1.0";
%IRSSI = (
  authors     => 'Julian Andrews',
  contact     => 'jandrews271@gmail.com',
  name        => 'notify',
  description => 'Simple `notify-send` based message notifications',
  license     => 'GNU General Public License',
);
 
sub notify {
  my ($dest, $text, $stripped) = @_;
  my $level = $dest->{level};
  $stripped =~ /^\< ([^\>]+)\> (.*)/;

  my $summary = "$dest->{target}: $1";
  my $message = $2;
  my $urgency = $level & MSGLEVEL_HILIGHT ? 'critical' : 'normal';

  if( $dest->{server} &&
      !($level & MSGLEVEL_NO_ACT) &&
      ($level & (MSGLEVEL_PUBLIC | MSGLEVEL_MSGS | MSGLEVEL_HILIGHT))
  ) {
    system("notify-send", "$summary", "$message", "-u", "$urgency");
  }
}
 
Irssi::signal_add('print text', 'notify');