#!/bin/bash
#ほりうち
#
echo "#############";
echo "重要語";
k="<KEYS><KEY>大学野球<SCORE>4.41</SCORE></KEY><KEY>完封<SCORE>4.00</SCORE></KEY><KEY>三振<SCORE>4.00</SCORE></KEY><KEY>斎藤<SCORE>4.00</SCORE></KEY><KEY>東京<SCORE>4.00</SCORE></KEY><KEY>連覇<SCORE>4.00</SCORE></KEY><KEY>早大<SCORE>4.00</SCORE></KEY><KEY>慶大<SCORE>3.00</SCORE></KEY><KEY>早大<SCORE>3.00</SCORE></KEY><KEY>斎藤<SCORE>2.00</SCORE></KEY><KEY>大学野球秋季リーグ<SCORE>1.83</SCORE></KEY><KEY>リーグ戦<SCORE>1.68</SCORE></KEY><KEY>千葉経大付<SCORE>1.68</SCORE></KEY><KEY>明治神宮大会<SCORE>1.59</SCORE></KEY><KEY>エース加藤幹<SCORE>1.59</SCORE></KEY><KEY>最終週<SCORE>1.41</SCORE></KEY><KEY>適時打<SCORE>1.41</SCORE></KEY><KEY>勝ち点<SCORE>1.41</SCORE></KEY><KEY>早稲田実<SCORE>1.41</SCORE></KEY></KEYS>";
#k="<KEYS><KEY>北朝鮮<SCORE>5.83</SCORE></KEY><KEY>中距離<SCORE>5.69</SCORE></KEY><KEY>落下<SCORE>5.24</SCORE></KEY><KEY>日本海<SCORE>5.24</SCORE></KEY><KEY>新型ミサイル発射<SCORE>4.42</SCORE></KEY><KEY>日本<SCORE>2.83</SCORE></KEY><KEY>安全保障<SCORE>2.45</SCORE></KEY><KEY>弾道ミサイル<SCORE>2.06</SCORE></KEY><KEY>米太平洋軍<SCORE>2.00</SCORE></KEY><KEY>米中首脳会談<SCORE>2.00</SCORE></KEY><KEY>国連安全保障理事会決議<SCORE>1.91</SCORE></KEY><KEY>新型中距離弾道ミサイル<SCORE>1.86</SCORE></KEY><KEY>日米韓<SCORE>1.78</SCORE></KEY><KEY>排他的経済水域<SCORE>1.68</SCORE></KEY><KEY>挑発行為<SCORE>1.57</SCORE></KEY><KEY>挑発行動<SCORE>1.57</SCORE></KEY><KEY>落下場所<SCORE>1.41</SCORE></KEY><KEY>浦付近<SCORE>1.41</SCORE></KEY><KEY>日本海側<SCORE>1.41</SCORE></KEY><KEY>日本政府<SCORE>1.41</SCORE></KEY><KEY>安倍晋<SCORE>1.41</SCORE></KEY><KEY>北東方向<SCORE>1.41</SCORE></KEY><KEY>ワシントン共同<SCORE>1.41</SCORE></KEY></KEYS>"
echo "$k";
##
#固有名詞だけ取り出す
echo "#############";
#echo "固有名詞を外す"
l=$(echo "$k" | gsed -e "s/<KEYS>//g" -e "s/<\/KEYS>//g" -e "s/<KEY>//g" -e "s/<\/KEY>/\n/g" -e "s/<SCORE>/:/g" -e "s/<\/SCORE>//g" ); 
#echo "$l"|awk -F: '{print $1;}'|mecab -Owakati|tr " " "\n"|while read w;do
l=$(echo "$l"|awk -F: '{print $1;}'|mecab -d /usr/local/mecab/lib/mecab/dic/mecab-ipadic-neologd/);
echo "$l";
l=$(echo "$l" |awk '{print $1;}'|grep -v "EOS");
#wordNet
echo "#############";
echo "WORDNETを検索する"
echo "$l"|while read w;do
 echo "$w";
 grep -e " $w " -e ">$w "  -e " $w<" "WORDNET"; 
done;
#日本語語彙体型
echo "#############";
echo "GOITAIKEI2を検索する"
echo "$l"|while read w;do
 echo "$w";
 grep -e " $w " -e ">$w "  -e " $w<" "GOITAIKEI2"; 
done;
#類義語を見つける
echo "#############";
echo "WEBLIORUIGOを検索する";
echo "$l"|while read w;do
 echo "$w";
 grep -e " $w " -e ">$w "  -e " $w<" "WEBLIORUIGO2"; 
done;
#l=$(echo "$l"|while read w;do
# echo "$w";
# grep -e " $w " -e ">$w "  -e " $w<" "WEBLIORUIGO2"|sed -e "s|^.*<BODY>||" -e "s|</BODY>.*||"; 
#done|tr " " "\n"|grep -v "^$"|sort|uniq);
#echo "$l";
#連想語を見つける
echo "#############";
echo "RENSORUIGOを検索する"
#l=$(echo "$l"|while read w;do
# echo "$w";
# grep "$w" "RENSORUIGO"|sed -e "s|^.*<GOI>||" -e "s|</GOI>.*||"; 
#done|tr " " "\n"|grep -v "^$"|sort|uniq);
#echo "$l";
echo "$l"|while read w;do
 echo "$w";
 grep  -e " $w " -e ">$w "  -e " $w<" "RENSORUIGO"; 
done;
