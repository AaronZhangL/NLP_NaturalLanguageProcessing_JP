#!/bin/bash
##にほんごごい体系のフォルダを作成する
GOITAIKEI="../lib/GOITAIKEI2";
WNDB="../lib/wnjpn.db";
##
#
function getWord(){
  local wordid="$1";
  rst=`sqlite3 "$WNDB" "select * from word where wordid='$wordid'"`;
  echo "$rst";
}
function getSense(){
  local rst="" synset="$1" lang="jpn" lang= wordid=$3 ; 
  [[ -n "$2" ]] && local lang="$2"; 
	cC=0
	while [ -z "$rst" ]; do
		case "$cC" in
			0) rst=$(sqlite3 "$WNDB" "select * from sense where synset='$1' and lang='$lang' and wordid='$3'") ;;
			1) rst=$(sqlite3 "$WNDB" "select * from sense where synset='$1' and lang='$lang'") ;;
			2) rst=$(sqlite3 "$WNDB" "select * from sense where synset='$1' and lang='eng'") ;;
			3) synset=$(echo "$synset"|sed -e "s|-n||")
    		 rst=$(sqlite3 "$WNDB" "select * from sense where synset like '$1-%' and lang='$lang'") ;;
			4) rst=$(sqlite3 "$WNDB" "select * from sense where synset like '$1-%' and lang='eng'") ;;
			*) break ;;
		esac
		((cC++));
	done
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

  if [ -z "$rst" ];then
    rst=`sqlite3 "$WNDB" "select * from synlink where synset1='$synset' and link in ('caus','also')"|head -n1`;
    local p=$(echo "$rst"awk -F\| '{print $2;}'|sed -e "s|-.*||"); 
    if echo "$path"|grep "WN${p}" > /dev/null;then
      rst="";
    fi
  fi

  if [ -z "$rst" ];then
    rst=`sqlite3 "$WNDB" "select * from synlink where synset1='$synset' and link in ('inst','sim')"|head -n1`;
    local p=$(echo "$rst"awk -F\| '{print $2;}'|sed -e "s|-.*||"); 
    if echo "$path"|grep "WN${p}" > /dev/null;then
      rst="";
    fi
  fi

  echo "$rst";
}

function getSynLinksRecursive(){
  local sense=$1 sl=$2 lg="";
  [[ -n "$3" ]]&&{ lg="$3" ;};
  local depth=$4;
  synLinks=$(getSynLinks "$sense" "$sl");
  local synset=$( echo "$sense"|awk -F\| '{print $1;}'|sed -e "s|-.*||" );
  echo "WN$synset"
  path="${path}WN${synset}"
  senses=$(echo "$synLinks"|head -n1|awk -F\| '{print $2;}'| \
    while read synset2;do
      getSense "$synset2" "$lang";
    done|grep -v "^$");
  ((depth++));
  [[ -z "$synLinks" ]] && break ;
  echo "$senses"|head -n1| \
    while read sense;do
      getSynLinksRecursive "$sense" "$sl" "$lg" "$depth"; 
    done
}
##
#
function mkwn(){
  sl="hype" lg="" C=0;
  WC=$( sqlite3 "$WNDB" "select * from sense" | wc -l | awk '{ print $1; }' );
  if which tac >/dev/null ; then tac="tac" ; else tac="tail -r" ; fi
  sqlite3 "$WNDB" "select * from sense"| \
  while read ss;do  
    dr=$(getSynLinksRecursive "$ss" "$sl" "$lg" "0"| $tac |tr "\n" "/");
    [[ -z "$dr" ]] && { echo "$id:not親"; continue; } 
    local id=$(echo "$ss"|awk -F\| '{print $1;}');
    echo "$id" |grep "\-n" >/dev/null || { echo "$id:not名詞" ; continue; }
    se=$(sqlite3 "$WNDB" "SELECT * FROM word JOIN sense ON word.wordid = sense.wordid WHERE synset ='$id'");
    jg=$(echo "$se"|grep "jpn"|awk -F\| '{print $3;}'|tr "\n" " "); 
    fn=$(echo "$se"|grep "jpn"|awk -F\| '{print $3;}'|head -n1); 
    [[ -z "$fn" ]]&&{ fn=$(echo "$se"|grep "eng"|awk -F\| '{print $3;}'|head -n1);} 
    eg=$(echo "$se"|grep "eng"|awk -F\| '{print $3;}'|tr "\n" " "); 
    pr=$(echo "$dr"|awk -F/ '{print $(NF - 1)}');
    [[ ! -e "N/$dr" ]] && mkdir -p "WN/$dr";
    echo "<NO>$id</NO><GOI>$jg</GOI><ENGOI>$eg</ENGOI><OYA_NO>$pr</OYA_NO><KEIRO>$dr</KEIRO>" > "WN/${dr}WN${fn}";
    ((C++));
    echo "#C:$C/$WC" ;
  done
}
##
#
function mkgt(){
  C=0 WC=$( wc -l $GOITAIKEI | awk '{ print $1; }' );
  cat "$GOITAIKEI" | \
    while read l;do
      dr=$(echo "$l" | sed -e "s|^.*<KEIRO>||" -e "s|</KEIRO>.*$||"|sed -e "s|-|/|g");
      id=$(echo "$l" | sed -e "s|^.*<NO>||" -e "s|</NO>.*$||");
      GOI=$(echo "$l" | sed -e "s|^.*<GOI>||" -e "s|</GOI>.*$||");
      [[ ! -e "$dr" ]] && mkdir -p "$dr";
      echo "$l">"$dr/GT$GOI";
      ((C++));
      echo "C:$C/$WC";
    done
}
##
#
function main(){
#  mkgt;
  mkwn;
}
#
main;
exit;



#function getSynLinksRecursive(){
#  local sense=$1;
#  local sl=$2;
#  local lg="";
#  if [ -n "$3" ];then
#    lg="$3";  
#  fi
#  local depth=$4;
#  synLinks=`getSynLinks "$sense" "$sl"`;
#    #local wordid=`echo "$sense"|awk -F\| '{print $2;}'`;
#    #local lemma=`getWord "$wordid"|awk -F\| '{print $3;}'`;
#    #local lemma=`echo "$sense"|awk -F\| '{print $7;}'`;
#    local synset=`echo "$sense"|awk -F\| '{print $1;}'|sed -e "s|-.*||"`;
#    #00452293-n|00452864-n|hypo|eng30|00452864-n|n|beagling|eng30
#    #echo "<sy>$synset</sy><jp>$lemma</jp><en>$name</en>";
#    echo "WN$synset"
#    path="${path}WN${synset}"
#    #echo "$space$lemma $name";
#  _senses=`echo "$synLinks"|head -n1|awk -F\| '{print $2;}'|while read synset2;do
#    getSense "$synset2" "$lang";
#    
#  done|grep -v ^$`;
#  depth=$(($depth + 1));
#  if [ -z "$synLinks" ];then
#    break;
#  fi
#  echo "$_senses"|head -n1|while read _sense;do
#    getSynLinksRecursive "$_sense" "$sl" "$lg" "$depth"; 
#  done
#}
#
#function mkwn(){
#  sl="hype";
#  lg="";
#  sqlite3 "$WNDB" "select * from sense"|while read ss;do  
#  #sqlite3 "$WNDB" "select * from sense where synset='01296505-n'"|while read ss;do  
#    echo "$ss";
#		if which tac >/dev/null ; then
#			tac="tac" ;
#		else
#			tac="tail -r" ;
#		fi
#    #親経路をたどる
#    #dr=$(getSynLinksRecursive "$ss" "$sl" "$lg" "0"| tail -r |tr "\n" "/");
#    path="";
#    dr=$(getSynLinksRecursive "$ss" "$sl" "$lg" "0"| $tac |tr "\n" "/");
#    echo "$dr";
#    if [ -z "$dr" ];then
#      echo "$id:親がないのでスキップ";
#      continue;
#    fi
#    #自身の情報を作る
#    local id=$(echo "$ss"|awk -F\| '{print $1;}');
#    #名詞以外はスキップする
#    if ! echo "$id" |grep "\-n" >/dev/null;then
#      echo "$id:名詞意外なのでスキップ"
#      continue;
#    fi
#    local se=$(sqlite3 "$WNDB" "SELECT * FROM word JOIN sense ON word.wordid = sense.wordid WHERE synset ='$id'");
#    local jg=$(echo "$se" |grep "jpn"|awk -F\| '{print $3;}'|tr "\n" " "); 
#    local fn=$(echo "$se" |grep "jpn"|awk -F\| '{print $3;}'|head -n1); 
#    if [ -z "$fn" ];then
#      fn=$(echo "$se" |grep "eng"|awk -F\| '{print $3;}'|head -n1); 
#    fi
#    local eg=$(echo "$se" |grep "eng"|awk -F\| '{print $3;}'|tr "\n" " "); 
#    #414|eng|suspension||n|14591091-n|414|eng|0|1|6|eng-30
#    #229141|jpn|懸濁液||n|14591091-n|229141|jpn||||hand
#    local pr=$(echo "$dr" |awk -F/ '{print $(NF - 1)}');
#    mkdir -p "WN/$dr";
#    echo "<NO>$id</NO><GOI>$jg</GOI><ENGOI>$eg</ENGOI><OYA_NO>$pr</OYA_NO><KEIRO>$dr</KEIRO>" > "WN/${dr}WN${fn}";
#    
#    #echo "$dr/$id";
#  done
#}
#function mkgt(){
#  cat "$GOITAIKEI" | while read l;do
#    #dr=$(echo "$l" | sed -e "s|^.*<KEIROJ>||" -e "s|</KEIROJ>.*$||"|sed -e "s|-|/|g");
#    dr=$(echo "$l" | sed -e "s|^.*<KEIRO>||" -e "s|</KEIRO>.*$||"|sed -e "s|-|/|g");
#    id=$(echo "$l" | sed -e "s|^.*<NO>||" -e "s|</NO>.*$||");
#    GOI=$(echo "$l" | sed -e "s|^.*<GOI>||" -e "s|</GOI>.*$||");
#    mkdir -p "$dr";
#    echo "$l"  > "$dr/GT$GOI";
#  done
#}
#function main(){
##  mkgt;
#  mkwn;
#}
#
#
#main;
#exit;
