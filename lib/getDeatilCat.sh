#!/bin/bash
#カテゴリ抽出用サンプルプログラム

#まずは引数は単語１個
WORD=$1;
WDNF="GETCAT/enjp2.xml";
GOIF="GETCAT/GOITAIKEI3";
HOSEI="0.5";
LF=$'\\\x0A';

function search_wdn(){
  w=$1;
  #GOITAIKEIファイルにない場合はWORDONETファイルを検索する
  #子供から親へ日本語語彙体系ファイルにマッチするまで上に上がっていく
  #一旦マッチしたらあとはsearch_goiの処理に移行する
  cat "$WDNF" |grep -e "<GOI>$w " -e " $w " -e "$w</GOI>"|while read wline;do
    #echo "####wline:$wline######"
    echo "$wline" |sed -e "s|^.*<KEIRO_JP>||" -e "s|</KEIRO_JP>.*$||"|sed -e "s|-|$LF|g"|grep -v "^$"|tail -r |while read wline2;do
      #echo "####wline2:$wline2######";
      CATS=`search_goi "$wline2"`;
      if [ -n "$CATS" ];then
        echo "$CATS";
        break;
      fi
    done
  done;
}

function get_oya(){
  #親経路をたどるとりあえず最上段までたどってみた
  KGOI=$1;
  KSCORE=$2;
  oyaline=`cat "$GOIF" |grep "^<NO>$KGOI</NO>";` 
  ONO=`echo "$oyaline" | sed -e "s|^<NO>||" -e "s|</NO>.*||"`;
  OGOI=`echo "$oyaline" |sed -e "s|<WNS>.*</WNS>||"| sed -e "s|.*<GOI>||" -e "s|</GOI>.*||"`;
  ODAN=`echo "$oyaline" |sed -e "s|^.*<DAN>||" -e "s|</DAN>.*||"`;
  OOYA_NO=`echo "$oyaline" |sed -e "s|^.*<OYA_NO>||" -e "s|</OYA_NO>.*||"`;    
  if [ -n "$ONO" ];then
    #親経路のスコアは子供のスコアに補正値をかけたもの
    #とりあえず０．５にして階層が上がるごとにスコアが減るようにしてみた
    OSCORE=`echo "$KSCORE * $HOSEI" |bc`
    echo "$ONO,$OGOI,$OSCORE,$ODAN"
  fi
  if [ -n "$OOYA_NO" ];then
    get_oya "$OOYA_NO" "$OSCORE";
  fi
}


function search_goi(){
  WORD=$1;
  #GOITAIKEIファイルをgrepする
  #日本語語彙体系のNO,GOI,DANを取得する
  #検索文字列のスコア（GOIとキーワードのWORDONETパス近似値）をスコアにする
  #親経路をたどる。
  #ユニーク処理してスコアを加算する
  cat "$GOIF" | grep -e "<GOI>$WORD " -e " $WORD " -e "$WORD</GOI>" |while read line;do
    NO=`echo "$line" | sed -e "s|^<NO>||" -e "s|</NO>.*||"`;
    GOI=`echo "$line" |sed -e "s|<WNS>.*</WNS>||"|sed -e "s|.*<GOI>||" -e "s|</GOI>.*||"`;
    DAN=`echo "$line" |sed -e "s|^.*<DAN>||" -e "s|</DAN>.*||"`;
    SCORE=`echo "$line" |grep "<WNS>" |sed -e "s|^.*<WNS>||" -e "s|</WNS>.*||"|sed -e "s|<WN>|$LF<WN>|g" |grep "<WN>" | while read line2;do
      echo "$line2" |grep -e "<GOI>$WORD " -e " $WORD " -e "$WORD</GOI>"|sed -e "s|^.*<SCORE>||" -e "s|</SCORE>.*$||" |grep -v "None"; 
    done |awk 'BEGIN{sum=0;}{sum+=$1}END{print sum}'`;
    echo "$NO,$GOI,$SCORE,$DAN";    
    OYA_NO=`echo "$line" |sed -e "s|^.*<OYA_NO>||" -e "s|</OYA_NO>.*||"`;    
    get_oya "$OYA_NO" "$SCORE";
  done 
}

function getDetailcat(){
  KEYS_RESULT_LINE="<KEYS><KEY>早大<SCORE>7.00</SCORE></KEY><KEY>大学野球<SCORE>6.24</SCORE></KEY><KEY>斎藤<SCORE>6.00</SCORE></KEY><KEY>連覇<SCORE>4.00</SCORE></KEY><KEY>東京<SCORE>4.00</SCORE></KEY><KEY>完封<SCORE>4.00</SCORE></KEY><KEY>三振<SCORE>4.00</SCORE></KEY><KEY>慶大<SCORE>3.00</SCORE></KEY><KEY>大学野球秋季リーグ<SCORE>1.83</SCORE></KEY><KEY>千葉経大付<SCORE>1.68</SCORE></KEY><KEY>リーグ戦<SCORE>1.68</SCORE></KEY><KEY>明治神宮大会<SCORE>1.59</SCORE></KEY><KEY>エース加藤幹<SCORE>1.59</SCORE></KEY><KEY>適時打<SCORE>1.41</SCORE></KEY><KEY>最終週<SCORE>1.41</SCORE></KEY><KEY>早稲田実<SCORE>1.41</SCORE></KEY><KEY>勝ち点<SCORE>1.41</SCORE></KEY></KEYS>";
  l=$(echo "$KEYS_RESULT_LINE"|sed -e "s/<KEYS>//g" -e "s/<\/KEYS>//g" -e "s/<KEY>//g" -e "s/<\/KEY>/\n/g" -e "s/<SCORE>/:/g" -e "s/<\/SCORE>//g"); 
  kwl=$(echo "$l"|awk -F: '{ print $1; }');
  #まず日本語語彙体系ファイルGOITAIKEIを検索する
  echo "$kwl" | tr ' ' '\n' |while read w;do
    #echo "w:$w"
    CATS=`search_goi "$w"`;
    if [ -n "$CATS" ];then
      echo "$CATS";
    else
    #GOITAIKEIになければwordnetを検索する
      #echo "wordnetを検索"
      search_wdn "$w"; 
    fi
  done |awk -F, '{
      cat_array[$1":"$2] += $3; 
    }END{
      for (key in cat_array) {
        print key":"cat_array[key]
      }
    }'|sort -t: -k3 -dr;
}
getDetailcat;
exit;
