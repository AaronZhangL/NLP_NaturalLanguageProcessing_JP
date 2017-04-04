#!/bin/bash
#堀内作成

#keys=`./MAIN.sh -f "in"|sed -e "s|.*<KEYS>||" -e "s|</KEYS>.*||"|grep "<KEY>" |sed -e "s|<KEY>|\n<KEY>|g"|grep -v "^$"|awk '{
#noun=$0 ;
#gsub (/<SCORE>.*$/, "", noun) ;
#gsub (/^.*<KEY>/, "", noun) ;
#printf "%s " , noun;
#}'`;
keys="東京 六 大学 野球 秋季 リーグ は ３ ０ 日 、 神宮球場 で 最終 週 の 早大 — 慶大 ３ 回戦 が あり、 早大 が 斎藤 （ １ 年 、 早稲田 実 ） の 活躍 で 慶大 に ７ — ０ で 大勝 し 、 ３ 季 連続 ４ ０ 度目 の 優勝 を 果たし た 。 勝ち 点 ４ で 明大 と 並ん だ が 、 勝率 で 上回っ た 。 早大 は １１月 １ ０ 日 開幕 の 明治 神宮 大会 へ の 出場 も 決め た 。 　 斎藤 は スライダー や ツーシーム など の 変化球 が さえ 、 リーグ 戦 初 完封 。 被 安打 ４ で １ ５ 奪 三振 の 力投 で 今季 ４ 勝 目 を 挙げ た 。 打線 は １ 回 、 松本 （ ３ 年 、 千葉 経 大 付 ） の 適時 打 と 本田 （ ４ 年 、 智弁和歌山 ） の ３ 点 二塁打 で ４ 点 を 先取 し 、 その後 も 加点 し た 。 慶大 は ３ 連投 の エース 加藤 幹 （ ４ 年 、 川和 ） が 力尽き た 。"
for var in sports world economics national ;do
  model="VECZO/model/${var}_doc2vec";
  #doc2vecでエラーがなかった単語の組み合わせ
#[('sent_384', 0.31705960631370544), ('sent_866', 0.2842436134815216), ('sent_478', 0.2537553906440735), ('sent_201', 0.24434585869312286), ('sent_401', 0.23477569222450256), ('sent_838', 0.22633293271064758), ('sent_465', 0.22490546107292175), ('sent_571', 0.22136487066745758), ('sent_315', 0.2198496162891388), ('sent_963', 0.21598972380161285)]
#cat t|python VECDOC.py model/sports_doc2vec|python unescape.py 
  rst=`echo "$keys"|python VECZO/VECDOC.py $model|sed -e "s|),|),\n|g"`;

  echo "####$var######"
  echo "$keys";
#  echo "$rst";
#[('sent_533', 0.5552881956100464),
# ('sent_402', 0.4930605888366699),
# ('sent_170', 0.4929535388946533)]
  while read sent;do
    se=`echo "$sent"|sed -e "s|.*('||" -e "s|',.*||"|sed -e "s|sent_||"`;
    se=$(($se + 1));
    sc=`echo "$sent"|sed -e "s|.*', ||" -e "s|).*||"`;
    NP="VECZO/np/${var}.txt";
    doc=`head -n "$se" "$NP"|tail -n1`
    echo "$doc:$sc";

  done < <(echo "$rst")
#早大 大学野球 斎藤 連覇 東京 完封 三振 慶大 大学野球秋季リーグ 千葉経大付 リーグ戦 明治神宮大会 エース加藤幹 適時打 最終週 早稲田実 勝ち点 
  #echo "$keys"|python VECZO/VECZO.py "$model"|python VECZO/unescape.py
done
#<KEYS><KEY>早大<SCORE>7.00</SCORE></KEY><KEY>大学野球<SCORE>6.24</SCORE></KEY><KEY>斎藤<SCORE>6.00</SCORE></KEY><KEY>連覇<SCORE>4.00</SCORE></KEY><KEY>東京<SCORE>4.00</SCORE></KEY><KEY>完封<SCORE>4.00</SCORE></KEY><KEY>三振<SCORE>4.00</SCORE></KEY><KEY>慶大<SCORE>3.00</SCORE></KEY><KEY>大学野球秋季リーグ<SCORE>1.83</SCORE></KEY><KEY>千葉経大付<SCORE>1.68</SCORE></KEY><KEY>リーグ戦<SCORE>1.68</SCORE></KEY><KEY>明治神宮大会<SCORE>1.59</SCORE></KEY><KEY>エース加藤幹<SCORE>1.59</SCORE></KEY><KEY>適時打<SCORE>1.41</SCORE></KEY><KEY>最終週<SCORE>1.41</SCORE></KEY><KEY>早稲田実<SCORE>1.41</SCORE></KEY><KEY>勝ち点<SCORE>1.41</SCORE></KEY></KEYS>
