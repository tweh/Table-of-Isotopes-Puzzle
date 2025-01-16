#!/usr/bin/perl
use strict;
use warnings;
use Text::CSV;
use File::Path qw(make_path remove_tree);
use File::Spec;
use IPC::System::Simple qw(system);

sub generate_stl {
    my ($scad_file, $output_path, $variables) = @_;
    
    # Build the OpenSCAD command
    my @cmd = ("openscad", ,"--backend=manifold", "--enable=textmetrics", "-o", $output_path, $scad_file);
    foreach my $key (keys %$variables) {
        push @cmd, "-D$key=$variables->{$key}";
    }
    
    # Execute the OpenSCAD command
    system(@cmd);
}

sub process_csv {
    my ($csv_path, $scad_file, $output_base) = @_;

    # Open the CSV file
    my $csv = Text::CSV->new({ binary => 1, sep_char => ';' })
        or die "Cannot use CSV: " . Text::CSV->error_diag();
    open my $fh, "<", $csv_path or die "Could not open '$csv_path': $!";
    
    # Read CSV headers
    my $headers = $csv->getline($fh);
    $csv->column_names(@$headers);

    # Process each row
    while (my $row = $csv->getline_hr($fh)) {
        my $base_file_name = $row->{'file name'};
        
        # Set OpenSCAD variables from the CSV row
        my %variables = (
            ElementSymbol   => "\"$row->{'symbol'}\"",
            ElementMass     => "\"$row->{'A'}\"",
            ElementProtons  => "\"$row->{'Z'}\"",
            ElementDecays   => "\"$row->{'decay text'}\"",
            alphaDecay      => lc($row->{'alpha decay'}) eq 'true' ? 'true' : 'false',
            betaMinusDecay  => lc($row->{'beta minus decay'}) eq 'true' ? 'true' : 'false',
            betaPlusDecay   => lc($row->{'beta plus decay'}) eq 'true' ? 'true' : 'false',
        );

        # Determine if markSecondDecay should be true
        my $decay_count = 0;
        $decay_count++ if $variables{alphaDecay} eq 'true';
        $decay_count++ if $variables{betaMinusDecay} eq 'true';
        $decay_count++ if $variables{betaPlusDecay} eq 'true';

        my %configs = (
            p  => { showDecaysText => 'false', markSecondDecay => 'false' },
            pd => { showDecaysText => 'true',  markSecondDecay => 'false' },
            c  => { showDecaysText => 'false', markSecondDecay => $decay_count >= 2 ? 'true' : 'false' },
            cd => { showDecaysText => 'true',  markSecondDecay => $decay_count >= 2 ? 'true' : 'false' },
        );

        foreach my $folder (keys %configs) {
            my $output_dir = File::Spec->catdir($output_base, $folder);
            make_path($output_dir) unless -d $output_dir;
            
            # Combine base variables with current configuration
            my %current_variables = (%variables, %{ $configs{$folder} });
            
            my $stl_path = File::Spec->catfile($output_dir, "$base_file_name.stl");
            generate_stl($scad_file, $stl_path, \%current_variables);
        }
    }
    close $fh;
}

sub prompt_to_clear_directories {
    my ($base_dir) = @_;
    print "Do you want to clear existing STL files in the output directories? (y/n): ";
    my $response = <STDIN>;
    chomp($response);
    if (lc($response) eq 'y') {
        if (-d $base_dir) {
            remove_tree($base_dir, { keep_root => 1 });
            print "Directories cleared.\n";
        } else {
            print "No directories to clear.\n";
        }
    }
}

sub prompt_for_test_mode {
    print "Do you want to run in test mode? (y/n): ";
    my $response = <STDIN>;
    chomp($response);
    return lc($response) eq 'y';
}

# Main script execution
my $csv_file_path = "../isotope_data/isotope_data.csv"; # Default CSV file path
my $scad_file_path = "nuclidepuzzle_tiles.scad"; # Path to the OpenSCAD file
my $output_base = File::Spec->catdir("..", "stl", "tiles"); # Default output directory

if (prompt_for_test_mode()) {
    $csv_file_path = "../isotope_data/isotope_data_test.csv";
    $output_base = File::Spec->catdir("..", "stl", "tiles_test");
}

prompt_to_clear_directories($output_base);
process_csv($csv_file_path, $scad_file_path, $output_base);
