#!/usr/bin/env perl
use strict;
use warnings;
use Pod::Usage;
use Path::Class;

pod2usage() if scalar @ARGV;

tt_tx(
    root    => 'lib',
    target  => qr/\/Web\.pm$/,
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
            my $entry = shift; 
            return if $entry->is_dir;
            return if $entry !~ $args{target};
            warn "read    $entry\n";
            my $path_tx = $entry;
            $path_tx.= '.tx';
            open my $tt_fh, "<", $entry   or die "open error $entry. $!";
            open my $tx_fh, ">", $path_tx or die "open error $path_tx. $!";
            while(my $buf = <$tt_fh>){
                for my $replace (@{$args{replace}}){
                    $replace->($buf);
                }
                print $tx_fh $buf;
            }
            close $tt_fh;
            close $tx_fh;
            
            rename $entry, $entry.'.tt';
            rename $path_tx, $entry;

            warn "written $path_tx\n";
            warn "rename $entry ${entry}.tt\n";
            warn "rename ${entry}.tx $entry\n";
        });
}

sub tmpl_tt_tx {
    my $dir = shift || 'tmpl';

    dir($dir)->recurse(callback => sub{
            my $entry = shift;
            return if $entry->is_dir;
            return if $entry !~ /\.tt$/;

            warn "read    $entry\n";
            my $path_tx = $entry;
            $path_tx =~ s/tt$/tx/;
            open my $tt_fh, "<", $entry   or die "open error $entry. $!";
            open my $tx_fh, ">", $path_tx or die "open error $path_tx. $!";
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
            warn "written $path_tx\n";
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

=head1 AUTHOR

Takafumi Ono

=cut
