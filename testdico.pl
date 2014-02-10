#!usr/bin/perl
####-----------------------------------
### File	: testdico.pl
### Author	: Ch.Minc
### Purpose	: chargement des dicos et test
### Version	: 1.1 2012/06/30
### copyright GNU license
### utf 8
####-----------------------------------


our $VERSION = '1.1';
use  5.012003;
use strict ;
use warnings ;
use Carp ;
#use utf8 ;
$Carp::Verbose='true' ;
use Data::Dumper;
use MongoDB;
use MongoDB::OID;
use POSIX qw(strftime);
use Test::More tests => 27;

=head1 INSTALL

Après décompression de dicos.zip , on obtient deux fichiers prolex.json et delaf.json.

Si l'on veut installer les dictionnaires sous le répertoire G:/Dictionnaires/DBmg et que les fichiers se trouve dans le répertoire 
G:/Dictionnaires/json/ , il suffira de taper les commandes suivantes :

c:/mongodb/bin/mongoimport -d dicos -c Prolex --dbpath G:/Dictionnaires/DBmg G:/Dictionnaires/json/prolex.json
c:/mongodb/bin/mongoimport -d dicos -c Delaf --dbpath G:/Dictionnaires/DBmg G:/Dictionnaires/json/delaf.json
c:/mongodb/bin/mongoimport -d dicos -c Delaf --dbpath G:/Dictionnaires/DBmg G:/Dictionnaires/json/Lexique372.json

et enfin  pour lancer le démon Mongod : c:/mongodb/bin/mongod -dbpath G:\Dictionnaires\DBmg

=head1 TEST

Le programme de test testdico.pl devrait permettre de valider l'installation en tapant la commande :

perl.exe -w testdico.pl

=head1 RESULTATS

l'exécution sans erreur donnant le résultat suivant :

>perl -w testdico.pl
1..12
ok 1 - une seule occurence
ok 2 - trouve le lemme
ok 3 - trouve le pos
ok 4 - une seule occurence
ok 5 - trouve le lemme
ok 6 - trouve le pos
ok 7 - une seule occurence
ok 8 - trouve le lemme
ok 9 - trouve le pos
ok 10 - une seule occurence
ok 11 - trouve le lemme
ok 12 - trouve le pos
>Exit code: 0

=cut

my $conn= MongoDB::Connection->new;
my $db = $conn->dicos;
#$db->drop;
my $coll="Prolex";
my $prolex= $db->$coll;
my $delaf=$db->Delaf ;
my $lexique372=$db->Lexique372 ;

=head1 accès aux formes,pos,lemma

prolex :
"LexicalEntry.Lemma.writtenForm"
"LexicalEntry.partOfSpeech"
"LexicalEntry.WordForm .writtenForm"

delaf:
entry.lemma
entry.pos.name
entry.inflected.feat.form

=cut

my $lemmep="LexicalEntry.Lemma.writtenForm" ;
my $posp="LexicalEntry.partOfSpeech" ;
my $formp="LexicalEntry.WordForm.writtenForm" ;

my $lemmed="entry.lemma.\$t" ;
my $posd="entry.pos.name" ;
my $formd="entry.inflected.form.\$t" ;

# test cherche lesformes et donne les lemmes et le pos
# pour le debut et la fin de chaque dictionnaire

#is  ($got, $expected, $test_name);

#######################################################
my $foundp=$prolex->find( {$formp=> qr/^assiniboine$/i}) ;

is ($foundp->count, 1 , "une seule occurence" );

while(my $val=$foundp->next){
	is($val->{'LexicalEntry'}{'Lemma'}{'writtenForm'}, "assiniboine", "trouve le lemme");
	is (  $val->{'LexicalEntry'}{'partOfSpeech'} ,"noun", "trouve le pos") ;
	}
########################################################
$foundp=$prolex->find( {$formp=> qr/^Zyrjanka$/i}) ;

is ($foundp->count, 1 , "une seule occurence" );

while(my $val=$foundp->next){
is	($val->{'LexicalEntry'}{'Lemma'}{'writtenForm'}, "Zyrjanka", "trouve le lemme");
is (  $val->{'LexicalEntry'}{'partOfSpeech'} ,"noun", "trouve le pos") ;
};
########################################################
my $foundd=$delaf->find( {$formd=>qr/^abacas$/i}) ;

is ($foundd->count, 1 , "une seule occurence" );

while ( my $vald=$foundd->next){
	is($vald->{'entry'}{'lemma'}{'$t'}, "abaca", "trouve le lemme");
	is (  $vald->{'entry'}{'pos'} {'name'},"noun", "trouve le pos") ;
	};
########################################################
$foundd=$delaf->find( {$formd=> qr/^zyzomys$/i}) ;

is ($foundd->count, 1 , "une seule occurence" );

while(my $val=$foundd->next){
	is ($val->{'entry'}{'lemma'}{'$t'}, "zyzomys", "trouve le lemme");
	is (  $val->{'entry'}{'pos'} {'name'} ,"noun", "trouve le pos") ;
	} ;

# retrouve le temps de la forme d'un verbe

my $mot="chantai" ;

$foundd=$delaf->find( {$formd=> qr/^$mot$/i}) ;

say $foundd->count ;

while(my $val=$foundd->next){
	say $val->{'entry'}{'lemma'}{'$t'} ;
	say $val->{'entry'}{'pos'} {'name'} ;
	for  (0..$#{$val->{'entry'}{'inflected'}}){
	if   ($val->{'entry'}{'inflected'}[$_]{'form'}{'$t'} =~m/^$mot$/i){
	 is $val->{'entry'}{'inflected'}[$_]{'form'}{'$t'},"chantai","forme de chantai";
	 
	 is $val->{'entry'}{'inflected'}[$_]{'feat'}[0]{'name'},"tense", "temps";
	  is $val->{'entry'}{'inflected'}[$_]{'feat'}[0]{'value'},"ind","temps ind";
	 
	  is $val->{'entry'}{'inflected'}[$_]{'feat'}[1]{'name'},"person", "person tag";
	 is $val->{'entry'}{'inflected'}[$_]{'feat'}[1]{'value'},"1","personne première";
	 
	is $val->{'entry'}{'inflected'}[$_]{'feat'}[2]{'name'},"number"," nombre";
	  is $val->{'entry'}{'inflected'}[$_]{'feat'}[2]{'value'},"singular","du singulier";	  
	} ;
    };
}
# retrouve le temps de la forme d'un verbe plus directe (traverse les arrays)
$foundd=$delaf->find( {"entry.inflected.form.\$t"=> qr/^chantaient$/i}) ;
say $foundd->count ;
my $val=$foundd->next;
is $val->{'entry'}{'inflected'}[0]{'form'}{'$t'},"chantaient","forme chantaient";
is $val->{'entry'}{'lemma'}{'$t'} ,"chanter", "lemme :chanter";
is $val->{'entry'}{'inflected'}[0]{'feat'}[0]{'value'},"ind","temps indicatif";


# Lexique372

my $foundL=$lexique372->find( {'ortho'=> qr/^tomba$/i}) ;

say $foundL->count ;

while(my $val=$foundL->next){

	is $val->{'lemme'},"tomber","lemme de tomba" ;
	is $val->{'cgram'},"VER"," pos de tomba : VER" ;
	is $val->{'genre'},'',"pas de genre dans ce cas" ;
	is $val->{'nombre'},'',"pas de nombre dans ce cas" ; ;
	is $val->{'infover'} , "ind:pas:3s;", "passé simple 3 eme du sing";

}
