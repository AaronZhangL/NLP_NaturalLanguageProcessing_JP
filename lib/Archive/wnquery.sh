#!/bin/bash
#わーどネット sqlite3メソッド
searchword=$1;
searchlink=$2;
searchlang=$3;
#
#DB="wnjpn-1.1_and_synonyms-1.0.db";
DB="wnjpn.db";

function Synonym(){
  local wordid="$1";
  rst=`sqlite3 "$DB" "SELECT lemma FROM word JOIN wordlink ON word.wordid = wordlink.wordid2
              WHERE wordid1 = '$wordid' 
                AND link    = 'syns'"`;
  echo "$rst";
}
function WordID(){
  local word="$1";
  word=`echo "$word"|sed -e "s| |_|g"`;
  local pos="$2";
  local lang="jpn";
  if [ -n "$3" ];then
    lang="$3";  
  fi
  rst=`sqlite3 "$DB" "SELECT wordid FROM word
              WHERE lemma = '$word' 
                AND pos   = '$pos'
                AND lang  = '$lang'"`;
  echo "$rst";
}
function Rel(){
  local synset="$1";
  local rel="$2";
  rst=`sqlite3 "$DB" "SELECT synset2 FROM synlink
              WHERE synset1 = '$synset' 
                AND link    = '$rel'"`;
  echo "$rst";
}
function Pos(){
  local synset="$1";
  rst=`sqlite3 "$DB" "SELECT sid, def FROM synset_def
              WHERE synset = '$synset'
                AND lang   = '$lang'"`;
  echo "$rst";
}
function SynPos(){
  local word="$1";
  local pos="$2";
  local lang="jpn";
  if [ -n "$3" ];then
    lang="$3";  
  fi
  rst=`sqlite3 "$DB" "SELECT synset FROM word LEFT JOIN sense ON word.wordid = sense.wordid
              WHERE lemma      = '$word' 
                AND word.pos   = '$pos'  
                AND sense.lang = '$lang'"`;
  echo "$rst";
}
#
function Ex(){
  local synset="$1";
  local lang="jpn";
  if [ -n "$2" ];then
    lang="$2";  
  fi
  rst=`sqlite3 "$DB" "SELECT sid, def FROM synset_ex
              WHERE synset = '$synset' 
                AND lang   = '$lang'"`;
  echo "$rst";
}
function Def(){
  local synset="$1";
  local lang="jpn";
  if [ -n "$2" ];then
    lang="$2";  
  fi
  rst=`sqlite3 "$DB" "SELECT sid, def FROM synset_def
              WHERE synset = '$synset'
                AND lang   = '$lang'"`;
  echo "$rst";
}
function Word(){
  local synset="$1";
  local lang="jpn";
  if [ -n "$2" ];then
    lang="$2";  
  fi
  rst=`sqlite3 "$DB" "SELECT lemma FROM word JOIN sense ON word.wordid = sense.wordid
              WHERE synset     ='$synset' 
                AND sense.lang = '$lang'"`;
  echo "$rst";
}
main(){
  #キーワードのIDを取得する
  echo "##################";
  echo "検索ワード:$searchword";
  synsets=`Synset "$searchword" "$searchlang"` ;
  #IDから品詞を取得する
  #$pos can take the left side values of the following table.
  #
  #  a|adjective
  #  r|adverb
  #  n|noun
  #  v|verb
  #  a|形容詞
  #  r|副詞
  #  n|名詞
  #  v|動詞
  #SynPos "$searchword"  "$pos";
  echo "$synsets"|while read line;do
  echo "##################";
    echo "id:$line";
  #IDからキーワードを取得する
    Word "$line";
  #IDから定義文を取得する
    Def "$line";
  #IDから例文を取得する
    Ex "$line";
  #IDから品詞を取得する
    Pos "$line";
  #IDからRelを取得する
    echo "【上位語】";
    Rel "$line" "hype"|while read line2;do
        re=`Word "$line2";`
        if [ -n "$re" ];then
          echo "$re";
        else
          Word "$line2" "eng";
        fi  
    done;
    echo "【下位語】";
    Rel "$line" "hypo"|while read line2;do
        re=`Word "$line2";`
        if [ -n "$re" ];then
          echo "$re";
        else
          Word "$line2" "eng";
        fi  
    done;

  echo "##################";
  done;  
#  wordID=`WordID "$searchword" "n"`;
#  echo "【シノニム】";
#  Synonym "$wordID";
  echo "##################";
}
function Synset(){
  local word="$1";
  local lang="jpn";
  if [ -n "$2" ];then
    lang="$2";  
  fi
  rst=`sqlite3 "$DB" "SELECT synset FROM word LEFT JOIN sense ON word.wordid = sense.wordid WHERE lemma = '$word' AND sense.lang = '$lang'"`;
  echo "$rst";
}
function getWord(){
  local wordid="$1";
  rst=`sqlite3 "$DB" "select * from word where wordid='$wordid'"`;
  echo "$rst";
}
function getSense(){
  local synset="$1";
  local lang="jpn";
  if [ -n "$2" ];then
    lang="$2";  
  fi
  rst=`sqlite3 "$DB" "select * from sense where synset='$synset' and lang='$lang'"`;
  if [ -z "$rst" ];then
    rst=`sqlite3 "$DB" "select * from sense where synset='$synset' and lang='eng'"`;
  fi
  echo "$rst";
}
function getSenses(){
  local wordid="$1";
  rst=`sqlite3 "$DB" "select * from sense where wordid='$wordid'"`;
  echo "$rst";
}
function getWords(){
  local word="$1";
  rst=`sqlite3 "$DB" "select * from word where lemma='$word'"`;
  echo "$rst";
}
function getSynset(){
  local synset="$1";
  rst=`sqlite3 "$DB" "select * from synset where synset='$synset'"`;
  echo "$rst";
}
function  getSynLinks(){
  local sense="$1";
  local synset=`echo "$sense"|awk -F\| '{print $1;}'`
  local link="$2";
  rst=`sqlite3 "$DB" "select * from synlink where synset1='$synset' and link='$link'"`;
  echo "$rst";
}
#def getSense(synset, lang='jpn'):
#  cur = conn.execute("select * from sense where synset=? and lang=?",
#      (synset,lang))
#  row = cur.fetchone()
#  if row:
#    return Sense(*row)
#  else:
#    return None
#def getSynLinksRecursive(senses, link, lang='jpn', _depth=0):
#  for sense in senses:
#    synLinks = getSynLinks(sense, link)
#    if synLinks:
#      print '  '*_depth + getWord(sense.wordid).lemma, getSynset(sense.synset).name
#    _senses = []
#    for synLink in synLinks:
#      sense = getSense(synLink.synset2, lang)
#      if sense:
#        _senses.append(sense)
#    getSynLinksRecursive(_senses, link, lang, _depth+1)
function getSynLinksRecursive(){
  local sense=$1;
  local link=$2;
  local lang="jpn";
  if [ -n "$3" ];then
    lang="$3";  
  fi
  local depth=$4;
  synLinks=`getSynLinks "$sense" "$link"`;
  if [ -z "$synLinks" ];then
    continue;
  fi
    local space="";
    for i in `seq 0 $depth`;do
      space="$space ";
    done
    local wordid=`echo "$sense"|awk -F\| '{print $2;}'`;
    local lemma=`getWord "$wordid"|awk -F\| '{print $3;}'`;
    local synset=`echo "$sense"|awk -F\| '{print $1;}'`;
    local name=`getSynset "$synset"|awk -F\| '{print $3;}'`
    echo "$space$lemma $name";
  _senses=`echo "$synLinks"|awk -F\| '{print $2;}'|while read synset2;do
    getSense "$synset2" "$lang";
    
  done|grep -v ^$`;
  depth=$(($depth + 1));
  echo "$_senses"|while read _sense;do
    getSynLinksRecursive "$_sense" "$searchlink" "$searchlang" "$depth"; 
  done
}
main2(){
  words=`getWords "$searchword"|awk -F\| '{print $1;}'`;
  if [ -n "$words" ];then
    getSenses "$words"|while read sense;do
      getSynLinksRecursive "$sense" "$searchlink" "$searchlang" "0";
    done
  fi
}
main2;
#main;
exit;
