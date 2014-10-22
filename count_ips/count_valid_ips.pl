#!/usr/bin/perl -w
use Data::Dumper;
use File::Find;
use strict;


#I could also add use Data::Validate::IP qw(is_ipv4);
#but there's no sport in that

my $warning_summary = "";
my @results = ();
#this will be used repeatedly so may be worth overhead to pre-compile
my $basic_ip_pattern = qr/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/;

sub count_ips_in_file { 
    #ignore anything that isn't like a file
    return if -d;
    my $basename = $_;

    my $current_file = $File::Find::name;
    #report something amiss if can't read file
    $warning_summary .= "cannot open $current_file for reading\n" unless -r;
    return unless -r;

    my $ips_found = 0;
    open(IPS, "< $current_file") or warn "Couldn't open $current_file for reading:$!\n";
    while (<IPS>) {
        chomp;  #otherwise 'end of line' condition can be more complicated
        #promising candidates only
        next unless $_ =~ $basic_ip_pattern;
        #tokenize line, taking 'space separated' part of definition seriously
        my @words = split / /, $_;
        foreach my $w (@words) {
            if ($w =~ m/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/) {
                next if (($1 > 255) || ($2 > 255) || ($3 > 255) || ($4 > 255));
                #print $w . "\n";
                $ips_found += 1;
            }
        }
   }
   #print "$basename:  $ips_found\n" if $ips_found;
   push @results, [$basename, $ips_found] if $ips_found;
}

die "must specify absolute path to at least one directory as argument\n" unless ($ARGV[0] =~ m/^\//);
find(\&count_ips_in_file, @ARGV);

my @sorted_results = sort {$a->[0] cmp $b->[0]} @results;
foreach my $r (@sorted_results) {
    print $r->[0] . " " . $r->[1] . "\n";
}
print STDERR  $warning_summary . "\n";
