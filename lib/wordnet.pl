#!/opt/local/bin/perl
##!/usr/bin/perl

#インストール
#sudo cpan DBI
#sudo cpan DBD::SQLite
#sudo cpan Lingua::JA::WordNet
#sudo /usr/libexec/locate.updatedb
# sudo chmod -R 777 /opt/local/lib/perl5/site_perl/5.22/auto/share/dist/Lingua-JA-WordNet/wnjpn-1.1_and_synonyms-1.0.db

#参考サイト
#http://nlpwww.nict.go.jp/wn-ja/jpn/detail.html
#https://ja.wikipedia.org/wiki/WordNet
#Hype Hypernym  上位語  当該synsetが相手synsetに包含される  "canis familiaris"(02084071-n)は"domestic animal"(01317541-n)と"canid"(02083346-n)に包含される
#Hypo Hyponym 下位語  当該synsetが相手synsetを包含する  "canis familiaris"(02084071-n)は"toy canis familiaris"(02085374-n),"mutt"(02084861-n),"pooch"(02084732-n),...を包含する
#Mprt Meronyms --- Part 被構成要素(部分)  当該synsetが相手synsetという部分によって構成される  "canis familiaris"(02084071-n)は"flag"(02158846-n)を一部分として持つ
#Hprt Holonyms --- Part 構成要素(部分)  当該synsetが部分として相手synsetを構成する  "flag"(02158846-n)は"canis familiaris"(02084071-n)や"cervid"(02430045-n)の一部分である
#Hmem Holonyms --- Member 構成要素(構成員)  当該synsetが相手synsetの構成員である  "canis familiaris"(02084071-n)は"02083863-n"(canis)や"pack"(07994941-n)の構成員である
#Mmem Meronyms --- Member 被構成要素(構成員)  当該synsetが相手synsetという構成員によって構成される  "canis"(02083863-n)は"canis familiaris"(02084071-n)や" jackal"(02115096-n)、"wolf"(02114100-n)を構成員として持つ
#Msub Meronyms --- Substance  被構成要素(物質・材料)  当該synsetが相手synsetという物質or材料によって構成される  "ozone"(14972807-n)は"atomic number 8"(14648100-n)という物質を構成要素として持つ
#Hsub Holonyms --- Substance  構成要素(物質・材料)  当該synsetが相手synsetを構成する物質or材料である  "atomic number 8"(14648100-n)は"ozone"(14972807-n)や"water"(14845743-n)、"air"(14841267-n)を構成する物質である
#Dmnc Domain --- Category 被包含領域(カテゴリ)  当該synsetが相手synsetのカテゴリに属する  "comet"(09251407-n)は"astronomy"(06095022-n)のカテゴリに属する
#Dmtc In Domain --- Category  包含領域(カテゴリ)  当該synseが相手synsetが属するカテゴリである  "astronomy"(06095022-n)というカテゴリには"uprise"(01970348-v)や"absolute magnitude"(05090979-n)が属している
#Dmnu Domain --- Usage  被包含領域(語法)  当該synsetの用法が相手synsetの領域に限られる  "jean"(03594734-n)の用法は"plural form"(06295235-n)に限定される
#Dmtu In Domain --- Usage 包含領域(語法)  当該synsetの領域が相手synsetの用法を規定する  "plural form"(06295235-n)は"jean"(03594734-n)の用法を規定する
#Dmnr Domain --- Region 被包含領域(地域)  当該synsetが相手synsetの地域に属するものである  "sake"(07891433-n)は"nippon"(08921850-n)という地域に属している
#Dmtr In Domain --- Region  包含領域(地域)  当該synsetが相手synsetの属する地域である  "nippon"(08921850-n)は"sake"(07891433-n)の属する地域である
#Inst Instances 例  当該synsetは相手synsetの例である  "seiji ozawa"(11219502-n)は"director"(09952539-n)の例である
#Hasi Has Instance  例あり  当該synsetは相手synsetを例として持つ  "director"(09952539-n)は"seiji ozawa"(11219502-n)を例に持つ
#Enta Entails 含意  当該synsetを行う場合、必ず相手synsetも行っている  "fleece"(02319050-v)を行う場合、必ず"charge"(02320374-v)も行っている
#Caus Causes  引き起こし  当該synsetを行うと、相手synsetを引き起こす  "project"(02138075-v)を行うと、"appear"(00422090-v)を引き起こす
#Also See also  関連  当該synsetと相手synsetとの間に何らかの関連がある  "white"(00393105-a)は"light"(00408660-a)との間に何らかの関連がある
#Attr Attributes  属性  (a=形容詞のsynsetから見て)当該synsetが相手synsetという属性を表す際に使われる  "white"(00393105-a)は"value"(04979425-n)という属性を表す際に使われる
#(n=名詞のsynsetから見て)当該synsetという属性を表す際に相手synsetを使う "value"(04979425-n)という属性を表すのに"white"(00393105-a)を使う
#Sim  Similar to  近似  当該synsetは表す意味が相手synsetと近似している  "white"(00393105-a)は意味が"albescent"(00393422-a)と近似している
use Lingua::JA::WordNet;
 
my $jp = $ARGV[0];
my $wn = Lingua::JA::WordNet->new;
my @synsets = $wn->Synset("$jp");
my @hypes   = $wn->Rel($synsets[0], 'hype');
&printword(\@hypes,"上位語");
  my $wordID   = $wn->WordID("$jp", 'n');
  my @synonyms = $wn->Synonym($wordID);
#   
   print "シノニム:@synonyms\n";
my @hypos   = $wn->Rel($synsets[0], 'hypo');
&printword(\@hypos,"下位語");
 
# -> レスリング
#  
  # Synonym method can access to Japanese WordNet Synonyms Database.
  #my $wordID   = $wn->WordID('ねんねこ', 'n');
  #my @synonyms = $wn->Synonym($wordID);
#   
   #print "@synonyms\n";
#   # -> お休み ねね スリープ 就眠 御休み 眠り 睡り 睡眠
#
sub printword{
  my $words=shift;
  my $method=shift;
  foreach my $word(@$words){
    my @w   = $wn->Word($word);
    print "$method:@w\n"; 
  }
}
