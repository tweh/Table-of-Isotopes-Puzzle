#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;
use File::Copy;
use File::Path qw(make_path);

# Directories where sorting should take place
my @base_dirs = (
    '../stl/tiles/p',
    '../stl/tiles/pd'
);

# Target folders and their respective patterns
my %folders = (
    'active/'   => qr/_(a|bm|bp|a-bm|a-bp|bm-bp)\.stl$/,
    'stable/'   => qr/_stable\.stl$/
);

# Loop over all base directories
foreach my $base_dir (@base_dirs) {

    # Check if the base directory exists
    unless (-d $base_dir) {
        warn "Base directory $base_dir does not exist. Skipping...\n";
        next;
    }

    # List files in the base directory
    opendir(my $dh, $base_dir) or do {
        warn "Cannot open $base_dir: $!\n";
        next;
    };
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
                move("$base_dir/$file", "$target_dir/$new_file")
                    or warn "Cannot move $file to $target_dir: $!\n";
                last;
            }
        }
    }

    print "Sorting completed for $base_dir.\n";
}

print "All sorting completed.\n";
