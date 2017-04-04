#!/bin/bash
#わーどネット enjpをパース
enjp="wordnetENJP_utf8.txt";
enjp2="enjp2.xml";
:>"enjp2.xml";

#enjp="t";
parse1(){
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
      if [ -n "$sid" ];then
        xml="<ITEM><ID>$id</ID><JP>$jp</JP><EN>$en</EN><JPDF>$jpdf</JPDF><ENDF>$endf</ENDF><SITEMS>$sitem<sitem><sid>$sid</sid><scat>$scat</scat><sjp>$sjp</sjp><sen>$sen</sen></sitem></SITEMS></ITEM>";
      else
        xml="<ITEM><ID>$id</ID><JP>$jp</JP><EN>$en</EN><JPDF>$jpdf</JPDF><ENDF>$endf</ENDF><SITEMS>$sitem</SITEMS></ITEM>";
      fi
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
      sen="";
    elif echo "$line"|grep "^\*\*\*\*" |grep "[０-９Ａ-ｚ、-◯ぁ-んァ-ヶ亜-腕弌-熙]">/dev/null;then
      if [ "$flg" = "1" ];then
        sjp=`echo "$line"|sed -e "s|\*||g";`;
      else
        jp=`echo "$line"|sed -e "s|\*||g";`;
      fi
    elif echo "$line"|egrep "^\*\*\*\*" | grep "[0-9a-z\(]" >/dev/null;then
      if [ "$flg" = "1" ];then
        sen=`echo "$line"|sed -e "s|\*||g";`;
      else
        en=`echo "$line"|sed -e "s|\*||g";`;
      fi
    elif echo "$line"|grep "\[" >/dev/null;then
      flg="1";
      if [ -n "$sid" ];then
        sitem="$sitem<sitem><sid>$sid</sid><scat>$scat</scat><sjp>$sjp</sjp><sen>$sen</sen></sitem>";
      fi
      sid=`echo "$line"|awk '{print $2;}'|sed -e "s|\[||g" -e "s|\]||g"`;
      scat=`echo "$line"|awk '{print $4;}'`;
      sjp="";
      sen="";
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
}
parse2(){
#<NO>2</NO><GOI>具体</GOI><OYA_NO>1</OYA_NO><OYA_GOI>名詞</OYA_GOI><PAR>"名詞" - "具体"</PAR><DAN>2</DAN><SSN>3-994</SSN><BODY>有り物 合せ物 具体 公物 個体 三才 人畜 人馬 地物 天地人 万物 万有 有体物</BODY><KEIRO>1-2</KEIRO>
#<ITEM><ID>01965404</ID><JP></JP><EN>Dreissena, genus Dreissena</EN><JPDF>カワホトトギスガイ。</JPDF><ENDF>zebra mussels</ENDF><SITEMS><sitem><sid>01939598</sid><scat>hype</scat><sjp></sjp><sen>mollusk genus</sen></sitem><sitem><sid>01964636</sid><scat>mem.holo</scat><sjp></sjp><sen>Unionidae, family Unionidae</sen></sitem><sitem><sid>01965529</sid><scat>mem.mero</scat><sjp></sjp><sen>zebra mussel, Dreissena polymorpha</sen></sitem></SITEMS></ITEM>
#./wnquery_byid.sh "00478262" hype jpn|tail -n100 -r

while read line;do
  no=`echo "$line"|sed -e "s|.*<ID>||" -e "s|</ID>.*||"`;
  goi=`echo "$line"|sed -e "s|.*<JP>||" -e "s|</JP>.*||"`;
  body=`echo "$goi"|sed -e "s|,| |g"`;
  engoi=`echo "$line"|sed -e "s|.*<EN>||" -e "s|</EN>.*||"`;
  enbody=`echo "$engoi"|sed -e "s|,| |g"`;
  keiro_line=`./wnquery_byid.sh "$no" hype jpn|tail -n100 -r`;
  OYA_NO=`echo "$keiro_line"|tail -n2|head -n1|sed -e "s|.*<sy>||" -e "s|</sy>.*||" -e "s|-.*||"`;
  DAN=`echo "$keiro_line"|wc -l|sed -e "s|      ||" -e "s| ||"`;
  KEIRO=`echo "$keiro_line"|while read line2;do
    echo "$line2"|sed -e "s|.*<sy>||" -e "s|</sy>.*||" -e "s|-.*||";
done|tr "\n" "-"|sed -e "s|-$||"`;
  KEIRO_JP=`echo "$keiro_line"|while read line2;do
    echo "$line2"|sed -e "s|.*<jp>||" -e "s|</jp>.*||";
done|tr "\n" "-"|sed -e "s|-$||"`;
  OYA_GOI=`echo "$keiro_line"|tail -n2|head -n1|sed -e "s|.*<jp>||" -e "s|</jp>.*||"`
  KEIRO_EN=`echo "$keiro_line"|while read line2;do
    echo "$line2"|sed -e "s|.*<en>||" -e "s|</en>.*||";
done|tr "\n" "-"|sed -e "s|-$||"`;
  OYA_GOI_EN=`echo "$keiro_line"|tail -n2|head -n1|sed -e "s|.*<en>||" -e "s|</en>.*||"`
  #ssn_line=`./wnquery_byid.sh "$no" hypo jpn`;
  ssn_line=`sqlite3 "wnjpn.db" "select * from synlink where synset1='$no-n' and (link='hypo' OR link='Mprt' OR link='Mmem' OR link='Msub' OR link='Dmtc' OR link='Dmtu' OR link='Dmtr'  OR link='Hasi' OR link='Enta')"`;
  SSN="";
  SSN_JP="";
  SSN_EN="";
#ssn_line:00558630-n|00188183-n|hypo|eng30
#00558630-n|00188449-n|hypo|eng30
    SSN=`echo "$ssn_line"|while read line2;do
    echo "$line2"|awk -F\| '{print $2;}'|sed -e "s|-.*||";
done|tr "\n" " "`;
#    SSN_JP=`echo "$ssn_line"|while read line2;do
#    echo "$line2"|sed -e "s|.*<jp>||" -e "s|</jp>.*||" -e "s|-.*||";
#done|tr "\n" "-"|sed -e "s|-$||"`;
#    SSN_EN=`echo "$ssn_line"|while read line2;do
#    echo "$line2"|sed -e "s|.*<en>||" -e "s|</en>.*||" -e "s|-.*||";
#done|tr "\n" "-"|sed -e "s|-$||"`;
  no=`echo "$no"|sed -e "s|-.*||"`;
#echo "<NO>$no</NO><GOI>$goi</GOI><ENGOI>$engoi</ENGOI><OYA_NO>$OYA_NO</OYA_NO><OYA_GOI>$OYA_GOI</OYA_GOI><OYA_GOI_EN>$OYA_GOI_EN</OYA_GOI_EN><PAR>\"$OYA_GOI\" - \"$goi\"</PAR><DAN>$DAN</DAN><SSN>$SSN</SSN><SSN_JP>$SSN_JP</SSN_JP><SSN_EN>$SSN_EN</SSN_EN><BODY>$body</BODY><ENBODY>$enbody</ENBODY><KEIRO>$KEIRO</KEIRO><KEIRO_JP>$KEIRO_JP</KEIRO_JP><KEIRO_EN>$KEIRO_EN</KEIRO_EN>"|tee -a "$enjp2";
echo "<NO>$no</NO><GOI>$goi</GOI><ENGOI>$engoi</ENGOI><OYA_NO>$OYA_NO</OYA_NO><OYA_GOI>$OYA_GOI</OYA_GOI><OYA_GOI_EN>$OYA_GOI_EN</OYA_GOI_EN><PAR>\"$OYA_GOI\" - \"$goi\"</PAR><DAN>$DAN</DAN><SSN>$SSN</SSN><SSN_JP>$SSN_JP</SSN_JP><SSN_EN>$SSN_EN</SSN_EN><BODY>$body</BODY><ENBODY>$enbody</ENBODY><KEIRO>$KEIRO</KEIRO><KEIRO_JP>$KEIRO_JP</KEIRO_JP><KEIRO_EN>$KEIRO_EN</KEIRO_EN>"|tee -a "$enjp2";
#<sy>00002137-n</sy><jp>捨象</jp><en>abstract_entity</en>
#<sy>00023100-n</sy><jp>psychological_feature</jp><en>psychological_feature</en>
  
done < "enjp.xml"

}
main(){
  #parse1;
  parse2;


}


main;
