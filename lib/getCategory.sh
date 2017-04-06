
# 日本語
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
:
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

