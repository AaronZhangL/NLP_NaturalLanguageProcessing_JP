
function getCategory(){
  l=$(echo "$KEYS_RESULT_LINE"|sed -e "s/<KEYS>//g" -e "s/<\/KEYS>//g" -e "s/<KEY>//g" -e "s/<\/KEY>/\n/g" -e "s/<SCORE>/:/g" -e "s/<\/SCORE>//g"); 
  hn=$(echo "$l"|head -n1|awk -F: '{ print $2; }');
  tn=$(echo "$l"|tail -n1|awk -F: '{ print $2; }') ;
  av=$(echo "$hn" "$tn"|awk '{ print ($1+$2)/2; }') ;
  kw=$(echo "$l"|awk -F: '{ if($2> '"$av"'){ print $1; } }');
  kwl=$(echo "$l"|awk -F: '{ print $1; }');
  wcl=$(echo "$l" |wc -l|awk '{ print $1; }') ;
  wc=$(echo "$kw"|wc -l|awk '{ print $1; }') ;
  NPCATEGORY_RESULT_LINE=$(echo "$kwl" | tr ' ' '\n' | \
      while read l; do 
        ((c==0))&&{ 
          rl=$(sary "$l" lib/NEWSPACKDB2);
        }||{ 
          rl_t=$(echo "$rl"|fgrep "$l"); 
          [[ -z "$rl_t" ]] && {
            echo "<SIM>$rl</SIM>" ; break ;  
          }||{
            rl="$rl_t";
          }
        }
        ((c++)); 
        ((c==wc))&&{ 
            echo "$rl" | \
            sed -e "s/^.*<CATE>//g" -e "s/<\/CATE>.*$//g"| \
            sort|uniq -c|sort -nr| \
            head -n1|awk '{ print $2;}'| \
            sed -e "s/^/<CATEGORY>/g" -e "s/$/<\/CATEGORY>/g" ;
        }
        ((c==wcl))&&{
            echo "<SIM>$rl</SIM>" ; break ;  
        }
      done );
}

