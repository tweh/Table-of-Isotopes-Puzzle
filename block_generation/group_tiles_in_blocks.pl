#!/usr/bin/perl
use strict;
use warnings;
use File::Path qw(make_path);
use Getopt::Long;
use File::Basename;

# ==========================
# parameters
# ==========================

## paths and files
my $csv_file = "../isotope_data/isotope_data.csv";
my $tiles_dir = "../../stl/tiles/p_for_blocks";
my $connector_hor = "../connector_hor.stl";
my $connector_vert = "../connector_vert.stl";
my $scad_out_dir = "../block_generation/blocks";
my $stl_out_dir = "../stl/blocks";

## dimensions
### mm, grid size
my $tile_size = 38;
### size of block (n direction = width)
my $block_size_n = 7;
### size of block (z direction = height)
my $block_size_w = 7;

## characters (for ASCII map)
my $char_empty = "\e[90m·\e[0m";
my $char_active = "◻︎";
my $char_stable = "◼︎";

# ==========================
# prepare
# ==========================
make_path($scad_out_dir);
make_path($stl_out_dir);

# Ask user whether to delete existing SCAD files
print "Delete existing SCAD files in $scad_out_dir? (y/n) ";
chomp(my $answer = <STDIN>);
if ($answer =~ /^y/i) {
    unlink glob("$scad_out_dir/*.scad");
    print "Old SCAD files deleted.\n";
}

# ==========================
# read CSV
# ==========================
open(my $fh, '<:encoding(utf8)', $csv_file) or die "Can't open: $csv_file\n";
my $header = <$fh>; # skip header row

my %tiles;
my ($minN, $maxN, $minZ, $maxZ);

while (my $line = <$fh>) {
    chomp $line;
    next if $line =~ /^\s*$/;
    my @f = split(/;/, $line);
    my ($index,$symbol,$A,$Z,$N,undef,$stable,undef,undef,undef,undef,undef,undef,$file) = @f;
    $N = int($N);
    $Z = int($Z);
    my $stl_file = "$tiles_dir/$file.stl";

    $tiles{$N}{$Z} = {
        file   => $stl_file,
        symbol => $symbol,
        index  => $index,
        stable => $stable
    };

    $minN = (!defined $minN or $N < $minN) ? $N : $minN;
    $maxN = (!defined $maxN or $N > $maxN) ? $N : $maxN;
    $minZ = (!defined $minZ or $Z < $minZ) ? $Z : $minZ;
    $maxZ = (!defined $maxZ or $Z > $maxZ) ? $Z : $maxZ;
}
close($fh);

# ==========================
# make blocks
# ==========================
for (my $bn = $minN; $bn <= $maxN; $bn += $block_size_n) {
    for (my $bz = $minZ; $bz <= $maxZ; $bz += $block_size_w) {
        my $scad_name = sprintf("block_N%d_Z%d.scad", $bn, $bz);
        my $scad_path = "$scad_out_dir/$scad_name";

        my $has_tiles = 0;
        my $scad_content = "// $scad_name\n// generated with group_tiles_in_block.pl\nunion() {\n";

        for my $n ($bn .. $bn + $block_size_n - 1) {
            for my $z ($bz .. $bz + $block_size_w - 1) {
                next unless exists $tiles{$n}{$z};
                $has_tiles = 1;
                my $tile = $tiles{$n}{$z};
                my $x = ($n - $bn) * $tile_size;
                my $y = ($z - $bz) * $tile_size;

                $scad_content .= sprintf("  translate([%d,%d,0]) import(\"%s\");\n", $x, $y, $tile->{file});
                print "  tile N=$n Z=$z at ($x,$y)\n";

                # Horizontal connector (right)
                if (exists $tiles{$n+1}{$z} && $n+1 <= $bn+$block_size_n-1) {
                    my $xc = $x;
                    my $yc = $y;
                    $scad_content .= sprintf("  translate([%d,%d,0]) import(\"%s\");\n", $xc, $yc, $connector_hor);
                    print "  horizontal connector at (N=$n,Z=$z)\n";
                }

                # Vertical connector (top)
                if (exists $tiles{$n}{$z+1} && $z+1 <= $bz+$block_size_w-1) {
                    my $xc = $x;
                    my $yc = $y + $tile_size;
                    $scad_content .= sprintf("  translate([%d,%d,0]) import(\"%s\");\n", $xc, $yc, $connector_vert);
                    print "   vertical connector at (N=$n,Z=$z)\n";
                }
            }
        }
        $scad_content .= "}\n";

        # Only write SCAD file if block contains tiles
        if ($has_tiles) {
            print "Generating block $scad_name ...\n";
            open(my $scad, '>', $scad_path) or die "Can't write: $scad_path\n";
            print $scad $scad_content;
            close($scad);
        } else {
            print "Skipping empty block $scad_name\n";
        }
    }
}

# ==========================
# generate ASCII map
# ==========================
print "\nOVERVIEW\n${char_active} = radioactive     ${char_stable} = stable     ${char_empty} = empty)\nN\n";

for (my $z = $maxZ; $z >= $minZ; $z--) {
    if (($z % 2) == 1) {
        printf("%3d ", $z);
    } else {
        print "    ";
    }
    for (my $n = $minN; $n <= $maxN; $n++) {
        my $char = exists $tiles{$n}{$z} ? $char_active : $char_empty;
        if (exists $tiles{$n}{$z} && $tiles{$n}{$z}->{stable} eq "true") {
            $char = $char_stable;
        }
        print " $char";
        if (($n - $minN + 1) % $block_size_n == 0 && $n < $maxN) {
            print "│";
        } else {
            print " ";
        }
    }
   print "\n";
   if (($z + 1 - $maxZ - $maxZ % $block_size_w) % $block_size_w == 0 && $z != $minZ) {
      print "    ";
      for (my $n = $minN; $n <= $maxN; $n++) {
         print "──";
         if (($n - $minN + 1) % $block_size_n == 0 && $n < $maxN) {
            print "┼";
         } else {
            print "─";
         }
      }
      print "\n";
   }
}
print "Z   ";
for (my $n = $minN; $n <= $maxN; $n++) {
    if (($n % 5) == 0) {
        printf("%-3d", $n);
    } else {
        print "   ";
    }
}

print "\n\n";
print "Done.\n";

exit 0;
