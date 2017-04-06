
# 日本語
function getCategory(){
  local DIC="$1" TAG="$2" ;
  l=$(echo "$KEYS_RESULT_LINE"|sed -e "s/<KEYS>//g" -e "s/<\/KEYS>//g" -e "s/<KEY>//g" -e "s/<\/KEY>/\n/g" -e "s/<SCORE>/:/g" -e "s/<\/SCORE>//g"); 
  hn=$(echo "$l"|head -n1|awk -F: '{ print $2; }');
  tn=$(echo "$l"|tail -n1|awk -F: '{ print $2; }') ;
  av=$(echo "$hn" "$tn"|awk '{ print ($1+$2)/2; }') ;
#  echo "###average : $av" ;
  kw=$(echo "$l"|awk -F: '{ if($2> '"$av"'){ print $1; } }');
  kwl=$(echo "$l"|awk -F: '{ print $1; }');
  wcl=$(echo "$l" |wc -l|awk '{ print $1; }') ;
  wc=$(echo "$kw"|wc -l|awk '{ print $1; }') ;
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
            echo "<SIM>$rl</SIM>" ; break ;  
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
            echo "<SIM>$rl</SIM>" ; break ;  
        }
      done );
      
#      | \
#            sed -e "s/^.*<CATE>//g" -e "s/<\/CATE>.*$//g"| \
#            sort|uniq -c|sort -nr| \
#            head -n1|awk '{ print $2;}'| \
#            sed -e "s/^/<CATEGORY>/g" -e "s/$/<\/CATEGORY>/g");
}

