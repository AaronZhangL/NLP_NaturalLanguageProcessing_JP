
# 日本語
function  getSynLinks(){
  local sense="$1";
  local synset=`echo "$sense"|awk -F\| '{print $1;}'`
  local link="$2";
  rst=`sqlite3 "$DB" "select * from synlink where synset1='$synset' and link='$link'"`;
  echo "$rst";
}
function getSynset(){
  local synset="$1";
  rst=`sqlite3 "$DB" "select * from synset where synset='$synset'"`;
  echo "$rst";
}
function getSynLinksRecursive(){
  local sense=$1;
  local link=$2;
  local lang="jpn";
  if [ -n "$3" ];then
    lang="$3";  
  fi
  local depth=$4;
  synLinks=`getSynLinks "$sense" "$link"`;
  #echo "sense:$sense link :$link synLinks:$synLinks";
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
    #echo "<sy>$synset</sy><jp>$lemma</jp><en>$name</en>";
    echo "$lemma";
    #echo "$space$lemma $name";
  _senses=`echo "$synLinks"|head -n1|awk -F\| '{print $2;}'|while read synset2;do
    getSense "$synset2" "$lang";
    
  done|grep -v ^$`;
  depth=$(($depth + 1));
  echo "$_senses"|head -n1|while read _sense;do
    getSynLinksRecursive "$_sense" "$sl" "$lg" "$depth"; 
  done
}
function getWord(){
  local wordid="$1";
  rst=`sqlite3 "$DB" "select * from word where wordid='$wordid'"`;
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
    rst=`sqlite3 "$DB" "select * from sense where synset='${synset}' and lang='$lang' and wordid='$wordid'"`;
  fi
  if [ -z "$rst" ];then
    rst=`sqlite3 "$DB" "select * from sense where synset='${synset}' and lang='$lang'"`;
  fi
  if [ -z "$rst" ];then
    rst=`sqlite3 "$DB" "select * from sense where synset='${synset}' and lang='eng'"`;
  fi
  
  if [ -z "$rst" ];then
    synset=`echo "$synset"|sed -e "s|-n||"`;
    rst=`sqlite3 "$DB" "select * from sense where synset like '${synset}-%' and lang='$lang'"`;
  fi
  if [ -z "$rst" ];then
    rst=`sqlite3 "$DB" "select * from sense where synset like '${synset}-%' and lang='eng'"`;
  fi
  echo "$rst";
}
function wnquery_byid(){
  sw=$1;
  sl=$2;
  lg=$3;
  DB="lib/$DIC";
  wt=`sqlite3 "lib/wnjpn.db" "SELECT * FROM word LEFT JOIN sense ON word.wordid = sense.wordid WHERE lemma = '$sw' AND word.pos = 'n' AND sense.lang = '$lg'"|head -n 1`;
#179412|jpn|大学||n|08278324-n|179412|jpn||||hand
  [[ -z "$wt" ]] && {
    break;
  }||{
    wd=`echo "$wt"|awk -F\| '{print $3;}'`;
    si=$(echo "$wt" | awk -F\| '{print $6}');
    #228553|jpn|野球||n
    #00476140-n|44534|eng|0|1|0|eng-30
    getSense "$si" "$lg" "$wd"|head -n1|while read ss;do
      getSynLinksRecursive "$ss" "$sl" "$lg" "0";
    done
  }
}
function getCategoryNP(){
  local DIC="$1" TAG="$2" ;
  f=0;
  NPCATEGORY_RESULT_LINE=$(echo "$kwl" | tr ' ' '\n' | \
      while read l; do 
#        echo "#### $l #####" ;
        ((c==0))&&{ 
          rl=$(sary "$l" lib/"$DIC");
#echo "$rl" | grep -v "^$" | wc -l  ;exit ;
        }||{ 
          rl_t=$(echo "$rl"|fgrep "$l"); 
#echo "$rl_t" | grep -v "^$" | wc -l ; exit ;
#          echo "$rl_t" | grep -v "^$" | wc -l ;
          [[ -z "$rl_t" ]] && {
#            echo "#### hajikare "
            ((f==0)) && {
              echo "$rl" | \
              sed -e "s/^.*<CATE>//g" -e "s/<\/CATE>.*$//g"| \
              sort|uniq -c|sort -nr| \
              head -n1|awk '{ print $2;}'| \
              sed -e "s/^/<$TAG>/g" -e "s/$/<\/$TAG>/g" ;
            }
            echo "<SIM>$( echo "$rl" | head -n1)</SIM>" ; break ;  
          }||{
            rl="$rl_t";
          }
        }
        ((c++)); 
#((c==wc))&&{ echo "$rl"; }
        ((c==wc))&&{ 
            echo "$rl" | \
            sed -e "s/^.*<CATE>//g" -e "s/<\/CATE>.*$//g"| \
            sort|uniq -c|sort -nr| \
            head -n1|awk '{ print $2;}'| \
            sed -e "s/^/<$TAG>/g" -e "s/$/<\/$TAG>/g" ;
            f=1;
        }
        ((c==wcl))&&{
            echo "<SIM>$( echo "$rl" | head -n1)</SIM>" ; break ;  
        }
      done );
}
function getCategoryGT(){
    #GTCATEGORY_RESULT_LINE=$(echo "$kwl" | tr ' ' '\n' | \
    #GTCATEGORY_RESULT_LINE=$( echo "$TITLE_KEYS_RESULT_LINE" | sed -e "s/<\/KEY>/\n/g" -e "s/<KEY>//g" -e "s/<\/KEY>//g" -e "s/<SCORE>[^<]*<\/SCORE>//g" | grep -v "^$" | nkf -e | mecab -Owakati | nkf -w | tr ' ' '\n' | grep -v "^$" |  \
    GTCATEGORY_RESULT_LINE=$( echo "$kwl" | nkf -e | mecab -Owakati | nkf -w | tr ' ' '\n' | grep -v "^$" | grep -v '^...$' | \
    while read l; do 
#   echo "####l $l #####" ;
        rl=$(sary "$l" lib/"$DIC");
#   echo "####rl#$rl" ;
      [[ -z "$rl" ]]&&{
        :
      }||{
          echo "$rl" | \
          sed -e "s/^.*<KEIROJ>//g" -e "s/<\/KEIROJ>.*$//g"| \
          sort|uniq -c|sort -nr| \
          head -n1|awk '{ print $2;}'| \
          sed -e "s/^/<$TAG>/g" -e "s/$/<\/$TAG>/g" ;
          #break ;
      }
    done | sort | uniq -c | sort -nr | awk '{ print $2; }' | head -n5;
    );
}
function getCategoryWN(){
    #echo "$kwl" | nkf -e | mecab -Owakati | nkf -w | tr ' ' '\n' | grep -v "^$" | grep -v '^...$' | \
    WNCATEGORY_RESULT_LINE=$( echo "$kwl" | nkf -e | mecab -Owakati | nkf -w | tr ' ' '\n' | grep -v "^$" | grep -v '^...$' | \
      while read l; do 
   #echo "$DIC"
   #echo "#RRR###l $l  #####" ;
        rl=$(wnquery_byid "$l" "hype" "jpn");
   #echo "####rl#$rl" ;
      [[ -z "$rl" ]]&&{
        :
      }||{
          echo "$rl" | \
          tail -r | \
          tr "\n" "-" | \
          sed -e "s/^/<$TAG>/g" -e "s/-$/<\/$TAG>\n/g" ;
          #break ;
      }
    done | sort | uniq -c | sort -nr | awk '{print $2;}' |head -n5;
    );
}
function getCategory(){
  local DIC="$1" TAG="$2" ;
  l=$(echo "$KEYS_RESULT_LINE"|sed -e "s/<KEYS>//g" -e "s/<\/KEYS>//g" -e "s/<KEY>//g" -e "s/<\/KEY>/\n/g" -e "s/<SCORE>/:/g" -e "s/<\/SCORE>//g"); 
  hn=$(echo "$l"|head -n1|awk -F: '{ print $2; }');
  tn=$(echo "$l"|tail -n1|awk -F: '{ print $2; }') ;
  av=$(echo "$hn" "$tn"|awk '{ print ($1+$2)/2; }') ;
  kw=$(echo "$l"|awk -F: '{ if($2> '"$av"'){ print $1; } }');
  kwl=$(echo "$l"|awk -F: '{ print $1; }');
  wcl=$(echo "$l" |wc -l|awk '{ print $1; }') ;
  wc=$(echo "$kw"|wc -l|awk '{ print $1; }') ;
  case $DIC in
    NEWSPACKDB2) getCategoryNP "$DIC" "$TAG" ;
              ;;
    GOITAIKEI2)  getCategoryGT "$DIC" "$TAG" ;
              ;;
    wnjpn.db)    getCategoryWN "$DIC" "$TAG" ;
              ;;
    *)  
              ;;
  esac
}

