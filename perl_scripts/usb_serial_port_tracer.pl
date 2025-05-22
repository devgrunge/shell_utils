#!/usr/bin/perl -w

use strict;
use Getopt::Long qw(GetOptions);
use IO::Handle;

our $VERSION = "0.83";

sub usage {
  print <<HELP;
    There are three modes:

    1) ttylog tty

    DIRECT (tty): Show terminal output for a given tty to stdout. This means
    that you will see whatever the user sees.

    2) ttylog -t tty  [ -w file ]

    WRITE (-t tty): Attach to a tty and log the I/O to a trace file for
    future analysis.

    3) ttylog -r file [ -b file ] [ -i file ] [ -o file ]

    READ (-r file): Analyze a trace file for key strokes or for terminal
    output or for bandwidth usage.

    OPTIONS:

      --tty tty
        Specify which psuedo terminal to use
        Example: --tty pts/1
      --write file
        Save the packet data to a file for later analysis
        Example: --write trace.log
      --read file
        Read from a saved packet file
        Example: --read trace.log
      --bandwidth file
        Log network bandwidth used to a file
        Example: --bandwidth ssh.bytes_log
      --input file
        Log keystrokes sent to terminal to a file
        Example: --input keyboard.log
      --output file
        Log terminal output to a file
        Example: --output terminal.log
      --help
        Show this usage message.

    Note that all options may be abbreviated, i.e., "-h" is the same as "--help".

HELP
  exit;
}

if (@ARGV == 1) {
  # Assume it is just a tty to set to stdout
  exec($0,"-w","|$0 -r - -o -","-t",@ARGV) or die "exec error: $!";
}

usage() if !@ARGV;

my $tty = undef;
my $write = undef;
my $read = undef;
my $bandwidth = undef;
my $input = undef;
my $output = undef;
my $help = undef;

my $good = GetOptions
  "tty:s" => \$tty,
  "write:s" => \$write,
  "read:s" => \$read,
  "bandwidth:s" => \$bandwidth,
  "input:s" => \$input,
  "output:s" => \$output,
  help => \$help,
  ;

usage() if $help || @ARGV;
if ($read and !$bandwidth && !$input && !$output) {
  # Default output to stdout if no action specified
  $output = "-";
}
if ($good) {
  if ($read && $write) {
    warn "Cannot specify both --read and --write options\n";
    $good = 0;
  } elsif ($read && $tty) {
    warn "Cannot specify both --read and --tty options\n";
    $good = 0;
  } elsif (!$read && !$tty) {
    warn "Must specify either --read or --tty option\n";
    $good = 0;
  }
}
unless ($good) { sleep 2; usage(); }

if ($tty) {
  # This is write mode
  # Need to attach to tty
  if ($tty !~ m%^(pts/\d+|ttyVIZ\d+)$%) {
  warn "Unrecognized pseudo terminal [$tty]\n";
  exit;
}
  if (!$write) {
    # No write file specified
    # Generate a random one
    $write = (getpwuid $<)[7];
    $write .= "/";
    my @r = ("A".."Z");
    for (my $i = 0 ; $i < 32 ; $i++) {
      $write .= $r[rand @r];
    }
    $write .= ".trace";
    warn "DEBUG: Auto-generated write file [$write]\n";
  }
  warn "DEBUG: Scanning for psuedo terminal $tty\n";
  if (-e "/dev/$tty") {
    warn "DEBUG: Psuedo terminal [$tty] found.\n";
    my $ps = `ps fauwwx`;
    # Use lsof to find which PID has the tty open
    my $lsof = `lsof /dev/$tty 2>/dev/null | grep -v COMMAND | head -n 1`;
    if ($lsof =~ /^\S+\s+(\d+)/) {
    my $pid = $1;
    warn "DEBUG: Found process [$pid] using /dev/$tty\n";
    exec "strace", "-e", "read,write", "-s16384", "-x", "-o", $write, "-p", $pid
    or die "exec: $!";
  } else {
    die "Unable to find any process using /dev/$tty\n";
  }

  } else {
    die "Psuedo terminal [$tty] currently does NOT exist.\n";
  }
}

# This is read mode
# Need to scan the trace file and perform the desired logging

$| = 1;
my $fd_bandwidth = undef;
my $fd_keyboard = undef;
my $fd_terminal = undef;
if (open TRACE, $read) {
  my $fds = {};
  while (<TRACE>) {
    #warn "DEBUG: Scanning for I/O fds ...\n";
    if (/(read|write)\((\d+), "(.*)"/) {
      #warn "DEBUG: Found fd [$2]\n";
      $fds->{$2} = $1;
      if (3 <= scalar keys %{ $fds }) {
        ($fd_bandwidth, $fd_keyboard, $fd_terminal) = sort keys %{ $fds };
        last;
      }
    } else {
      warn "DEBUG: Unrecognized trace line: $_";
    }
    #warn "DEBUG: SETTINGS: b[$fd_bandwidth] k[$fd_keyboard] t[$fd_terminal] ...\n";
  }
} else {
  die "$read: Could not open for reading: $!\n";
}

my $buffer_bytes = 0;
my $buffer_since = time();
if ($output) {
  my $pid = fork;
  if (defined $pid) {
    if ($pid) {
      waitpid($pid, 0);
    } else {
      open STDOUT, ">>$output";
      exec("clear") or die "exec: $!";
    }
  }
}

while (<TRACE>) {
  if ($input && /write\($fd_keyboard, "(.*)"/) {
    my $s = $1;
    $s =~ s/\\\\/\\/g;
    $s =~ s/\\r/[ENTER]\n/g;
    $s =~ s/\\n/^J/g;
    $s =~ s/\\x1b\\x5b\\x41/[UP]/g;
    $s =~ s/\\x1b\\x5b\\x42/[DOWN]/g;
    $s =~ s/\\x1b\\x5b\\x43/[RIGHT]/g;
    $s =~ s/\\x1b\\x5b\\x44/[LEFT]/g;
    $s =~ s/\\x(0[1-9a-f]|1[0-9a])/sprintf "^%c", (64+hex $1)/eg;
    if (open KEYS, ">>$input") {
      KEYS->autoflush(1);
      print KEYS $s;
      close KEYS;
    }
  }
  if ($output && /read\($fd_terminal, "(.*)"/) {
    my $s = $1;
    $s =~ s/\\x(..)/chr hex $1/eg;
    $s =~ s/\\t/\t/g;
    $s =~ s/\\r/\r/g;
    $s =~ s/\\n/\n/g;
    $s =~ s/\\\\/\\/g;
    if (open OUT, ">>$output") {
      OUT->autoflush(1);
      print OUT $s;
      close OUT;
    }
  }
  if ($bandwidth && /(read|write)\($fd_bandwidth,.*= (\d+)$/) {
    my $direction = $1;
    my $bytes = $2;
    $buffer_bytes += $bytes;
    if (time - $buffer_since > 5) {
      $buffer_since = time;
      if (open BYTES, ">>$bandwidth") {
        BYTES->autoflush(1);
        print BYTES time()," $buffer_bytes .\n";
        close BYTES;
        $buffer_bytes = 0;
      }
    }
  }
}

if ($bandwidth && $buffer_bytes) {
  if (open BYTES, ">>$bandwidth") {
    BYTES->autoflush(1);
    print BYTES time()," $buffer_bytes .\n";
    close BYTES;
  }
}
warn "\nTTY EOF\n";

=pod

=head1 NAME

ttylog - Log tty sessions

=head1 SYNOPSIS

  ttylog tty
    or
  ttylog -t tty  [ -w file ]
    or
  ttylog -r file [ -b file ] [ -i file ] [ -o file ]

=head1 EXAMPLE

Type "w" to obtain the desired tty:

  [root@host root]# w
    9:01am  up 81 days, 16:06,  5 users,  load average: 0.00, 0.00, 0.00
  USER     TTY      FROM              LOGIN@   IDLE   JCPU   PCPU  WHAT
  root     pts/0    admin.com         8:19am  0.00s  0.39s  0.05s  w
  joe      pts/1    workstation.wi    8:02am 39:33   2.63s  2.19s  pine
  hacker   pts/4    client.isp.com    8:45am  5.00s 27.95s  1.45s  vim devil.cfg
  [root@host root]#

Then connect to monitor what is being typed or what is seen through the tty:

  [root@host root]# ttylog pts/4

=head1 OPTIONS

There are three modes:

DIRECT (tty): Show terminal output for a given tty to stdout.
This means that you will see whatever the user sees.

WRITE (-t tty): Attach to a tty and log the I/O to a trace
file for future analysis.

READ (-r file): Analyze a trace file for key strokes or for
terminal output or for bandwidth usage.

  --tty tty
    Specify which psuedo terminal to use
    Example: --tty pts/1
  --write file
    Save the packet data to a file for later analysis
    Example: --write trace.log
  --read file
    Read from a saved packet file
    Example: --read trace.log
  --bandwidth file
    Log network bandwidth used to a file
    Example: --bandwidth ssh.bytes_log
  --input file
    Log keystrokes sent to terminal to a file
    Example: --input keyboard.log
  --output file
    Log terminal output to a file
    Example: --output terminal.log
  --help
    Show this usage message.

Note that all options may be abbreviated, i.e., "-h" is the same as "--help".

=head1 DESCRIPTION

This utility is intended for attaching to currently running tty sessions
for the purposes of administration, shell assisting, bandwidth tracking,
and logging for debugging or training.  Unlike other tty sniffers, this
utility does not require any patches to the kernel or any system
configuration modifications or tweaking.  You can even install it AFTER
someone has logged in and connect on the fly to instantly view their
session which has already been currently running for a long time.

=head1 DISCLAIMER

Please be sensitive to the privacy of others!  The author will not be
held liable for any violation of privacy or damage that may be caused
by unauthorized use of this utility.  It is left to the discretion of
the user of this application to deem what is appropriate.

=head1 REQUIREMENTS

This utility has been designed and is only known with work under the
Linux platform, specifically the RedHat flavor, but possibly others.
It requires that the strace utility be installed within the PATH.
It assumes the tty sessions to be logged have been created from the sshd server.
It does not work for terminal logins directly from the console.
You must be the root user for permissions to use this program effectively.
It is recommended that you have a very large screen and maximize your
client because you will be seeing the terminal in the same dimensions
as the tty of the user you are connecting to and you might not be able
to see everything if your screen is constantly wrapping.
The user must type at least one character to begin monitoring.
Also, it is not recommended to log your own tty session as it may
cause an infinite loop.  If you really need to log your session, just
send it to a trace file (using -w) and analyze it later (using -r) after
your session is finished.

=head1 AUTHOR

  Rob Brown rob@asquad.com
  A-Squad.Com

=head1 COPYRIGHT

  Copyright 2004-2005
  All rights reserved
  Artistic License

=head1 SEE ALSO

w(1)
strace(1)

=head1 VERSION

$Id: ttylog,v 1.12 2005/03/17 21:13:11 rob Exp $

=cut