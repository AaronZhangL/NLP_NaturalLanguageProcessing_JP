#!/bin/bash
#堀内作成
list="../page.txt";
rst="rst";
wikilist="wikilist.txt";
:>$wikilist;
while read line;do
  #id は生成時に割り振られ固定
  id=`echo "$line"|awk '{print $1;}'`;
  #idを出力フォルダ・ファイルにする
  #リビジョンを更新すると latest が更新される
  latest=`echo "$line"|awk '{print $10;}'`;
  body=`mysql -uroot -pkydroot1101 wikipedia -e "select * from text where old_id='$latest'"|tail -n+2`;
  if [ -z "$body" ];then
    continue;
  fi
  #メタ情報を抽出する
  metatmp=`echo "$body"|sed -e "s|{{|\n{{|g"|grep "{{"`;
  meta=`while read mt;do
    echo -n "$mt"|sed -e "s|.*{{|{{|" -e "s|}}.*|}}|";
done < <(echo "$metatmp")`
  #本文情報を抽出する
  description=`echo "$body"|sed -e "s|{{[^\}]*}}||g" -e "s|^[0-9]*||"`;
  mec_tmp=`echo "$description"|sed 's|\\\n|\n|g'|grep -v "^$"|grep "。"`;
  mec=`while read ct;do
    echo "$ct"|mecab -Owakati -d /usr/local/lib/mecab/dic/mecab-ipadic-neologd/
done < <(echo "$mec_tmp")`
  title=`echo "$line"|awk '{print $3;}'`;
  mec_title=`echo "$title"|mecab -Owakati -d /usr/local/lib/mecab/dic/mecab-ipadic-neologd/`;
  other=`echo "$line"|awk '{
  printf "<ID>%s</ID><LATESTID>%s</LATESTID><NAMESPACE>%s</NAMESPACE><RESTRICTIONS>%s</RESTRICTIONS><ISREDIRECT>%s</ISREDIRECT><ISNEW>%s</ISNEW><RANDOM>%s</RANDOM><TOUCHED>%s</TOUCHED><LINKSUPDATED>%s</LINKSUPDATED><LEN>%s</LEN><CONTENTMODEL>%s</CONTENTMODEL><LANG>%s</LANG>" , $1 ,$10 ,$2,$4,$5,$6,$7,$8,$9,$11,$12,$13 ;
}'`
  #出力先
  #printf "\%'d\n" 1234 produces \1'245

  path="$rst/"`export LANG=ja_JP.utf-8 ;echo "$id"|awk '{printf"\%\047d\n",$1}'|sed -e "s|,|/|g"`".xml";
  dir=`dirname "$path"`;
  mkdir -p "$dir";
  echo "<ITEM>
  <TITEL>$title</TITLE>
  <META>$meta</META>
  <DESCRIPTION>$description</DESCRIPTION>
  <BODY>$body</BODY>
  <MECAB>$mec_title $mec</MECAB>
  $other</ITEM>"> $path;

  #echo "##$body##"|tee -a result.txt;
  #page_id: 3396499
  #page_namespace: 0
  #page_title: 寺崎北
  #page_restrictions: 
  #page_is_redirect: 0
  #page_is_new: 0
  #page_random: 1
  #page_touched: 0.829676481662
  #page_links_updated: 20160407113823
  #page_latest: 59257659
  #page_len: 6200
  #page_content_model: NULL
  #page_lang: NULL

  #old_id: 59257659
  #old_text: 
  echo "<ID>$id</ID><LATEST>$latest</LATEST><TITLE>$title</TITLE><PATH>$path</PATH>"|tee -a "$wikilist"; 

done < "$list";
