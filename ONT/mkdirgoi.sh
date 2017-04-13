#!/bin/bash
#にほんごごい体系のフォルダを作成する
GOITAIKEI="../lib/GOITAIKEI2";
WNDB="../lib/wnjpn.db";
function getWord(){
  local wordid="$1";
  rst=`sqlite3 "$WNDB" "select * from word where wordid='$wordid'"`;
  echo "$rst";
}
function getSense(){
  local rst="";
  local synset="$1";
  local lang="jpn";
  if [ -n "$2" ];then
    lang="$2";  
  fi
  if [ -n "$3" ];then
    local wordid="$3";
    rst=`sqlite3 "$WNDB" "select * from sense where synset='${synset}' and lang='$lang' and wordid='$wordid'"`;
  fi
  if [ -z "$rst" ];then
    rst=`sqlite3 "$WNDB" "select * from sense where synset='${synset}' and lang='$lang'"`;
  fi
  if [ -z "$rst" ];then
    rst=`sqlite3 "$WNDB" "select * from sense where synset='${synset}' and lang='eng'"`;
  fi
  
  if [ -z "$rst" ];then
    synset=`echo "$synset"|sed -e "s|-n||"`;
    rst=`sqlite3 "$WNDB" "select * from sense where synset like '${synset}-%' and lang='$lang'"`;
  fi
  if [ -z "$rst" ];then
    rst=`sqlite3 "$WNDB" "select * from sense where synset like '${synset}-%' and lang='eng'"`;
  fi
  echo "$rst";
}
function  getSynLinks(){
  local sense="$1";
  local synset=`echo "$sense"|awk -F\| '{print $1;}'`
  local link="$2";
  rst=`sqlite3 "$WNDB" "select * from synlink where synset1='$synset' and link='$link'"|head -n1`;
  if [ -z "$rst" ];then
    rst=`sqlite3 "$WNDB" "select * from synlink where synset1='$synset' and link in ('hprt','hmem','hsub','dmnc','dmtr')"|head -n1`;
  fi
  #if [ -z "$rst" ];then
  #  rst=`sqlite3 "$WNDB" "select * from synlink where synset1='$synset' and link in ('inst','caus','also','sim')"|head -n1`;
# #   #echo "#####$rst####"
  #fi
  #rst=`sqlite3 "$DB" "SELECT * FROM synlink LEFT JOIN synset ON synlink.synset2 = synset.synset synset1='$synset' and link='$link';"`;
  echo "$rst";
}
function getSynLinksRecursive(){
  local sense=$1;
  local sl=$2;
  local lg="";
  if [ -n "$3" ];then
    lg="$3";  
  fi
  local depth=$4;
  synLinks=`getSynLinks "$sense" "$sl"`;
    #local wordid=`echo "$sense"|awk -F\| '{print $2;}'`;
    #local lemma=`getWord "$wordid"|awk -F\| '{print $3;}'`;
    #local lemma=`echo "$sense"|awk -F\| '{print $7;}'`;
    local synset=`echo "$sense"|awk -F\| '{print $1;}'|sed -e "s|-.*||"`;
    #00452293-n|00452864-n|hypo|eng30|00452864-n|n|beagling|eng30
    #echo "<sy>$synset</sy><jp>$lemma</jp><en>$name</en>";
    echo "WN$synset"
    #echo "$space$lemma $name";
  _senses=`echo "$synLinks"|head -n1|awk -F\| '{print $2;}'|while read synset2;do
    getSense "$synset2" "$lang";
    
  done|grep -v ^$`;
  depth=$(($depth + 1));
  if [ -z "$synLinks" ];then
    break;
  fi
  echo "$_senses"|head -n1|while read _sense;do
    getSynLinksRecursive "$_sense" "$sl" "$lg" "$depth"; 
  done
}

function mkwn(){
  sl="hype";
  lg="";
  #sqlite3 "$WNDB" "select * from sense"|while read ss;do  
  sqlite3 "$WNDB" "select * from sense where synset='01296505-n'"|while read ss;do  
    echo "$ss";
		if which tac >/dev/null ; then
			tac="tac" ;
		else
			tac="tail -r" ;
		fi
    #親経路をたどる
    #dr=$(getSynLinksRecursive "$ss" "$sl" "$lg" "0"| tail -r |tr "\n" "/");
    dr=$(getSynLinksRecursive "$ss" "$sl" "$lg" "0"| $tac |tr "\n" "/");
    echo "$dr";
    if [ -z "$dr" ];then
      echo "$id:親がないのでスキップ";
      continue;
    fi
    #自身の情報を作る
    local id=$(echo "$ss"|awk -F\| '{print $1;}');
    #名詞以外はスキップする
    if ! echo "$id" |grep "\-n" >/dev/null;then
      echo "$id:名詞意外なのでスキップ"
      continue;
    fi
    local se=$(sqlite3 "$WNDB" "SELECT * FROM word JOIN sense ON word.wordid = sense.wordid WHERE synset ='$id'");
    local jg=$(echo "$se" |grep "jpn"|awk -F\| '{print $3;}'|tr "\n" " "); 
    local fn=$(echo "$se" |grep "jpn"|awk -F\| '{print $3;}'|head -n1); 
    if [ -z "$fn" ];then
      fn=$(echo "$se" |grep "eng"|awk -F\| '{print $3;}'|head -n1); 
    fi
    local eg=$(echo "$se" |grep "eng"|awk -F\| '{print $3;}'|tr "\n" " "); 
    #414|eng|suspension||n|14591091-n|414|eng|0|1|6|eng-30
    #229141|jpn|懸濁液||n|14591091-n|229141|jpn||||hand
    local pr=$(echo "$dr" |awk -F/ '{print $(NF - 1)}');
    mkdir -p "WN/$dr";
    echo "<NO>$id</NO><GOI>$jg</GOI><ENGOI>$eg</ENGOI><OYA_NO>$pr</OYA_NO><KEIRO>$dr</KEIRO>" > "WN/${dr}WN${fn}";
    
    #echo "$dr/$id";
  done
}
function mkgt(){
  cat "$GOITAIKEI" | while read l;do
    #dr=$(echo "$l" | sed -e "s|^.*<KEIROJ>||" -e "s|</KEIROJ>.*$||"|sed -e "s|-|/|g");
    dr=$(echo "$l" | sed -e "s|^.*<KEIRO>||" -e "s|</KEIRO>.*$||"|sed -e "s|-|/|g");
    id=$(echo "$l" | sed -e "s|^.*<NO>||" -e "s|</NO>.*$||");
    GOI=$(echo "$l" | sed -e "s|^.*<GOI>||" -e "s|</GOI>.*$||");
    mkdir -p "$dr";
    echo "$l"  > "$dr/GT$GOI";
  done
}
function main(){
#  mkgt;
  mkwn;
}


main;
exit;
