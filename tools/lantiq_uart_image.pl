#!/usr/bin/perl
#
# Copyright (C) 2005-2015 Lantiq Deutschland GmbH
#
# SPDX-License-Identifier:	GPL-2.0+
#

#use strict;
#use Cwd;
#use Env;

my $aline;
my $lineid;
my $length;
my $address;
my @bytes;
my $addstr;
my $chsum=0;
my $count=0;
my $firstime=1;
my $i;
my $currentaddr;
my $tmp;
my $holder="";
my $loadaddr;

if(@ARGV < 2){
	die("\n Syntax: ./program_SDRAM input1(memory setup) input2(*\.srec) output\n");
}

open(INFILE1, "<$ARGV[0]") || die("\ninput1 open fail\n");
open(INFILE2, "<$ARGV[1]") || die("\ninput2 open fail\n");
open(OUTFILE, ">$ARGV[2]") || die("\nOutput file open fail\n");

$i=0;
while ($line = <INFILE1>){
	if($line=~/\w/){
		if($line!~/[;#\*]/){
			if($i eq 0){
				printf OUTFILE ("33333333");
			}
			chomp($line);
			$line=~s/\t//;
			@array=split(/ +/,$line);
			$j=0;
			while(@array[$j]!~/\w/){
				$j=$j+1;
			}
			$addr=@array[$j];
			$regval=@array[$j+1];
			$addr=~s/0x//;
			$regval=~s/0x//;
			printf OUTFILE ("%08x%08x",hex($addr),hex($regval));
			$i=$i+1;
			if($i eq 8){
				$i=0;
				printf OUTFILE ("\n");
			}
		}
	}
}

while($i lt 8 && $i gt 0){
	printf OUTFILE "00"x8;
	$i=$i+1;
}

if($i eq 8){
	printf OUTFILE ("\n");
}

while($aline=<INFILE2>){
	$aline=uc($aline);
	chomp($aline);
	next if(($aline=~/^S0/) || ($aline=~/^S7/));
	($lineid, $length, $address, @bytes) = unpack"A2A2A8"."A2"x300, $aline;
	$length = hex($length);
	$address = hex($address);
	$length -=5;
	$i=0;

	while($length>0){
		if($firstime==1){
			$addstr = sprintf("%x", $address);
			$addstr = "0"x(8-length($addstr)).$addstr;
			print OUTFILE $addstr;
			addchsum($addstr);
			$firstime=0;
			$currentaddr=$address;
			$loadaddr = $addstr;
		}
		else{
			if($count==64){
				$addstr = sprintf("%x", $currentaddr);
				$addstr = "0"x(8-length($addstr)).$addstr;
				print OUTFILE $addstr;
				addchsum($addstr);
				$count=0;
			}
			#printf("*** %x != %x\n", $address, $currentaddr) if $address != $currentaddr;
		}
		if($currentaddr < $address) {
			print OUTFILE "00";
			addchsum("00");
			$count++;
			$currentaddr++;
		}
		else {
			while($count<64){
				$bytes[$i]=~tr/ABCDEF/abcdef/;
				print OUTFILE "$bytes[$i]";
				addchsum($bytes[$i]);
				$i++;
				$count++;
				$currentaddr++;
				$length--;
				last if($length==0);
			}
		}
		if($count==64){
			print OUTFILE "\n";
			#print OUTFILE "\r";
		}
	}
}
if($count != 64){
	$tmp = "00";
	for($i=0;$i<(64-$count);$i++){
		print OUTFILE "00";
		addchsum($tmp);
	}
	print OUTFILE "\n";
	#print OUTFILE "\r";
}


print OUTFILE "11"x4;
use integer;
$chsum=$chsum & 0xffffffff;
$chsum = sprintf("%X", $chsum);
$chsum = "0"x(8-length($chsum)).$chsum;
$chsum =~tr/ABCDEF/abcdef/;
print OUTFILE $chsum;
print OUTFILE "00"x60;
print OUTFILE "\n";
#print OUTFILE "\r";

print OUTFILE "99"x4;
print OUTFILE $loadaddr;
print OUTFILE "00"x60;
print OUTFILE "\n";
#print OUTFILE "\r";


close OUTFILE;
#END of Program



sub addchsum{
	my $cc=$_[0];
	$holder=$holder.$cc;
	if(length($holder)==8){
		$holder = hex($holder);
		$chsum+=$holder;
		$holder="";
	}
}
#END

