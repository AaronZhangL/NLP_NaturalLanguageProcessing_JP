
#real    0m44.887s
#user    0m32.204s
#sys     0m18.215s
function getCategory_ani(){
  l=$(echo "$KEYS_RESULT_LINE"|sed -e "s/<KEYS>//g" -e "s/<\/KEYS>//g" -e "s/<KEY>//g" -e "s/<\/KEY>/\n/g" -e "s/<SCORE>/:/g" -e "s/<\/SCORE>//g"); 
  hn=$(echo "$l"|head -n1|awk -F: '{ print $2; }');
  tn=$(echo "$l"|tail -n1|awk -F: '{ print $2; }') ;
  av=$(echo "$hn" "$tn"|awk '{ print ($1+$2)/2; }') ;
  kw=$(echo "$l"|awk -F: '{ if($2> '"$av"'){ print $1; } }');
  wc=$(echo "$kw"|wc -l|awk '{ print $1; }') ;

  #cnt$B$O<+F0E*$K(B0$B$G=i4|2=$5$l$k$+$iITMW(B
  #cnt=0;

  # =`` $B$O8E$$=q$-J}!#(B =$( ) $B$K$7$h$&(B
  #RESULT_LINE=`cat "$NEWSPACKDB"`;

  # $B%m!<%+%kJQ?t$O>.J8;z!#%0%m!<%P%kJQ?t$OBgJ8;z(B
  # $B0UL#$r;}$?$J$$JQ?t$O(B2$BJ8;zDxEY$G!#0UL#$r;}$DJQ?t$,L\N)$D$h$&$K(B
  rl=$(cat "$NEWSPACKDB"); # RL: resultLine
  NPCATEGORY_RESULT_LINE=$(echo "$kw"| \
      while read l; do # l: line
        rl=$(echo "$rl"|fgrep "$l");

         # $B%$%s%/%j%a%s%H$J$I?tCM$O(B (( )) $B$G0O$`$HJXMx(B
         # $BJQ?t$N(B$$B$bITMW!!(B
         #cnt=$((cnt + 1));
         ((c++)); # c:count

        # $B9bB.2=$rL\;X$9$H$-$O(B if $B$9$iI,MW$J$7(B
        # (( .....))&&{
        #   true
        # }||{
        #   false
        # }
        #if [ "$cnt" = "$wc" ];then
        #   echo "$RESULT_LINE";
        #fi 
         ((c==wc))&&{ echo "$rl"; }
      done| \
            sed -e "s/^.*<CATE>//g" -e "s/<\/CATE>.*$//g"| \
            sort|uniq -c|sort -nr| \
            head -n1|awk '{ print $2;}'| \
            sed -e "s/^/<CATEGORY>/g" -e "s/$/<\/CATEGORY>/g");
}

#real    0m15.738s
#user    0m15.243s
#sys     0m0.652s
function getCategory(){
  l=$(echo "$KEYS_RESULT_LINE"|sed -e "s/<KEYS>//g" -e "s/<\/KEYS>//g" -e "s/<KEY>//g" -e "s/<\/KEY>/\n/g" -e "s/<SCORE>/:/g" -e "s/<\/SCORE>//g"); 
  hn=$(echo "$l"|head -n1|awk -F: '{ print $2; }');
  tn=$(echo "$l"|tail -n1|awk -F: '{ print $2; }') ;
  av=$(echo "$hn" "$tn"|awk '{ print ($1+$2)/2; }') ;
  kw=$(echo "$l"|awk -F: '{ if($2> '"$av"'){ print $1; } }');
  wc=$(echo "$kw"|wc -l|awk '{ print $1; }') ;
  w=$(echo "$kw"|tr '\n' ' ') ;
  for((i=0;i<wc;i++)){ wo=($(echo "$w")); }
  case "$wc" in
    1)
      NPCATEGORY_RESULT_LINE=$(egrep "${wo[0]}" "$NEWSPACKDB"| \
        sed -e "s/^.*<CATE>//g" -e "s/<\/CATE>.*$//g"| \
        sort|uniq -c|sort -nr| \
        head -n1|awk '{ print $2;}'| \
        sed -e "s/^/<CATEGORY>/g" -e "s/$/<\/CATEGORY>/g") ;
      ;;
    2)
      NPCATEGORY_RESULT_LINE=$(egrep "${wo[0]}" "$NEWSPACKDB"|egrep "${wo[1]}"| \
        sed -e "s/^.*<CATE>//g" -e "s/<\/CATE>.*$//g"| \
        sort|uniq -c|sort -nr| \
        head -n1|awk '{ print $2;}'| \
        sed -e "s/^/<CATEGORY>/g" -e "s/$/<\/CATEGORY>/g") ;
      ;;
    3)
      NPCATEGORY_RESULT_LINE=$(egrep "${wo[0]}" "$NEWSPACKDB"|egrep "${wo[1]}"|egrep "${wo[2]}"| \
        sed -e "s/^.*<CATE>//g" -e "s/<\/CATE>.*$//g"| \
        sort|uniq -c|sort -nr| \
        head -n1|awk '{ print $2;}'| \
        sed -e "s/^/<CATEGORY>/g" -e "s/$/<\/CATEGORY>/g") ;
      ;;
    4)
      NPCATEGORY_RESULT_LINE=$(egrep "${wo[0]}" "$NEWSPACKDB"|egrep "${wo[1]}"|egrep "${wo[2]}"|egrep "${wo[3]}"| \
        sed -e "s/^.*<CATE>//g" -e "s/<\/CATE>.*$//g"| \
        sort|uniq -c|sort -nr| \
        head -n1|awk '{ print $2;}'| \
        sed -e "s/^/<CATEGORY>/g" -e "s/$/<\/CATEGORY>/g") ;
      ;;
    5)
      NPCATEGORY_RESULT_LINE=$(egrep "${wo[0]}" "$NEWSPACKDB"|egrep "${wo[1]}"|egrep "${wo[2]}"|egrep "${wo[3]}"|egrep "${wo[4]}"| \
        sed -e "s/^.*<CATE>//g" -e "s/<\/CATE>.*$//g"| \
        sort|uniq -c|sort -nr| \
        head -n1|awk '{ print $2;}'| \
        sed -e "s/^/<CATEGORY>/g" -e "s/$/<\/CATEGORY>/g") ;
      ;;
    *)
      NPCATEGORY_RESULT_LINE=$(egrep "${wo[0]}" "$NEWSPACKDB"|egrep "${wo[1]}"|egrep "${wo[2]}"| \
        sed -e "s/^.*<CATE>//g" -e "s/<\/CATE>.*$//g"| \
        sort|uniq -c|sort -nr| \
        head -n1|awk '{ print $2;}'| \
        sed -e "s/^/<CATEGORY>/g" -e "s/$/<\/CATEGORY>/g") ;
      ;;
  esac
}
