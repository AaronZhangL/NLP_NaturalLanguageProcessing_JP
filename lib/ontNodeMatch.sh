#################################################################
#
#  投入された記事の重要語と、
#  日本語語彙体形のノードに格納されている語彙を見比べて
#  ノードを返す
#
#################################################################
##オントロジー
function ontNodeMatch(){
  NODE_RESULT_LINE=$( echo "$KEYS_RESULT_LINE" | sed -e "s|<KEY>|\n<KEY>|g" | grep "<KEY>" | while read line;do
    num=$( echo "$line"|sed -e "s|^.*<KEY>||g" -e "s|<SCORE>.*$||g" ) ;
    score=$( echo "$line" | sed -e "s|^.*<SCORE>||g" -e "s|</SCORE>.*$||g" ) ;
    cat "$GOITAIKEI" | grep -e ">$num " -e " $num " -e " $num<" | grep -v "^$" | while read line2;do
      goi=$( echo "$line2" | sed -e "s|^.*<GOI>||g" -e "s|</GOI>.*$||g" ) ;
      no=$( echo "$line2" | sed -e "s|^.*<NO>||" -e "s|</NO>.*$||" );
      deep=$( echo "$line2" | sed -e "s|^.*<KEIRO>||g" -e "s|</KEIRO>.*$||g" | awk -F- '{ print NF; }' ) ;
      goiscore=$( echo "1 * $deep * $score" | bc ) ;
			if [ ! -z "$goi" ] && [ ! -z "$goiscore" ]; then
      	 echo "$no,$goi,$goiscore"
			fi
			echo "$ontNode" | grep -v "^$goi,"
    done 
  done | grep -v "^$"  |  awk -F, '{ a[$2]+=$3; b[$2]=$1 } END { for(k in a) printf "%s,%s,%.2f\n", b[k], k, a[k] }'| sort -t, -k3 -nr | awk -F, '{ print "<ID>" $1 "</ID><N>" $2 "</N><S>" $3 "</S></N>" ; }' | tr -d '\n' | sed -e "s/^/<NODE>/g" -e "s/$/<\/NODE>/g" ) ;



#"KEYS_RESULT_LINE:$KEYS_RESULT_LINE";
#  #語彙体系：スコアのハッシュ
#  :>$TMP/ontNOde.tmp;
#  while read key;do
#    #echo "key:$key";
#    #<KEY>早大<SCORE>7.00</SCORE></KEY>
#    num=`echo "$key"|sed -e "s|^.*<KEY>||" -e "s|<SCORE>.*$||"`;
#    score=`echo "$key"|sed -e "s|^.*<SCORE>||" -e "s|</SCORE>.*$||"`;
#    goimatch=`cat "$GOITAIKEI" |grep -e ">$num " -e " $num " -e " $num<"|grep -v "^$"`;
#    while read goiline;do
#      if [ -z "$goiline" ];then
#        continue;
#      fi
#      goi=`echo "$goiline"|sed -e "s|^.*<GOI>||" -e "s|</GOI>.*$||"`;
#      no=`echo "$goiline"|sed -e "s|^.*<NO>||" -e "s|</NO>.*$||"`;
#      keiro=`echo "$goiline"|sed -e "s|^.*<KEIRO>||" -e "s|</KEIRO>.*$||"`;
#      deep=`echo "$keiro"|awk -F- '{print NF}'`
#      #とりあえずファイルにアウトプット後でawkとかにする
#      ontgrep=`cat "$TMP/ontNOde.tmp" |grep "^$goi,"`;
#      goiscore=`echo "1 * $deep * $score" | bc`;
#      if [ -n "$ontgrep" ];then
#        goisum=`echo "$ontgrep"|awk -F, '{print $2;}'`;
#        goiscore=`echo "$goisum + $goiscore" | bc`; 
#      fi
#      echo "$goi,$goiscore" > "$TMP/ontNOde.tmp.tmp";
#      cat "$TMP/ontNOde.tmp" |grep -v "^$goi," >> "$TMP/ontNOde.tmp.tmp";
#      /bin/mv  "$TMP/ontNOde.tmp.tmp" "$TMP/ontNOde.tmp";
#    done < <(echo "$goimatch")
#
#    #<NO>2020</NO><GOI>打ち</GOI><OYA_NO>2019</OYA_NO><OYA_GOI>打ち・投げ・撃ち</OYA_GOI><PAR>"打ち・投げ・撃ち" - "打ち"</PAR><DAN>10</DAN><SSN>-</SSN><BODY>アッパー アッパーカット 当て身 横殴り ライト打 乱射 乱打 両手打 塁打 レフト打 連安打 連打 ロビング ロブ ロフト 藁打 藁打ち</BODY><KEIRO>1-1000-1235-1236-1560-1681-1682-1701-1702</KEIRO>
#
#
#  done < <(echo "$KEYS_RESULT_LINE"|sed -e "s|<KEY>|\n<KEY>|g"|grep "<KEY>") 
#  cat "$TMP/ontNOde.tmp"|sort -t, -k2 -nr;
#
##KEYS_RESULT_LINE:<KEYS><KEY>早大<SCORE>7.00</SCORE></KEY><KEY>大学野球<SCORE>6.24</SCORE></KEY><KEY>斎藤<SCORE>6.00</SCORE></KEY><KEY>連覇<SCORE>4.00</SCORE></KEY><KEY>東京<SCORE>4.00</SCORE></KEY><KEY>完封<SCORE>4.00</SCORE></KEY><KEY>三振<SCORE>4.00</SCORE></KEY><KEY>慶大<SCORE>3.00</SCORE></KEY><KEY>大学野球秋季リーグ<SCORE>1.83</SCORE></KEY><KEY>千葉経大付<SCORE>1.68</SCORE></KEY><KEY>リーグ戦<SCORE>1.68</SCORE></KEY><KEY>明治神宮大会<SCORE>1.59</SCORE></KEY><KEY>エース加藤幹<SCORE>1.59</SCORE></KEY><KEY>適時打<SCORE>1.41</SCORE></KEY><KEY>最終週<SCORE>1.41</SCORE></KEY><KEY>早稲田実<SCORE>1.41</SCORE></KEY><KEY>勝ち点<SCORE>1.41</SCORE></KEY></KEYS>
#  exit;
}
