#!/bin/bash
#堀内
find np -type f > file.txt;
while read fl;do
rst=`basename $fl`;
cat "$fl" > list.txt
:>rst/$rst;
while read line;do
#5274496,CN2002102701000386,与党推薦の星野氏返り咲き,与野党対決を制す,&lt;news.content Duid=&quot;CO0001&quot;&gt; &lt;p&gt;　田中真紀子前外相の議員辞職に伴う衆院新潟５区補選は、無所属の元衆院議員星野行男氏（７０）＝自民、公明、保守推薦＝が、無所属新人の神奈川大教授石積勝氏（５２）＝民主、自由、社民推薦＝と?
  #echo "$line";
  title=`echo "$line"|awk -F, '{print $3;}'|nkf -We |mecab -Owakati|nkf -wLu`
  subtitle=`echo "$line"|awk -F, '{print $4;}'|nkf -We |mecab -Owakati|nkf -wLu`
  body=`echo "$line"|awk -F, '{print $5;}'|sed -e "s|&quot;||g" -e "s|&lt;[^;]*&gt;||g"|nkf -We |mecab -Owakati|nkf -wLu`
  echo "$title $subtitle $body"|tee -a rst/$rst;
done < list.txt 

done < file.txt

