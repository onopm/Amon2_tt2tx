#!/usr/bin/env perl
use strict;
use warnings;
use Pod::Usage;
use File::Copy;
use Path::Class;
use File::Path;
use File::Basename;

pod2usage() if scalar @ARGV;

my $bkup_dir = 'tt_org';
warn "backup-dir: $bkup_dir\n";
mkdir $bkup_dir if ! -d $bkup_dir;

tt_tx(
    root    => 'lib',
    #target  => qr{/Web\.pm$},     # - Amon2-3.66
    target  => qr{/Web/View\.pm$}, # Amon2-3.67-
    replace => [
    sub{ $_[0] =~ s/TTerse/Kolon/ },
    ],
);

tt_tx(
    root    => 'lib',
    target  => qr/\/Dispatcher\.pm$/,
    replace => [
    sub{ $_[0] =~ s/index\.tt/index.tx/ },
    ],
);

tmpl_tt_tx('tmpl');

exit;


sub tt_tx {
    my %args = @_;

    dir($args{root})->recurse(callback => sub{ 
            my $tt_file = shift; 
            return if $tt_file->is_dir;
            return if $tt_file !~ $args{target};

            warn "target: $tt_file\n";

            my $tt_path = $bkup_dir.'/'.$tt_file;
            warn "  copy     $tt_file ->  $tt_path\n";
            mkpath( dirname($tt_path), { verbose => 1 });
            copy $tt_file, $tt_path;

            my $tx_path = $tt_file;
            warn "  read     $tt_path\n";
            warn "  write    $tx_path\n";

            open my $tt_fh, "<", $tt_path or die "open error $tt_path. $!";
            open my $tx_fh, ">", $tx_path or die "open error $tx_path. $!";
            while(my $buf = <$tt_fh>){
                for my $replace (@{$args{replace}}){
                    $replace->($buf);
                }
                print $tx_fh $buf;
            }
            close $tt_fh;
            close $tx_fh;
        });
}

sub tmpl_tt_tx {
    my $dir = shift || 'tmpl';

    dir($dir)->recurse(callback => sub{
            my $tt_file = shift;
            return if $tt_file->is_dir;
            return if $tt_file !~ /\.tt$/;

            warn "target: $tt_file\n";
            my $tt_path = $bkup_dir.'/'.$tt_file;
            warn "  move     $tt_file ->  $tt_path\n";
            mkpath( dirname($tt_path), { verbose => 1 });
            #copy $tt_file, $tt_path;
            move $tt_file, $tt_path;

            (my $tx_path = $tt_file) =~ s/tt$/tx/;
            warn "  read     $tt_path\n";
            warn "  write    $tx_path\n";

            open my $tt_fh, "<", $tt_path or die "open error $tt_path. $!";
            open my $tx_fh, ">", $tx_path or die "open error $tx_path. $!";

            while(my $buf = <$tt_fh>){
                $buf =~ s/\[% IF bodyID %]/<: if \$bodyID  { :>/ig;
                $buf =~ s/\[% bodyID %]/<: \$bodyID :>/ig;
                $buf =~ s/^\s?\[% END %]\s?$/: }/ig;
                $buf =~ s/\[% END %]/<: } :>/ig;

                $buf =~ s/\[% WRAPPER 'include\/layout.tt' %]/: cascade 'include\/layout.tx'\n: around body -> {/ig;
                $buf =~ s/\[% content %]/: block body -> {}/ig;

                $buf =~ s/\[% title (.*) %]/<: \$title $1 :>/ig;

                $buf =~ s/\[% content %]/: block body -> {}/ig;

                $buf =~ s/\[%/<:/ig;
                $buf =~ s/%]/:>/ig;

                print $tx_fh $buf;
            }
            close $tt_fh;
            close $tx_fh;
        });
}

__END__

=head1 NAME

amon2-tt2tx.pl - change Xslate engine TTerse to Kolon after amon2-setup.pl

=head1 SYNOPSIS

    % amon2-setup.pl MyApp
    % amon2-tt_tx.pl

=head1 DESCRIPTION

amon2-steup.pl is created TTerse format.

this script change to Kolon format.

=head1 SUPPORTS

https://github.com/onopm/Amon2_tt2tx

=head1 AUTHOR

Takafumi Ono

=cut
