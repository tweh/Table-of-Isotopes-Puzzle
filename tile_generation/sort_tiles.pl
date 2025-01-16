#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;
use File::Copy;
use File::Path qw(make_path);

# The directory where sorting should take place
my $base_dir = '../stl/tiles/c';
my $base_dir = '../stl/tiles/cd';

# Target folders and their respective patterns
my %folders = (
    'a/'        => qr/_a\.stl$/,
    'bm/'       => qr/_bm\.stl$/,
    'bp/'       => qr/_bp\.stl$/,
    'a-bm/'     => qr/_a-bm\.stl$/,
    'a-bp/'     => qr/_a-bp\.stl$/,
    'bm-bp/'    => qr/_bm-bp\.stl$/,
    'stable/'   => qr/_stable\.stl$/
);

# Check if the base directory exists
unless (-d $base_dir) {
    die "Base directory $base_dir does not exist.\n";
}

# List files in the base directory
opendir(my $dh, $base_dir) or die "Cannot open $base_dir: $!\n";
my @files = grep { -f "$base_dir/$_" } readdir($dh);
closedir($dh);

# Sort files
foreach my $file (@files) {
    foreach my $folder (keys %folders) {
        if ($file =~ $folders{$folder}) {
            my $target_dir = "$base_dir/$folder";

            # Create target folder if it does not exist
            unless (-d $target_dir) {
                print "Creating folder: $target_dir\n";
                make_path($target_dir) or die "Cannot create target folder $target_dir: $!\n";
            }

            # Replace '+' with '-' in file name
            (my $new_file = $file) =~ s/\+/-/g;

            # Move the file
            move("$base_dir/$file", "$target_dir/$new_file") or warn "Cannot move $file to $target_dir: $!\n";
            last;
        }
    }
}

print "Sorting completed.\n";
