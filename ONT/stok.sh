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
 w=$1;
 s=$2;
 f=$3;
 gw=$(echo ${w:$s:$f});
 g=$(cat "$WLTH" |grep "<GOI>$gw</GOI>");
 if [ -n "$g" ];then
   echo "$g" |sed -e "s|^.*<BODY>||" -e "s|</BODY>.*$||"
 else
   #再帰でやろうと思ったけどやめた
   echo "マッチせず";
 fi
}
# 入力があるまで無限ループ
flg=0;
while true ;  do
        case "$flg" in
          "0" ) echo -n "ひらがなを入力してください:" ;;
          "1" ) echo -n "検索文字列を表示してください:" ;;
          "2" ) echo -n "WORDNET・語彙体系を検索します:" ;;
        esac 
        # キーワード入力を促す部分
        
 
        # 標準入力からキーワードを読み込むコマンド (read) => 変数KEYWORDに格納される
        read KEYWORD
 
        # 変数KEYWORDが空文字なら無限ループする
        if [ "${KEYWORD}" == "" ];then
                # ループの先頭に戻る
                flg="0";
                continue
        fi
        if [ "$flg" = 0 ];then
          #漢字が混じっていたらflg="1"
          h=$(echo "${KEYWORD}"|sed -e "s|[ぁ-ん]||g");
          if [ -n "$h" ];then
            flg="1";
          fi
        fi
        
        # 入力があった場合、内容をチェック。"ぼくイケメン"なら正解
        if [ "${KEYWORD}" == "exit" ];then
                echo "終了します"
                # ループを脱出
                break
        fi

        if [ "$flg" = "0" ];then
          henkan "$KEYWORD" "0" "${#KEYWORD}";
          flg=1;  
          continue;
        elif [ "$flg" = "1" ];then
            g=$(cat "$WLRU" |grep "<GOI>$KEYWORD</GOI>");
            if [ -n "$g" ];then
              echo "類義語:";
              echo "$g" |sed -e "s|^.*<BODY>||" -e "s|</BODY>.*$||"
              g=$(cat "$RU" |grep "<GOI>$KEYWORD</GOI>");
              echo "連想語:";
              echo "$g" |sed -e "s|^.*<BODY>||" -e "s|</BODY>.*$||"
              flg=2;  
            else
              g=$(cat "$RU" |grep "<GOI>$KEYWORD</GOI>");
              if [ -n "$g" ];then
                echo "連想語:";
                echo "$g" |sed -e "s|^.*<BODY>||" -e "s|</BODY>.*$||"
                flg=2;  
              else
                g=$(cat "$WLRU" |grep "$KEYWORD");
                echo "類義語:";
                echo "$g" |sed -e "s|^.*<BODY>||" -e "s|</BODY>.*$||"
                g=$(cat "$RU" |grep "$KEYWORD");
                echo "連想語:";
                echo "$g" |sed -e "s|^.*<BODY>||" -e "s|</BODY>.*$||"
                flg=2;  
              fi
            fi
          continue;
        elif [ "$flg" = "2" ];then
          g=$(find WN -name "*$KEYWORD*"|while read l;do
            cat "$l";
          done);
          if [ -n "$g" ];then
            echo "WORDNET:";
            echo "$g";
          fi
          g=$(cat "$GOI"|grep "<GOI>$KEYWORD</GOI>");
          if [ -n "$g" ];then
            echo "語彙体系:";
            echo "$g";
          else
            g=$(cat "$GOI"|grep "$KEYWORD");
            if [ -n "$g" ];then
              echo "語彙体系:";
              echo "$g";
            fi
          fi
          continue;
        fi
done

