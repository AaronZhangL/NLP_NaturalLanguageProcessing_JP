#!/bin/bash
#堀内作成

keys=(`./MAIN.sh -f "in"|sed -e "s|.*<KEYS>||" -e "s|</KEYS>.*||"|grep "<KEY>" |sed -e "s|<KEY>|\n<KEY>|g"|grep -v "^$"|awk '{
noun=$0 ;
gsub (/<SCORE>.*$/, "", noun) ;
gsub (/^.*<KEY>/, "", noun) ;
printf "%s " , noun;
}'`);
echo ${keys[@]}
for var in sports world economics national ;do
  model="VECZO/model/${var}_doc2vec";
  #doc2vecでエラーがなかった単語の組み合わせ
  keyline="";
  #doc2vecの実行結果
  keyresult="";
  frst=""; 
  for key in ${keys[@]};do
    if [ -z "$keyline" ];then
      keyline_tmp="$key";      
    else
      keyline_tmp="$keyline $key";      
    fi
    #rst=`echo "$keyline_tmp"|python VECZO/VECZO.py "$model"|python VECZO/unescape.py `;
    rst=`echo "$keyline_tmp"|python VECZO/VECZO.py "$model" 2>&1`;
    if echo "$rst"|grep "KeyError" >/dev/null;then
      :
    else
      keyline="$keyline_tmp";
      frst="$rst";
    fi

  done
  echo "####$var######"
  echo "$keyline";
  echo "$frst"|python VECZO/unescape.py;
#早大 大学野球 斎藤 連覇 東京 完封 三振 慶大 大学野球秋季リーグ 千葉経大付 リーグ戦 明治神宮大会 エース加藤幹 適時打 最終週 早稲田実 勝ち点 
  #echo "$keys"|python VECZO/VECZO.py "$model"|python VECZO/unescape.py
done
#<KEYS><KEY>早大<SCORE>7.00</SCORE></KEY><KEY>大学野球<SCORE>6.24</SCORE></KEY><KEY>斎藤<SCORE>6.00</SCORE></KEY><KEY>連覇<SCORE>4.00</SCORE></KEY><KEY>東京<SCORE>4.00</SCORE></KEY><KEY>完封<SCORE>4.00</SCORE></KEY><KEY>三振<SCORE>4.00</SCORE></KEY><KEY>慶大<SCORE>3.00</SCORE></KEY><KEY>大学野球秋季リーグ<SCORE>1.83</SCORE></KEY><KEY>千葉経大付<SCORE>1.68</SCORE></KEY><KEY>リーグ戦<SCORE>1.68</SCORE></KEY><KEY>明治神宮大会<SCORE>1.59</SCORE></KEY><KEY>エース加藤幹<SCORE>1.59</SCORE></KEY><KEY>適時打<SCORE>1.41</SCORE></KEY><KEY>最終週<SCORE>1.41</SCORE></KEY><KEY>早稲田実<SCORE>1.41</SCORE></KEY><KEY>勝ち点<SCORE>1.41</SCORE></KEY></KEYS>
