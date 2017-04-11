#!/bin/bash

DB="wnjpn.db";

main(){
	searchword="$1";														# 検索ワード
	lang="jpn";																	# 言語属性
  if [ -n "$2" ];then lang="$2";  fi

	# 検索語からシノニムを取得
  word=$( echo "$searchword" | sed -e "s| |_|g" );
	wordID=$( sqlite3 "$DB" "SELECT wordid 
						FROM word 
						WHERE lemma = '$word' 
						AND pos = 'n'
						AND lang  = '$lang'") ;
	echo "wordID: $wordID";
  SYNONYM=$( sqlite3 "$DB" "SELECT lemma 
						FROM word 
						JOIN wordlink ON 
						word.wordid = wordlink.wordid2 
						WHERE wordid1 = '$wordID'  
						AND link = 'syns'" );
	echo "SYNONYM : $SYNONYM" ;

	# 検索語からSYNSETSを取得
  SYNSETS=$( sqlite3 "$DB" "SELECT synset
						FROM word LEFT 
						JOIN sense ON 
						word.wordid = sense.wordid  
						WHERE lemma = '$searchword' 
						AND sense.lang = '$lang'" );
	echo "SYNSETS :$SYNSETS" | tr '\n' ',' | sed -e "s/$/\n/g";

  #SYNSETSからキーワードを取得する
  echo "$SYNSETS" | head -n1 | while read id; do
		WORD_J=$( sqlite3 "$DB" "SELECT lemma 
							FROM word  
							JOIN sense ON  
							word.wordid = sense.wordid  
							WHERE synset ='$id'  
							AND sense.lang = '$lang'" );
		WORD_E=$( sqlite3 "$DB" "SELECT lemma 
							FROM word  
							JOIN sense ON  
							word.wordid = sense.wordid  
							WHERE synset ='$id'  
							AND sense.lang = 'eng'" );
		echo "  WORD_J : `echo $WORD_J | tr '\n' ',' | sed -e "s/$/\n/g"`" ;
		echo "  WORD_E : `echo $WORD_E | tr '\n' ',' | sed -e "s/$/\n/g"`" ;

		#IDから定義文を取得する
		TEIGI_J=$( sqlite3 "$DB" "SELECT sid, def 
							FROM synset_def 
							WHERE synset = '$id' 
							AND lang   = '$lang'" ) ;
		TEIGI_E=$( sqlite3 "$DB" "SELECT sid, def 
							FROM synset_def 
							WHERE synset = '$id' 
							AND lang   = 'eng'" ) ;
		echo " TEIGI_J : $TEIGI_J" ;
		echo " TEIGI_E : $TEIGI_E";	

		#IDから例文を取得する
		REIBUN_J=$( sqlite3 "$DB" "SELECT sid, def 
							FROM synset_ex 
							WHERE synset = '$id' 
							AND lang   = '$lang'" );
		REIBUN_E=$( sqlite3 "$DB" "SELECT sid, def 
							FROM synset_ex 
							WHERE synset = '$id' 
							AND lang   = 'eng'" );
		echo "REIBUN_J : $REIBUN_J";
		echo "REIBUN_E : $REIBUN_E";

		#IDから品詞を取得する
		HINSHI_J=$( sqlite3 "$DB" "SELECT sid, def 
							FROM synset_def 
							WHERE synset = '$id' 
							AND lang   = '$lang'" );
		HINSHI_E=$( sqlite3 "$DB" "SELECT sid, def 
							FROM synset_def 
							WHERE synset = '$id' 
							AND lang   = 'eng'" );
		echo "HINSHI_J : $HINSHI_J" ;
		echo "HINSHI_E : $HINSHI_E" ;

		#IDからRelを取得する
		JOUIGO=$( sqlite3 "$DB" "SELECT synset2 
							FROM synlink 
							WHERE synset1 = '$id' 
							AND link = 'hype'" | while read line2; do 
				JOUIGO_J=$(sqlite3 "$DB" "SELECT lemma 
							FROM word JOIN sense ON  
							word.wordid = sense.wordid 
							WHERE synset = '$line2' 
							AND sense.lang = '$lang'" );
				JOUIGO_E=$(sqlite3 "$DB" "SELECT lemma 
							FROM word JOIN sense ON
							word.wordid = sense.wordid 
							WHERE synset = '$line2'  
							AND sense.lang = 'eng'"  );
				echo "$JOUIGO_J" ;
				echo "$JOUIGO_E" ;
			done
		);
		echo "  JOUIGO : $JOUIGO"  | tr '\n' ',' | sed -e "s/$/\n/g";
		#relから下位語を取得する
		KAIGO=$( sqlite3 "$DB" "SELECT synset2 
							FROM synlink 
							WHERE synset1 = '$id'
							AND link = 'hypo'" | while read line3; do
				KAIGO_J=$(sqlite3 "$DB"  "SELECT lemma 
							FROM word JOIN sense ON 
							word.wordid = sense.wordid 
							WHERE synset = '$line3'  
							AND sense.lang = '$lang'" );
				KAIGO_E=$(sqlite3 "$DB" "SELECT lemma 
							FROM word JOIN sense ON  
							word.wordid = sense.wordid 
							WHERE synset = '$line3' 
							AND sense.lang = 'eng'" );
				echo "$KAIGO_J" ;
				echo "$KAIGO_E" ;
			done
		);
		echo "   KAIGO : $KAIGO"  | tr '\n' ',' | sed -e "s/$/\n/g";
	done
}
<<<<<<< HEAD:lib/wnquery.sh
#
main "$1";
=======
main2;
#main;
>>>>>>> d23b3ca4c67f118c87fc15d3c6c4fd1fdab0353b:lib/Archive/wnquery.sh
exit;



##わーどネット sqlite3メソッド
#searchword=$1;
##
##DB="wnjpn-1.1_and_synonyms-1.0.db";
#DB="wnjpn.db";
#
#function Synonym(){
#  local wordid="$1";
#  rst=`sqlite3 "$DB" "SELECT lemma FROM word JOIN wordlink ON word.wordid = wordlink.wordid2
#              WHERE wordid1 = '$wordid' 
#                AND link    = 'syns'"`;
#  echo "$rst";
#}
#function WordID(){
#  local word="$1";
#  word=`echo "$word"|sed -e "s| |_|g"`;
#  local pos="$2";
#  local lang="jpn";
#  if [ -n "$3" ];then
#    lang="$3";  
#  fi
#  rst=`sqlite3 "$DB" "SELECT wordid FROM word
#              WHERE lemma = '$word' 
#                AND pos   = '$pos'
#                AND lang  = '$lang'"`;
#  echo "$rst";
#}
#function Rel(){
#  local synset="$1";
#  local rel="$2";
#  rst=`sqlite3 "$DB" "SELECT synset2 FROM synlink
#              WHERE synset1 = '$synset' 
#                AND link    = '$rel'"`;
#  echo "$rst";
#}
#function Pos(){
#  local synset="$1";
#  rst=`sqlite3 "$DB" "SELECT sid, def FROM synset_def
#              WHERE synset = '$synset'
#                AND lang   = '$lang'"`;
#  echo "$rst";
#}
#function SynPos(){
#  local word="$1";
#  local pos="$2";
#  local lang="jpn";
#  if [ -n "$3" ];then
#    lang="$3";  
#  fi
#  rst=`sqlite3 "$DB" "SELECT synset FROM word LEFT JOIN sense ON word.wordid = sense.wordid
#              WHERE lemma      = '$word' 
#                AND word.pos   = '$pos'  
#                AND sense.lang = '$lang'"`;
#  echo "$rst";
#}
##
#function Ex(){
#  local synset="$1";
#  local lang="jpn";
#  if [ -n "$2" ];then
#    lang="$2";  
#  fi
#  rst=`sqlite3 "$DB" "SELECT sid, def FROM synset_ex
#              WHERE synset = '$synset' 
#                AND lang   = '$lang'"`;
#  echo "$rst";
#}
#function Def(){
#  local synset="$1";
#  local lang="jpn";
#  if [ -n "$2" ];then
#    lang="$2";  
#  fi
#  rst=`sqlite3 "$DB" "SELECT sid, def FROM synset_def
#              WHERE synset = '$synset'
#                AND lang   = '$lang'"`;
#  echo "$rst";
#}
#function Word(){
#  local word="$1";
#  local lang="jpn";
#  if [ -n "$2" ];then
#    lang="$2";  
#  fi
#  rst=`sqlite3 "$DB" "SELECT lemma FROM word JOIN sense ON word.wordid = sense.wordid WHERE synset     ='$word' AND sense.lang = '$lang'"`;
#  echo "$rst";
#}
#function Synset(){
#  local word="$1";
#  local lang="jpn";
#  if [ -n "$2" ];then
#    lang="$2";  
#  fi
#  rst=`sqlite3 "$DB" "SELECT synset FROM word LEFT JOIN sense ON word.wordid = sense.wordid WHERE lemma = '$word' AND sense.lang = '$lang'"`;
#  echo "$rst";
#}
#
#main(){
#  #キーワードのIDを取得する
#  echo "##################";
#  echo "検索ワード:$searchword";
#  synsets=`Synset "$searchword"` ;
#echo "synsets :"
#echo "$synsets" ;
##00001740-n
##04867130-n
##02179279-a
##02465519-a
##00958880-a
#
#  #IDから品詞を取得する
#  #$pos can take the left side values of the following table.
#  #
#  #  a|adjective
#  #  r|adverb
#  #  n|noun
#  #  v|verb
#  #  a|形容詞
#  #  r|副詞
#  #  n|名詞
#  #  v|動詞
#  #SynPos "$searchword"  "$pos";
#  echo "$synsets" | head -n1 |while read line;do
#  echo "##################";
#    echo "id:$line";
#  #IDからキーワードを取得する
#    Word "$line";
#  #IDから定義文を取得する
#    Def "$line";
#  #IDから例文を取得する
#    Ex "$line";
#  #IDから品詞を取得する
#    Pos "$line";
#  #IDからRelを取得する
#    echo "【上位語】";
#    Rel "$line" "hype"|while read line2;do
#        re=`Word "$line2";`
#        if [ -n "$re" ];then
#          echo "$re";
#        else
#          Word "$line2" "eng";
#        fi  
#    done;
#    echo "【下位語】";
#    Rel "$line" "hypo"|while read line2;do
#        re=`Word "$line2";`
#        if [ -n "$re" ];then
#          echo "$re";
#        else
#          Word "$line2" "eng";
#        fi  
#    done;
#
#  echo "##################";
#  done;  
##  wordID=`WordID "$searchword" "n"`;
##  echo "【シノニム】";
##  Synonym "$wordID";
#  echo "##################";
#}
#main;
#exit;
#
##
