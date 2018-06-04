#!/usr/bin/perl -w

use strict;

die("Invalid syntax.\n") unless $ARGV[0] and $ARGV[1];

my $package1 = $ARGV[0];
my $package2 = $ARGV[1];

#print "Comparing $package1 to $package2.\n";

my ($package1_name, $package1_version, $package1_arch) = SplitPackage($package1);
my ($package2_name, $package2_version, $package2_arch) = SplitPackage($package2);

my @package1_verion_array = GetVersionArray($package1_version);
my @package2_verion_array = GetVersionArray($package2_version);

#print "$package1_name: " . join(',', @package1_verion_array) . "\n";
#print "$package2_name: " . join(',', @package2_verion_array) . "\n";

my $maxlen = $#package1_verion_array;
$maxlen = $#package2_verion_array if $#package2_verion_array > $maxlen;

for(my $i=0; $i <= $maxlen; $i++)
{
	#printf "comparing %s to %s\n", $package1_verion_array[$i], $package2_verion_array[$i];

	VersionResult(0) if !defined($package1_verion_array[$i]) and defined($package2_verion_array[$i]);
	VersionResult(1) if defined($package1_verion_array[$i]) and !defined($package2_verion_array[$i]);

	if( $package1_verion_array[$i] =~ /^\d+$/ and $package2_verion_array[$i] =~ /^\d+$/ )
	{
		VersionResult(0) if $package1_verion_array[$i] < $package2_verion_array[$i];
		VersionResult(1) if $package1_verion_array[$i] > $package2_verion_array[$i];
	}
	elsif( $package1_verion_array[$i] =~ /^[a-zA-Z]+$/ and $package2_verion_array[$i] =~ /^[a-zA-Z]+$/ )
	{
		VersionResult(0) if $package1_verion_array[$i] lt $package2_verion_array[$i];
		VersionResult(1) if $package1_verion_array[$i] gt $package2_verion_array[$i];
	}
	else
	{
		die( $package1_verion_array[$i] . " can't be compared with " . $package2_verion_array[$i] . " one is numeric one is alpha.\n");
	}
}


VersionResult(0) if GetPacketRev($package1_version) < GetPacketRev($package2_version);
VersionResult(1) if GetPacketRev($package1_version) > GetPacketRev($package2_version);

die("packets $package1 and $package2 have the same revision\n");

sub VersionResult {
	my $result = $_[0];
	#print("Exiting with $result\n");
	exit($result);
}

sub SplitPackage {
	my $package = $_[0];
	
	die("invalid package string\n") unless $package =~ /(.*)_(.*)_(.*)\.ipk/;
	return ($1, $2, $3);	
}

sub GetVersionArray {
	my $version = $_[0];

	my @versionarray;
	
	while( length($version) > 0 )
	{
		if( $version =~ s/^([a-zA-Z]+)\.*// )
		{
			push(@versionarray, $1);
		}
		elsif( $version =~ s/^(\d+)\.*// )
		{
			push(@versionarray, $1);
		}
		elsif( $version =~ s/^-(\d+)$// )
		{
			#push(@versionarray, $1);
		}
		else
		{
			die("Can't parse version\n");
		}
	}

	return @versionarray;
}

sub GetPacketRev {
	my $version = $_[0];
	if( $version =~ /-(\d+)$/ )
	{
		return $1;
	}
	else
	{
		return 0;
	}
}
