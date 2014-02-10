#!c:/Perl/bin/perl.exe
####-----------------------------------
### File	 : retagxml.pl
### Author	: Ch.Minc
### Purpose	: retrieve the tags NAM to be correct and modify if needed
### Version	: 1.0 05/05/2012
### copyright GNU license
### utf-8
####-----------------------------------

our $VERSION = '1.1';
use  5.12.3;
use strict ;
use warnings ;
use Encode ;
use Encode qw(from_to) ;
use charnames ':full' ;
#my $enc='utf-8' ;
my $enc='utf8' ;
use HTML::Entities;
use POSIX qw(strftime);
use File::Glob ':globally';
use Carp ;
use Data::Dumper;
use File::Spec;
use File::Basename ;

use Web::Scraper ;
use URI ;

use Moose;
with 'MooseX::Getopt';

=Synopsis

perl -w retagxml.pl --txm_dir your_txm_dir --working_dir your_output_dir

take the files under txm_dir with the xml extension and treats them and write
the results file by file into the working_dir (must exists).

=cut

=Purpose
This programs intends to track some bugs of TreeTagger.
Nouns written with upper letters tagged as proper noun are often
common nouns so improperly analysed.
This is done by a checking  on an internet dictionnary.
All the files are supposed to be writen with utf8 characters set.
System used must be irrelevant.

The program rint the values selected and the new values we have got.
It could run silently if the parameters $silent is set to '1' instead '0'.

=cut

my $silent= 0 ;

has 'txm_dir'  => (is => 'rw', isa => 'Str', required => 0,default =>'C:/Documents and Settings/Charles/TXM/corpora/maj/txm/MAJ') ;
has 'working_dir'  => (is => 'rw', isa => 'Str', required => 0,default =>'I:/work') ;

my $param =main->new_with_options();

# general parameters

my $txm_dir=$param->{txm_dir};
my $working_dir=$param->{working_dir};


my $reg=qr!<w id=".*" n="(\d+)" type="w"><txm:form>(.*)</txm:form><txm:ana resp="#txm" type="#.*pos">NAM</txm:ana><txm:ana resp="#txm" type="#.*lemma">(.*)</txm:ana></w>! ;

my $now_iso8601= strftime "%Y-%m-%dT%H:%M:%S+02:00", localtime;
say "program $0 starts :", $now_iso8601 ;

my @files=<"$txm_dir"/*.xml> ;

for my $f (@files) {
	
open(my $fhh,'<',$f)  || die "can't open filename: $!";

my @lg ;
&propreounom($reg,$fhh,\@lg) ;
close $fhh ;

my($newf, $directories, $suffix) = fileparse($f);
my $output=File::Spec->catfile($working_dir ,$newf );
open(my $fo,'>',$output)  || die "can't open filename: $!";
print $fo @lg ;
close $fo ;

}

$now_iso8601= strftime "%Y-%m-%dT%H:%M:%S+02:00", localtime;
say "program $0 stop :", $now_iso8601 ;


sub propreounom{
# parameters are the regex, the file  and and an array pointer	
# return value are in the array pointer ($lignes)
my $reg=shift ;
my $fhh=shift ;
my $lignes=shift ;

# add a new line after each <w ...></w>
my $l ;
while(<$fhh>){
$l .=$_ ; }
$l=~s/\n//g ;
$l=join "\n<w ",split '<w',$l ;
#say $l ;
@{$lignes}=split /\n/,$l ;

# get the tagged datas with 'NAM'
for my $iter (0..$#${lignes}) {
	my $h={} ;
	$lignes->[$iter]=onespace($lignes->[$iter] ) ;

	if($lignes->[$iter]=~ m/$reg/) {	
	say "look at :" ,$2," lm:", $3	 unless $silent ;
	my $lemme=$3 ;
	&lookatweb($2,$h) ;
	my $change=&cntrl2txm($h->{'.tlf_ccode'}) ;
	say "get for this word numbered $iter the new value : ", $change unless $silent ;
	say ''  unless $silent ;
	$lignes->[$iter] =~s/NAM/$change/ ;
	# lemma is got with  .tlf_cmot" , but basically the change is only need when the tag is different
	$lignes->[$iter] =~s/lemma\">$lemme/lemma\">$h->{'.tlf_cmot'}/ unless  ($change eq 'NAM');
	}
	
	}
}

sub cntrl2txm{
	# trancode tags from tlf to TT
	my $tlf_code=shift ;
	# correspondance .tlf_ccode
	# si word  eq "not_found" means that NAM is probably correct
        # the  visited site does'nt give the tense of the verb so it's set to infinitive in any case
	my %code=('adj'=>'ADJ','adv'=> 'ADV','art'=>'DET:ART','subst.'=>'NOM','verbe'=>'VER:INFI','not_found'=>'NAM');
	my $ttcode ;	
	for my $c (keys %code){
		$ttcode=$code{$c};
		last if  ($tlf_code  =~/$c/) ;}
		return $ttcode ;
}

sub lookatweb {
# get a word and retrieve on the following site lemma,( tlf_cmot) , tags(.tlf_ccode),
# default is set to 'not_found'
#my $uriv="http://www.cnrtl.fr/lexicographie/$u/substantif" ;	
my $form=shift ;
my $h=shift ;
my $look3="title" ;
my $look4=".tlf_cmot" ;
my $look5=".tlf_ccode" ;

for ($look3,$look4,$look5) {
my $s=scraper {
	process $_,word =>'TEXT' ;
	result 'word';
} ;

my $uriv="http://www.cnrtl.fr/lexicographie/$form" ;
my $uri=URI->new($uriv) ;
$h->{$_}=encode_utf8($s->scrape($uri) // 'not_found');
}
# a small cleaning (sometimes index and comma  are attached at the end)
$h->{'.tlf_cmot'}=lc $h->{'.tlf_cmot'} ;
$h->{'.tlf_cmot'} =~ s/([^a-z_])//g ;
}

sub onespace {
# suppress in a string (xml type) duplicated whitespace	
	my $string=shift ;
	my $reg=qr/\s*([<=>\s]|\".*\")\s*/ ;
	$string=~ s/$reg/$1/g ;
	return $string ;
}
	