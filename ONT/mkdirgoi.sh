#!/bin/bash
#にほんごごい体系のフォルダを作成する
#<NO>1</NO><GOI>名詞</GOI><OYA_NO>-</OYA_NO><OYA_GOI></OYA_GOI><PAR>"" - ">名詞"</PAR><DAN>1</DAN><SSN>2-2715</SSN><BODY>あれ 彼 あれこれ あれ等 いず
#れ 何れ 有象無象 エトワス 外物 各般 客体 比べ物 これ 此 此れ 是 是れ 之 之
#れ これら 授かり物 授け物 事々物々 事事物物 事物 諸行 森羅万象 造化 そっち そのもの 其の物 其物 それ 其 其れ それぞれ 其々 其其 夫々 夫夫 それら そ>れ等 地水火風空 どちら どれ 名無し なに 何 なにか 何か なになに 何々 何何 なん なんか 彼此 被保険物 ほう ほか もの 物 物事 もん 両方</BODY><KEIRO>1</KEIRO><KEIROJ>名詞</KEIROJ>
GOITAIKEI="../lib/GOITAIKEI2";

while read l;do
  #echo "$l";
  tg=$(echo "$l" | sed -e "s|^.*<TAG>||" -e "s|</TAG>.*$||");
  dr=$(echo "$tg" | tr "-" "\n" | while read t;do
    #echo "$t";
    d=$(cat "$GOITAIKEI"|grep "<NO>$t</NO>"|sed -e "s|^.*<GOI>||" -e "s|</GOI>.*$||");
    echo -n "$d/"; 
done| sed -e "s|/$||");
  id=$(echo "$tg" | awk -F- '{print $NF;}');
  mkdir -p "$dr";
  cat "$GOITAIKEI"|grep "<NO>$id</NO>" > "$dr/$id";
  #echo "$dr/$id";
done < GTLIST
