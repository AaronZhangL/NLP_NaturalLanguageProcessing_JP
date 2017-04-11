#!/bin/bash
#オントノードマッチてすとようプログラム
#2017年2月10日
function out(){
  echo "#######"
  cat "in3"
  echo "$rst"; 
  echo "#######"

}
function chk(){
  rst=`./MAIN.SH -f in3`;

}
function parse(){
#<ID>66335706</ID><NID>HN2017013101002166</NID><TITLE>大阪、遊具で小１男児が意識不明  </TITLE><BODY>                大阪市営住宅の敷地内で、小１男児が意識不明の状態で見つかる。近くの遊具で遊んでいて首圧迫か。</BODY><CATE>社会-社会</CATE><DATE>2017-02-01T00:00:10+0900</DATE>
  title=`echo "$line"|sed -e "s|^.*<TITLE>||" -e "s|</TITLE>.*||"|sed -e "s|^ ||"`;
  body=`echo "$line"|sed -e "s|^.*<BODY>||" -e "s|</BODY>.*||"|sed -e "s|^ ||"`;
  echo "title=$title&body=$body&perMax=30&summaxLength=&printHTML=no&sports=no" > in3;
  
#title=早大３連覇　斎藤が１５奪三振、初完封　東京六大学野球&body=東京六大学野球秋季リーグは３０日、神宮球場で最終週の早大—慶大３回戦があり、早大が斎藤（１年、早稲田実）の活躍で慶大に７—０で大勝し、３季連続４０度目の優勝を果たした。勝ち点４で明大と並んだが、勝率で上回った。早大は１１月１０日開幕の明治神宮大会への出場も決めた。 　斎藤はスライダーやツーシームなどの変化球がさえ、リーグ戦初完封。被安打４で１５奪三振の力投で今季４勝目を挙げた。打線は１回、松本（３年、千葉経大付）の適時打と本田（４年、智弁和歌山）の３点二塁打で４点を先取し、その後も加点した。慶大は３連投のエース加藤幹（４年、川和）が力尽きた。&perMax=30&summaxLength=&printHTML=no&sports=no
  

}

function main(){
  while read line;do
    parse;
    chk;
    out;
  done < lib/NEWSPACKDB | head
}


main;
exit;
