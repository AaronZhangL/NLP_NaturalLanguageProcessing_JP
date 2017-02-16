#!/bin/bash
#わーどネット enjpをパース
enjp="t";
:>enjp.xml
xml="";
flg="0";
while read line;do
 #先頭行
  if echo "$line" |grep ^[0-9] >/dev/null;then
    id="$line";
    #前のアイテムを出力
  elif echo "$line"|grep "^$" >/dev/null;then
    #XMLを生成する
    #echo "jp:$jp en:$en";
    xml="<ITEM><ID>$id</ID><JP>$jp</JP><EN>$en</EN><JPDF>$jpdf</JPDF><ENDF>$endf</ENDF><SITEMS>$sitem<sitem><sid>$sid</sid><scat>$scat</scat><sjp>$sjp</sjp></sitem></SITEMS></ITEM>";
    echo "$xml" |tee -a "enjp.xml";
    flg="0";
    xml="";
    id="";
    jp="";
    en="";
    jpdf="";
    endf="";
    sitem="";
    sid="";
    scat="";
    sjp="";
  elif echo "$line"|egrep "^\*\*\*\*" | grep "[0-9a-z\(]" >/dev/null;then
    if [ "$flg" = "1" ];then
      sjp=`echo "$line"|sed -e "s|\*||g";`;
    else
      en=`echo "$line"|sed -e "s|\*||g";`;
    fi
  elif echo "$line"|grep "^\*\*\*\*" |grep "[０-９Ａ-ｚ、-◯ぁ-んァ-ヶ亜-腕弌-熙]">/dev/null;then
    if [ "$flg" = "1" ];then
      sjp=`echo "$line"|sed -e "s|\*||g";`;
    else
      jp=`echo "$line"|sed -e "s|\*||g";`;
    fi
  elif echo "$line"|grep "\[" >/dev/null;then
    flg="1";
    if [ -n "$sitem" ];then
      sitem="$sitem<sitem><sid>$sid</sid><scat>$scat</scat><sjp>$sjp</sjp>";
    else
      sitem="<sitem>";
    fi
    sid=`echo "$line"|awk '{print $2;}'|sed -e "s|\[||g" -e "s|\]||g"`;
    scat=`echo "$line"|awk '{print $4;}'`;
    sjp="";
  #日本語の定義
  elif echo "$line"|grep "^\*\*"|grep "[０-９Ａ-ｚ、-◯ぁ-んァ-ヶ亜-腕弌-熙]" >/dev/null;then
    if [ "$flg" = "0" ];then
      jpdf=`echo "$line"|sed -e "s|\*||g";`;
    fi
  #英語の定義
  elif echo "$line"|grep "^\*\*"|grep "[0-9a-z(]" >/dev/null;then
    if [ "$flg" = "0" ];then
      endf=`echo "$line"|sed -e "s|\*||g";`;
    fi
  fi
done < "$enjp"
