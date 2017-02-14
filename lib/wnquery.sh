#!/bin/bash
#わーどネット sqlite3メソッド
searchword=$1;
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
  local word="$1";
  local lang="jpn";
  if [ -n "$2" ];then
    lang="$2";  
  fi
  rst=`sqlite3 "$DB" "SELECT lemma FROM word JOIN sense ON word.wordid = sense.wordid
              WHERE synset     ='$word' 
                AND sense.lang = '$lang'"`;
  echo "$rst";
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

main(){
  #キーワードのIDを取得する
  echo "##################";
  echo "検索ワード:$searchword";
  synsets=`Synset "$searchword"` ;
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
        Word "$line2";
    done;
    echo "【下位語】";
    Rel "$line" "hypo"|while read line2;do
        Word "$line2";
    done;

  echo "##################";
  done;  
#  wordID=`WordID "$searchword" "n"`;
#  echo "【シノニム】";
#  Synonym "$wordID";
  echo "##################";
}
main;
exit;
