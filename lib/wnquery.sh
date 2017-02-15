#!/bin/bash

DB="wnjpn.db";

main(){
	searchword="$1";														# 検索ワード
	lang="jpn";																	# 言語属性
  if [ -n "$2" ];then lang="$2";  fi

	# 検索語からシノニムを取得
  word=$( echo "$searchword" | sed -e "s| |_|g" );
  wordID=$( sqlite3 "$DB"  \
							"SELECT wordid FROM word
              	WHERE lemma = '$word' 
              	AND pos   = 'n'
              	AND lang  = '$lang'") ;
  SYNONYM=$( sqlite3 "$DB"  \
							"SELECT lemma FROM word JOIN wordlink ON \
								word.wordid = wordlink.wordid2
              	WHERE wordid1 = '$wordID' 
              	AND link = 'syns'" );
	echo "SYNONYM : $SYNONYM" ;

	# 検索語からSYNSETSを取得
  SYNSETS=$( sqlite3 "$DB"  \
					"SELECT synset FROM word LEFT JOIN sense ON  \
						word.wordid = sense.wordid  \
						WHERE lemma = '$searchword'  \
						AND sense.lang = '$lang'" );
	echo "SYNSETS :$SYNSETS" ;

  #SYNSETSからキーワードを取得する
  echo "$SYNSETS" | head -n1 | while read id; do
	WORD=$( sqlite3 "$DB"  \
						"SELECT lemma FROM word JOIN sense ON  \
							word.wordid = sense.wordid  \
							WHERE synset ='$id'  \
							AND sense.lang = '$lang'" );
	echo "WORD : $WORD"

  #IDから定義文を取得する
  TEIGI=$( sqlite3 "$DB"  \
						"SELECT sid, def FROM synset_def \
            	WHERE synset = '$id' \
            	AND lang   = '$lang'" ) ;
	echo "TEIGI : $TEIGI";	

  #IDから例文を取得する
  REIBUN=$( sqlite3 "$DB"  \
							"SELECT sid, def FROM synset_ex \
              	WHERE synset = '$id' \
                AND lang   = '$lang'" );
	echo "REIBUN : $REIBUN";

  #IDから品詞を取得する
  HINSHI=$( sqlite3 "$DB"  \
							"SELECT sid, def FROM synset_def \
              	WHERE synset = '$id' \
                AND lang   = '$lang'" );
	echo "HINSHI : $HINSHI" ;

  #IDからRelを取得する
  JOUIGO=$( sqlite3 "$DB" "SELECT synset2 FROM synlink \
              WHERE synset1 = '$id'  \
               AND link = hype" |  \
    #relから上位語を取得する
		while read line2; do 
			re= $(sqlite3 "$DB"  \
						"SELECT lemma FROM word JOIN sense ON  \
							word.wordid = sense.wordid WHERE  \
							synset = '$line2'  \
							AND sense.lang = '$lang'" ) ;
			if [ -n "$re" ];then
				echo "$re";
			else
				re= $(sqlite3 "$DB"  \
							"SELECT lemma FROM word JOIN sense ON  \
								word.wordid = sense.wordid WHERE  \
								synset = '$line2'  \
								AND sense.lang = eng" ) ;
				echo "$re" ;
			fi  
		done
	);

  #relから下位語を取得する
  KAIGO=$( sqlite3 "$DB" "SELECT synset2 FROM synlink \
              WHERE synset1 = '$id'  \
               AND link    = hypo" |  \
		while read line2; do 
			re= $(sqlite3 "$DB"  \
						"SELECT lemma FROM word JOIN sense ON  \
							word.wordid = sense.wordid WHERE  \
							synset = '$line2'  \
							AND sense.lang = '$lang'" ) ;
			if [ -n "$re" ];then
				echo "$re";
			else
				sqlite3 "$DB"  \
							"SELECT lemma FROM word JOIN sense ON  \
								word.wordid = sense.wordid WHERE  \
								synset = '$line2'  \
								AND sense.lang = eng" ;
			fi  
		done
	);
	done
}
#
main "$1";
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
