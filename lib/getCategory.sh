
function getCategory_ani(){
  l=$( echo "$KEYS_RESULT_LINE" | sed -e "s/<KEYS>//g" -e "s/<\/KEYS>//g" -e "s/<KEY>//g" -e "s/<\/KEY>/\n/g" -e "s/<SCORE>/:/g" -e "s/<\/SCORE>//g" ); 
  hn=$( echo "$l" | head -n1 | awk -F: '{ print $2; }' );
  tn=$( echo "$l" | tail -n1 | awk -F: '{ print $2; }' ) ;
  av=$( echo "$hn" "$tn" | awk '{ print ($1+$2)/2; }' ) ;
  kw=$( echo "$l" | awk -F: '{ if( $2> '"$av"' ){ print $1; } }' );
  wc=$( echo "$kw" | wc -l | awk '{ print $1; }' ) ;
  cnt=0;
  #RESULT_LINE=`cat $NEWSPACKDB`;
  RESULT_LINE=$( cat $NEWSPACKDB );
  #echo "$kw" | tr '\n' ' ' | while read line;do
  #echo "$kw" | while read line;do
  NPCATEGORY_RESULT_LINE=$( echo "$kw" | \
      while read line;do
        #while read line;do
        #RESULT_LINE=`egrep "${line}" "$RESULT_LINE"`;
         RESULT_LINE=$(egrep "$line" "$RESULT_LINE");
        #cnt=$((cnt + 1));
         ((cnt++));
         #if [ "$cnt" = "$wc" ];then
          #echo "$RESULT_LINE";
         #fi 
         ((cnt==wc))&&{ echo "$RESULT_LINE"; }
      done |\
            sed -e "s/^.*<CATE>//g" -e "s/<\/CATE>.*$//g" | \
            sort | uniq -c | sort -nr | \
            head -n1| awk '{ print $2;}' | awk -F- '{ print $1; }'| \
            sed -e "s/^/<CATEGORY>/g" -e "s/$/<\/CATEGORY>/g" );
}

function getCategory(){
  l=$( echo "$KEYS_RESULT_LINE" | sed -e "s/<KEYS>//g" -e "s/<\/KEYS>//g" -e "s/<KEY>//g" -e "s/<\/KEY>/\n/g" -e "s/<SCORE>/:/g" -e "s/<\/SCORE>//g" ); 
  hn=$( echo "$l" | head -n1 | awk -F: '{ print $2; }' );
  tn=$( echo "$l" | tail -n1 | awk -F: '{ print $2; }' ) ;
  av=$( echo "$hn" "$tn" | awk '{ print ($1+$2)/2; }' ) ;
  kw=$( echo "$l" | awk -F: '{ if( $2> '"$av"' ){ print $1; } }' );
  wc=$( echo "$kw" | wc -l | awk '{ print $1; }' ) ;

  w=$( echo "$kw" | tr '\n' ' ' ) ;
  for((i=0;i<wc;i++)){ wo=( $( echo "$w") ); }
  case "$wc" in
    1)
      NPCATEGORY_RESULT_LINE=$( egrep "${wo[0]}" "$NEWSPACKDB"| \
        sed -e "s/^.*<CATE>//g" -e "s/<\/CATE>.*$//g" | \
        sort | uniq -c | sort -nr | \
        head -n1| awk '{ print $2;}' | awk -F- '{ print $1; }'| \
        sed -e "s/^/<CATEGORY>/g" -e "s/$/<\/CATEGORY>/g" ) ;
      ;;
    2)
      NPCATEGORY_RESULT_LINE=$( egrep "${wo[0]}" "$NEWSPACKDB"|egrep "${wo[1]}"| \
        sed -e "s/^.*<CATE>//g" -e "s/<\/CATE>.*$//g" | \
        sort | uniq -c | sort -nr | \
        head -n1| awk '{ print $2;}' | awk -F- '{ print $1; }'| \
        sed -e "s/^/<CATEGORY>/g" -e "s/$/<\/CATEGORY>/g" ) ;
      ;;
    3)
      NPCATEGORY_RESULT_LINE=$( egrep "${wo[0]}" "$NEWSPACKDB"|egrep "${wo[1]}"|egrep "${wo[2]}"| \
        sed -e "s/^.*<CATE>//g" -e "s/<\/CATE>.*$//g" | \
        sort | uniq -c | sort -nr | \
        head -n1| awk '{ print $2;}' | awk -F- '{ print $1; }'| \
        sed -e "s/^/<CATEGORY>/g" -e "s/$/<\/CATEGORY>/g" ) ;
      ;;
    4)
      NPCATEGORY_RESULT_LINE=$( egrep "${wo[0]}" "$NEWSPACKDB"|egrep "${wo[1]}"|egrep "${wo[2]}"|egrep "${wo[3]}" | \
        sed -e "s/^.*<CATE>//g" -e "s/<\/CATE>.*$//g" | \
        sort | uniq -c | sort -nr | \
        head -n1| awk '{ print $2;}' | awk -F- '{ print $1; }'| \
        sed -e "s/^/<CATEGORY>/g" -e "s/$/<\/CATEGORY>/g" ) ;
      ;;
    5)
      NPCATEGORY_RESULT_LINE=$( egrep "${wo[0]}" "$NEWSPACKDB"|egrep "${wo[1]}"|egrep "${wo[2]}"|egrep "${wo[3]}"|egrep "${wo[4]}"| \
        sed -e "s/^.*<CATE>//g" -e "s/<\/CATE>.*$//g" | \
        sort | uniq -c | sort -nr | \
        head -n1| awk '{ print $2;}' | awk -F- '{ print $1; }'| \
        sed -e "s/^/<CATEGORY>/g" -e "s/$/<\/CATEGORY>/g" ) ;
      ;;
    *)
      echo "#other" ;
      NPCATEGORY_RESULT_LINE=$( egrep "${wo[0]}" "$NEWSPACKDB"|egrep "${wo[1]}"|egrep "${wo[2]}"| \
        sed -e "s/^.*<CATE>//g" -e "s/<\/CATE>.*$//g" | \
        sort | uniq -c | sort -nr | \
        head -n1| awk '{ print $2;}' | awk -F- '{ print $1; }'| \
        sed -e "s/^/<CATEGORY>/g" -e "s/$/<\/CATEGORY>/g" ) ;
      ;;
  esac
}
