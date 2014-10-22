#!/usr/bin/perl
use Data::Dumper;
use strict;

my %table = ();
my %expansion = ();
my $number_of_symbols;

sub expand($$) {
    my ($s, $l) = @_;
    print "expanding new symbol $s at level $l\n";
    my $expanded = "";
    my $separator = "---->";
    my $nodepseparator = "--->";

    #this may not be the fastest way to check for circularity but it simplifies
    #the bookkeeping--rely on pigeon-hole principle to limit length of recursive path
    #for pending expansion for any symbol, if path is too long some symbol appears 
    #at least twice
    die "circular dependencies in this table:\n" . Dumper(\%table) . "\n" unless ($l <= $number_of_symbols + 1);

    my @deps = @{$table{$s}};
    foreach my $d  (@deps) {
        print "$l -th level symbol is $d\n";

        #table is one-level deep, can use defined
        #without risk of autovivication and case
        #where table entry is empty is treated
        #correctly--no dependencies is valid use case
        #if it has no dependencies, set it up for output
        if (! defined ($table{$d})) {
            $expanded .= $nodepseparator . $d;
            next;
        }
        #if it's unexpanded, expand it now, in a recursive call
        if (exists ($table{$d}) && (! $expansion{$d})) {
            expand($d, $l + 1);
        } 
        $expanded .= $separator . $expansion{$d};
    }
    #expansions come with arrows
    #note that this will just print the symbol if there's
    #an empty entry in the table for any key
    $expansion{$s} = "$s" . $expanded;
    print Dumper(\%expansion);
}

my $symbol_file = $ARGV[0]; 
die "Must supply a file of dependencies\n" unless $symbol_file;
open(DEPS, "<$symbol_file") or die "Couldn't open $symbol_file for reading:$!\n";
while (<DEPS>) {
    my($symbol, $value) = split /\s+/, $_;
    my @values = split /,/, $value;
    $table{$symbol} = \@values;
}    
close(DEPS);


#plan to do evaluate only as needed
%expansion = map {$_ => ""} keys %table;

#expanding to levels past number of symbols + 1
#implies circularity (symbol shouldn't reappear
#on path, pigeon hole principle). 
$number_of_symbols = scalar(keys %table);

#print Dumper(\%table);
print Dumper(\%expansion);

while(<STDIN>) {
    #get symbol
    my $s = $_;
    chomp $s;

    #strip white space
    $s =~ s/^\s+//;
    $s =~ s/\s+$//;
    print "evaluating symbol" . $s . "\n";

    #is symbol included in dependency table?
    #table is one-level deep, can use defined
    #without risk of autovivication
    if (defined($table{$s})) {
        print "expanding of $s\n";
        if (! $expansion{$s}) {
   	   expand($s, 1);
        } 
   	print $expansion{$s} . "\n";
    }
    else {
        #symbol has no dependencies if not
        #in symbol table 
        print "no evaluation needed\n";
        print "$s" . "\n";
   }
}
