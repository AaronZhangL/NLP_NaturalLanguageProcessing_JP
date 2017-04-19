#!/bin/bash
#ほりうち作成

#!/bin/sh
###############
# kano_eikou.sh
###############
WLTH="WEBLIOTHESAURUS2"; 
WLRU="WEBLIORUIGO2"; 
RU="RENSORUIGO";
GOI="GOITAIKEI2";

function henkan(){
 local w="$1" s="$2" f="$3";
 gw=$(echo ${w:$s:$f});
 g=$(cat "$WLTH" |grep "<GOI>$gw</GOI>");
 if [ -n "$g" ];then
   echo "$g" |sed -e "s|^.*<BODY>||" -e "s|</BODY>.*$||"
 else
   #再帰でやろうと思ったけどやめた
   echo "マッチせず";
 fi
}
function searchgoi(){
  g=$(find WN -name "*$kw*"|while read l;do
    cat "$l";
  done);
  [[ -n "$g" ]] && echo "WORDNET:$g"; 
  g=$(cat "$GOI"|grep "<GOI>$kw</GOI>");
  if [ -n "$g" ];then
    echo "語彙体系:";
    echo "$g";
  else
    g=$(cat "$GOI"|grep "$kw");
    [[ -n "$g" ]] && echo "語彙体系:$g"; 
  fi
}
function searchruigo(){
  g=$(cat "$WLRU" |grep "<GOI>$kw</GOI>");
  if [ -n "$g" ];then
    echo "類義語:";
    echo "$g" |sed -e "s|^.*<BODY>||" -e "s|</BODY>.*$||"|sort|uniq;
    g=$(cat "$RU" |grep "<GOI>$kw</GOI>");
    echo "連想語:";
    echo "$g" |sed -e "s|^.*<BODY>||" -e "s|</BODY>.*$||"
    flg=2;  
  else
    g=$(cat "$RU" |grep "<GOI>$kw</GOI>");
    if [ -n "$g" ];then
      echo "連想語:";
      echo "$g" |sed -e "s|^.*<BODY>||" -e "s|</BODY>.*$||"
      flg=2;  
    else
      g=$(cat "$WLRU" |grep "$kw");
      echo "類義語:";
      echo "$g" |sed -e "s|^.*<BODY>||" -e "s|</BODY>.*$||"
      g=$(cat "$RU" |grep "$kw");
      echo "連想語:";
      echo "$g" |sed -e "s|^.*<BODY>||" -e "s|</BODY>.*$||"
      flg=2;  
    fi
  fi
}
function searchkana(){
  henkan "$kw" "0" "${#kw}";
  flg=1;  
}
function main(){
  # 入力があるまで無限ループ
  flg=0;
  while true ;  do
    case "$flg" in
      "0" ) echo -n "ひらがなを入力してください:" ;;
      "1" ) echo -n "検索文字列を表示してください:" ;;
      "2" ) echo -n "WORDNET・語彙体系を検索します:" ;;
    esac 
    # キーワード入力を促す部分
    # 標準入力からキーワードを読み込むコマンド (read) => 変数kwに格納される
    read kw
    # 変数kwが空文字なら無限ループする
    [[ "${kw}" == "" ]] && { flg="0"; continue; }
    #漢字が混じっていたらflg="1"にする
    [[ "$flg" == "0" ]] && {
      h=$(echo "${kw}"|sed -e "s|[ぁ-ん]||g");
      [[ -n "$h" ]] && flg="1"; 
    }
    # 入力があった場合、内容をチェック。"ぼくイケメン"なら正解
    [[ "${kw}" == "exit" ]] && { 
      echo "終了します"
      # ループを脱出
      break
    }
    #フラグに応じた検索をする
    case "$flg" in
      "0" ) searchkana ;;
      "1" ) searchruigo ;;
      "2" ) searchgoi ;;
    esac 
  done
}
main;
exit;
