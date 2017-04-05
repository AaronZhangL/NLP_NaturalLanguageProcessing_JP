
function getCategory(){
  l=$( echo "$KEYS_RESULT_LINE" | sed -e "s/<KEYS>//g" -e "s/<\/KEYS>//g" -e "s/<KEY>//g" -e "s/<\/KEY>/\n/g" -e "s/<SCORE>/:/g" -e "s/<\/SCORE>//g" ); 
  hn=$( echo "$l" | head -n1 | awk -F: '{ print $2; }' );
  tn=$( echo "$l" | tail -n1 | awk -F: '{ print $2; }' ) ;
  av=$( echo "$hn" "$tn" | awk '{ print ($1+$2)/2; }' ) ;
  kw=$( echo "$l" | awk -F: '{ if( $2> '"$av"' ){ print $1; } }' );
  wc=$( echo "$kw" | wc -l | awk '{ print $1; }' ) ;
  cnt=0;
  RESULT_LINE=`cat $NEWSPACKDB`;
  echo "$kw" | tr '\n' ' ' | while read line;do
     RESULT_LINE=`egrep "${line}" "$RESULT_LINE"`;
     cnt=$((cnt + 1));
     if [ "$cnt" = "$wc" ];then
       echo "$RESULT_LINE";
     fi 
  done|\
        sed -e "s/^.*<CATE>//g" -e "s/<\/CATE>.*$//g" | \
        sort | uniq -c | sort -nr | \
        head -n1| awk '{ print $2;}' | awk -F- '{ print $1; }'| \
        sed -e "s/^/<CATEGORY>/g" -e "s/$/<\/CATEGORY>/g";
}
