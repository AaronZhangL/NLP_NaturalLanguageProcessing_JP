#
###############################################################
# オントロジー構築
###############################################################
#
# ※どこで使用されているのか不明
#
# 現在の階層のリストを渡すと一つ上のノードを見つける
# 再帰呼び出しされる
#
# 入力１: $TMP_DEPTH_LIST ( 引数、ファイル )
# 入力２: $NODE_DEPTH ( 引数、変数 )
# 入力３: $NODE_HISTORY ( 引数、変数 )
# 入力４: $TOTAL_SCORE ( 引数、変数 )
# 入力: $IS_HAS_TABLE ( 変数 )
# 入力: $TMP_HISTORY_LIST ( ファイル )
# 入力: $IS_HAS_TABLE_FIN ( 変数 )
# 
function func_search_pre_node (){
  local PRE_DEPTH_LIST="$1" ;
  local NODE_DEPTH=$(($2 + 1 ));
  local NODE_HISTORY="$3" ;
  local TOTAL_SCORE="$4" ;
  echo "$nextpath" | $awk  \
  -v PRE_DEPTH_LIST="$PRE_DEPTH_LIST" \
  -v NODE_DEPTH="$NODE_DEPTH" \
  -v NODE_HISTORY="$NODE_HISTORY" \
  -v TOTAL_SCORE="$TOTAL_SCORE" \
  -v ishs_table_fin="$ishs_table_fin" \
  -v ishs_table="$ishs_table" \
  '
  # 再帰処理関数
  function search_pre_node(node_depth,node_hist,ttl_score,predepath,
                           nextp_n, np, p, sahen,  ## ここからは、local変数
                           NODE_SCORE, a, EDGE_SCORE,
                           TMP_TOTAL_SCORE, TMP_NODE_HIST,
                           sahenNo, tmpdepath, matchword1, matchword2  ){
    # 次のノードのパス（現ノードをインクリメント）
    node_depth = node_depth + 1 ;
    #
    # MAIN処理部 パスリスト毎に処理を行う
    nextp_n=split(predepath , np , "|" ) ;
    for ( p = 1 ; p <= nextp_n ; p++ ){
    #  空の場合はスキップ
      if ( np[p] == "" ){
        continue ;
      }
      #
      # 左辺を抽出
      sahen=np[p] ;
      gsub(/->.*$/,"",sahen); 
      #
      # NODE_SCORE計算
      # IS_HAS_TABLE_FINからスコアを抽出
      NODE_SCORE= 0 ;
      for ( a = 1 ; a <= ih_tf_n ; a++ ){
        if (index(sa[a], sahen) > 0 ){
          NODE_SCORE = sa[a] ;
          gsub(/^.*comment=/, "" , NODE_SCORE ) ;
          gsub(/].*$/, "" , NODE_SCORE ) ;
          break ;
        }
      }
      if ( NODE_SCORE == "" ){ NODE_SCORE = 0 } ;
      #
      # EDGH_SCORE計算
      EDGE_SCORE = np[p] ;
      gsub(/^.*label=\"/,"",EDGE_SCORE); 
      gsub(/\" .*/,"",EDGE_SCORE); 
      if ( EDGE_SCORE == "" ){ EDGE_SCORE = 0 } ;
      #
      # TOTAL_SCORE に、NODE_SCORE,EDGE_SCOREを加算
      TMP_TOTAL_SCORE = ttl_score + NODE_SCORE + EDGE_SCORE ;
      #
      # 経路に、現在のNODEを追加
      TMP_NODE_HIST = sahen "->" node_hist ;
      #
      # 左辺の番号を取得
      # ＊左辺文字列だけでなく、文字列＋番号で検索するため
      sahenNo = np[p] ;
      gsub(/^.*comment=\"/,"",sahenNo); 
      gsub(/,.*$/,"",sahenNo); 
      #
      # IS_HAS_TABLEから、左辺に対応する上位ノードを探索
      tmpdepath = "";
      NODE_SCORE= 0 ;
      matchword1 = "," sahenNo "\"" ;
      matchword2 = "->" sahen ;
      for ( a = 1 ; a <= ih_t_n ; a++ ){
        if (index(saa[a], matchword1) > 0 ){
          if (index(saa[a], matchword2) > 0 ){
            tmpdepath = tmpdepath "|" saa[a] ;
          }
        }
      }
      #
      # 再帰呼び出し(対応する左辺の上位ノードがあった場合のみ)
      if ( tmpdepath != "" ){
        search_pre_node( node_depth , TMP_NODE_HIST , TMP_TOTAL_SCORE , tmpdepath);
      }
      #
      # 経路／スコアを出力(最終出力)
      printf "%.2f %s\n" , TMP_TOTAL_SCORE , TMP_NODE_HIST ; 
    }
  }
  BEGIN{
    # IS_HAS_TABLE_FIN 読み込み
    ih_tf_n=split(ishs_table_fin , sa , "|" ) ;
    # IS_HAS_TABLE 読み込み
    ih_t_n=split(ishs_table , saa , "|" ) ; 
  }
  {
    nextpath = $0 ;
    search_pre_node( NODE_DEPTH , NODE_HISTORY , TOTAL_SCORE ,nextpath);
  }
  ' ;
}

#
# 係り受けリストから、最も重要度の高い道を見つける。
#
# 入力１: $IS_HAS_TABLE ( 変数 )  係り受けの一覧
# 入力２: $IS_HAS_TABLE_FIN ( 変数 )  重要語の一覧
# 出力: $JUUYOU_LINE ( 変数 ) 最も重要度が高い道
#
# 係り受けリストを組み合わせて作成できるすべての文章に対し、
# 単語毎の重要度、係り受けの重要度、人名／地名／組織の重要度を合算する。
# これにより最も重要度の高い言葉がつながった文章が作成される。
#
#    係り受けリストを組み合わせて作成できるすべての文章に対し、単語毎の重要度、係り受けの重要度、人名／地名／組織の重要度を合算する。
#    これにより最も重要度の高い言葉がつながった文章が作成される。
#    
#    単語毎の重要度：上記重要語の抽出アルゴリズムを用いて算出
#    係り受けの重要度：cabochaコマンドで出力されたものを用いる
#    人名／地名／組織の重要度：単語毎の重要度が基本であるが、それが0である場合は1とする
#    例）
#    ■ 係り受けとその重要度リスト
#      "４点を"->"先取し" [label="3.09"]
#      "先取し"->"加点した" [label="0.00"]
#      "その後も"->"加点した" [label="3.10"]
#      "加点した"->"力尽きた" [label="0.00"]
#      "慶大は"->"力尽きた" [label="3.65"]
#      "３連投の"->"エース加藤幹" [label="0.32"]
#      "エース加藤幹"->"（４年" [label="0.00"]
#      "（４年"->"力尽きた" [label="0.00"]
#      "川和）が"->"力尽きた" [label="0.00"]
#    ■ 重要語リスト
#      エース加藤幹 1.59
#      慶大 3.00
#    ■ 人名リスト
#      加藤幹
#    ■ 地名リスト
#      川和
#    ■ 組織リスト
#      慶大
#    ■ 重要度の計算
#      "４点を"->"先取し"->"加点した"->"力尽きた"
#        (1)係り受けの計算
#           3.09 + 0.00 + 0.00 = 3.09
#        (2)重要語、人名、地名、組織の計算
#           0 + 0 + 0 + 0  = 0
#        (3) (1)と(2)の合計値
#           3.09 + 0 = 3.09
#        
#      "その後も"->"加点した"->"力尽きた"
#        (1)係り受けの計算
#           3.10 + 0.00 = 3.10
#        (2)重要語、人名、地名、組織の計算
#           0 + 0 + 0 = 0
#        (3) (1)と(2)の合計値
#           3.10 + 0 = 3.10
#        
#      "慶大は"->"力尽きた"
#        (1)係り受けの計算
#           3.65 = 3.65
#        (2)重要語、人名、地名、組織の計算
#           3.00 + 0 = 3.00
#        (3) (1)と(2)の合計値
#           3.65 + 3.00 = 6.65
#        
#      "３連投の"->"エース加藤幹"->"（４年"->"力尽きた"
#        (1)係り受けの計算
#           0.32 + 0.00 + 0.00 = 0.32
#        (2)重要語、人名、地名、組織の計算
#           0 + 1.59 + 0 + 0 = 0
#        (3) (1)と(2)の合計値
#           0.32 + 1.59 = 1.91
#        
#      "エース加藤幹"->"（４年"->"力尽きた"
#        (1)係り受けの計算
#           0.00 + 0.00 = 0.00
#        (2)重要語、人名、地名、組織の計算
#           1.59 + 0 + 0 = 0
#        (3) (1)と(2)の合計値
#           0.00 + 1.59 = 1.59
#        
#      "川和）が"->"力尽きた"
#        (1)係り受けの計算
#           0.00 = 0.00
#        (2)重要語、人名、地名、組織の計算
#           1 + 0 = 1.00
#        (3) (1)と(2)の合計値
#           0.00 + 1.00 = 1
#        
#    文章ごとに点数を上記のように計算した結果、
#    最も合計値が高い「"慶大は"->"力尽きた"」を要約文とする。
# 
#
# 現段階ではシェルでファイル出力ありで書く。
# 動きが完成したらawkに置き換える
# -> awkへの移植完了
#
function makeGraph.JUUYOU_LINE(){
  ## makeDigraph で定義していたが、ここでやるべき。重要度の一覧
  IS_HAS_TABLE_FIN=`echo -e "$IS_TABLE_FIN\n$HAS_TABLE_FIN" | LANG=C sort -s -k1 -u` ; 
  #echo "$IS_HAS_TABLE_FIN" ; #debug
  #echo "$IS_HAS_TABLE" ; #debug
  # IS_HAS_TABLE_FIN,IS_HAS_TABLEを１行で変数化
  ishs_table_fin=$(echo "$IS_HAS_TABLE_FIN" | tr "\n" "|" );
  ishs_table=$(echo "$IS_HAS_TABLE" | tr "\n" "|" ); 
  NODE_DEPTH=1;
  HISTORY_LIST="${TMP}/HISTORY_LIST" ;
  TMP_HISTORY_LIST="${TMP}/HISTORY_LIST.tmp" ;
  :>$TMP_HISTORY_LIST ;
  # スタート位置は一番下のノード
  TAIL_POSITION=`echo "$IS_HAS_TABLE" | tail -n1 | sed -e "s/^.*->//g" -e "s|\[label.*||g"` ;
  TMP_DEPTH_LIST="${TMP}/NODE_${NODE_DEPTH}_LIST" ;
  uhenNo=`echo "$IS_HAS_TABLE" | tail -n1 | sed -e "s/^.*comment=.*,//g" -e "s|\" pen.*$||g"` ;
  #echo "$IS_HAS_TABLE" |LANG=C grep -i ",${uhenNo}\" pen"| LANG=C grep -i "\->${TAIL_POSITION}" > "$TMP_DEPTH_LIST"
  nextpath=`echo "$IS_HAS_TABLE" |LANG=C grep -i ",${uhenNo}\" pen"| LANG=C grep -i "\->${TAIL_POSITION}" | tr "\n" "|" `;
  #echo "depth $NODE_DEPTH 終了" ;
  # 現在の階層のリストを渡すと一つ上のノードを見つける
  #func_search_pre_node "$TMP_DEPTH_LIST" "$NODE_DEPTH" "$TAIL_POSITION" "0";
  RESULTLINE=`func_search_pre_node "$TMP_DEPTH_LIST" "$NODE_DEPTH" "$TAIL_POSITION" "0"`;
  
  #cat "$TMP_HISTORY_LIST" | sort -n > "$HISTORY_LIST" ;
  echo  "$RESULTLINE" | LANG=C sort -s -k1 -n > "$HISTORY_LIST" ;
  #cat "$HISTORY_LIST" ; #debug
  # 重要度が最も高い道が決定
  JUUYOU_LINE=$(tail -n1 $HISTORY_LIST | $awk '{ print $2; }' );
  #JUUYOU_LINE=$(tail -n1 $HISTORY_LIST | $awk '{ print $2; }' | sed -e 's|"|\\\"|g');
  # 例
  #JUUYOU_LINE="\\\"早大が\\\"->\\\"果たした\\\"->\\\"上回った\\\"->\\\"決めた\\\"->\\\"リーグ戦初完封\\\"->\\\"挙げた\\\"->\\\"加点した\\\"->\\\"力尽きた\\\"";
  if [ $DEBUG == "TRUE" ]; then echo "JUUYOU_LINE : $JUUYOU_LINE" ; fi
}
#
# HAS_TABLEとTERMEXを重ねる # IS_TABLEの各要素について、以下の条件で出力する
# ・重要後(TERMEXに合致)
# ・色設定(HASCOLOR_TABLEに合致)
#   ＊重要語スコアが０、及び色設定がされている場合、
#     重要語スコアは１として出力する
#
# 入力１: $TERMEX ( 変数 ) # 入力２: $HAS_TABLE ( 変数 ) # 入力３: $HASCOLOR_TABLE ( 変数 )
# 出力: $HAS_TABLE_FIN ( 変数 )
#
#HAS_TABLE_FIN
#"１０日"[peripheries=1 color=yellow label="１０日<BR>(0)" comment=1]
#"適時打と"[peripheries=1  label="適時打と<BR>(1.41)" comment=1.41]
#"松本（３年"[peripheries=1 color=red label="松本（３年<BR>(0)" comment=1]
#"エース加藤幹"[peripheries=1 color=red label="エース加藤幹<BR>(1.59)" comment=1.59]
#"リーグ戦初完封"[peripheries=1  label="リーグ戦初完封<BR>(1.68)" comment=1.68]
#"明治神宮大会への"[peripheries=1 color=blue label="明治神宮大会への<BR>(1.59)" comment=1.59]
#
function makeGraph.HAS_TABLE_FIN(){
  COLOR_TMP=$(echo "$HASCOLOR_TABLE" | tr "\n" " " );
  #HAS_TABLE_FIN=`echo "$HAS_TABLE" | $awk '
  HAS_TABLE_FIN=`echo "$HAS_TABLE" | awk '
  BEGIN{
    icolor=1;
    RtableNum=split("'"$RTABLE"'",ratbl, ":");
    for ( i=1; i<=RtableNum; i++){
      split(ratbl[i],rtmp," ");
      Rcount[rtmp[2]]=rtmp[1];
    }
    split("'"$COLOR_TMP"'" , tcolor , " " );
  }
  {
    has_table=$0; 
    split( tcolor[icolor] , col , "," );
    COLOR = col[1] ;  # 色設定を取得
    # 重要後スコアを取得
    EXSCORE = col[2] ; 
    gsub ( /EXTERM:/, "", EXSCORE) ;
    # NODEから、" を除去し、LABEL情報を生成
    _label = has_table ;
    gsub( /"/ , "" , _label );
    RCNT=Rcount[_label];
    if (RCNT != ""){
      rc=sprintf("%.2f" ,RCNT);
      RCNT="R"rc; 
  
    }
    ex=sprintf("%.2f" ,EXSCORE);
    LABEL = "label=\"" _label "<BR>" "(T" ex RCNT ")\"";
    COMMENT = "comment=" EXSCORE ;
    # COLOR設定がNONEの場合は、設定値を削除
    if ( COLOR == "NONE" ){
      COLOR="" ;
    } 
    # 重要後スコアの小数点を切り下げ
    gsub ( /\.../, "", EXSCORE) ;
    # 色設定有りで、重要語スコアが０の場合は、
    # スコア最小値「１」を設定
    if ( COLOR != "" && EXSCORE == 0 ){
      EXSCORE = 1;
      COMMENT = "comment=" EXSCORE ;
    }
    # 色設定有り  もしくは  重要語スコア有り
    # の場合、NODE情報を出力
    if ( COLOR != ""  || EXSCORE != 0 || RCNT != ""){
          print  has_table  "[peripheries=" EXSCORE  " " COLOR " " LABEL " " COMMENT "]"
    }
    icolor++;
  }' | LANG=C sort -s -k1 -u` ;
  if [ $DEBUG == "TRUE" ]; then echo "HAS_TABLE_FIN : $HAS_TABLE_FIN" ; fi
}
#
# IS_TABLEとTERMEXを重ねる
# 入力１: $TERMEX ( 変数 ) # 入力２: $IS_TABLE ( 変数 ) # 入力３: $COLOR_TABLE ( 変数 )
# 出力: $IS_TABLE_FIN ( 変数 )
#
# IS_TABLE_FIN
#"本田"[peripheries=1 color=red label="本田<BR>(0)" comment=1]
#"明大と"[peripheries=1 color=green label="明大と<BR>(0)" comment=1]
#"１０日"[peripheries=1 color=yellow label="１０日<BR>(0)" comment=1]
#"１１月"[peripheries=1 color=yellow label="１１月<BR>(0)" comment=1]
#"３０日"[peripheries=1 color=yellow label="３０日<BR>(0)" comment=1]
#"斎藤は"[peripheries=2 color=red label="斎藤は<BR>(2)" comment=2]
#"慶大に"[peripheries=3 color=green label="慶大に<BR>(3)" comment=3]
#"慶大は"[peripheries=3 color=green label="慶大は<BR>(3)" comment=3]
#"早大が"[peripheries=3 color=green label="早大が<BR>(3)" comment=3]
# * label中の<BR>は、必要に応じて改行へ置き換えて利用する
#
# IS_TABLEの各要素について、以下の条件で出力する
# ・重要後(TERMEXに合致)
# ・色設定(COLOR_TABLEに合致)
#   ＊重要語スコアが０、及び色設定がされている場合、
#     重要語スコアは１として出力する
#
function makeGraph.IS_TABLE_FIN(){
  COLOR_TMP=$(echo "$COLOR_TABLE" | tr "\n" " " );
  RTABLE=`echo "$HAS_TABLE"| LANG=C sort -s -k1 |uniq -c|sed -e "s|\"||g"|tr "\n" ":"`;
  #IS_TABLE_FIN=`echo "$IS_TABLE" | $awk '
  IS_TABLE_FIN=`echo "$IS_TABLE" | awk '
  BEGIN{
    icolor=1;
    RtableNum=split("'"$RTABLE"'",ratbl, ":");
    for ( i=1; i<=RtableNum; i++){
      split(ratbl[i],rtmp," ");
      Rcount[rtmp[2]]=rtmp[1];
    }
    split("'"$COLOR_TMP"'" , tcolor , " " );
  }
  {
    is_table=$0; 
    split( tcolor[icolor] , col , "," );
    COLOR = col[1] ;  # 色設定を取得
    # 重要後スコアを取得
    EXSCORE = col[2] ; 
    gsub ( /EXTERM:/, "", EXSCORE) ;
    # NODEから、" を除去し、LABEL情報を生成
    _label = is_table ;
    gsub( /"/ , "" , _label );
    RCNT=Rcount[_label];
    if (RCNT != ""){
      rc=sprintf("%.2f" ,RCNT);
      RCNT="R"rc; 
    }
    ex=sprintf("%.2f" ,EXSCORE);
    LABEL = "label=\"" _label "<BR>" "(T" ex RCNT ")\"";
    COMMENT = "comment=" EXSCORE ;
    # COLOR設定がNONEの場合は、設定値を削除
    if ( COLOR == "NONE" ){
      COLOR="" ;
    } 
    # 重要後スコアの小数点を切り下げ
    gsub ( /\.../, "", EXSCORE) ;
    # 色設定有りで、重要語スコアが０の場合は、
    # スコア最小値「１」を設定
    if ( COLOR != "" && EXSCORE == 0 ){
      EXSCORE = 1;
      COMMENT = "comment=" EXSCORE ;
    }
    # 色設定有り  もしくは  重要語スコア有り
    # の場合、NODE情報を出力
    if ( COLOR != ""  || EXSCORE != 0 || RCNT != ""){
          print  is_table  "[peripheries=" EXSCORE  " " COLOR " " LABEL " " COMMENT "]"
    }
    icolor++ ; 
  }' | LANG=C sort -s -k1 -u` ;
  if [ $DEBUG == "TRUE" ]; then echo "IS_TABLE_FIN : $IS_TABLE_FIN" ; fi
}
#
# $IS_TABLEと$HAS_TABLEをpasteコマンドで結合する
# ノード連携情報の最終リスト # HASがなければ出力しない
# 入力１: $HAS_TABLE ( 変数 ) # 入力２: $FILE_IS_TABLE ( ファイル ) # 出力: $IS_HAS_TABLE
#
#IS_HAS_TABLE
#"東京六大学野球秋季リーグは"->"あり"
#"３０日"->"あり"
#"神宮球場で"->"あり"
#"最終週の"->"３回戦が"
#"早大慶大"->"３回戦が"
#"３回戦が"->"あり"
#"あり"->"果たした"
#"早大が"->"果たした"
#"斎藤１年"->"果たした"
#"早稲田実の"->"活躍で"
#"活躍で"->"大勝し"
#"慶大に"->"大勝し"
#"７０で"->"大勝し"
#"大勝し"->"果たした"
#"３季連続４０度目の"->"優勝を"
#
function makeGraph.IS_HAS_TABLE(){
   FILE_COLOR="$TMP/color.txt" ;
   echo "$COLOR_TABLE" | $awk -F"," '{
     EDGE = $3 ;
     gsub(/EDGE:/ , "" , EDGE ) ;
     penwidth = EDGE + 1;
     myNoAndNextNo = $4 "," $5 ;
     printf "[label=\"%.2f\" comment=\"%s\" penwidth=%d]\n" , EDGE , myNoAndNextNo ,penwidth;
   }' > "$FILE_COLOR" 
  # IS_HAS_TABLE=`echo "$HAS_TABLE" | paste  "$FILE_IS_TABLE" - | sed -e "s/\t/->/g" | LANG=C grep -i -v "\->$"` ;
   IS_HAS_TABLE=`echo "$HAS_TABLE" | paste  "$FILE_IS_TABLE" -  | sed -e "s/\t/->/g" | paste - "$FILE_COLOR" | sed -e "s/\t/ /g"| LANG=C grep -i -v "\-> \[label"` ;
  if [ $DEBUG == "TRUE" ]; then echo "IS_HAS_TABLE : $IS_HAS_TABLE" ; fi
}
#
# $HASCOLOR_TABLEの作成
# 入力１: $IS_TABLE ( 変数 ) # 入力２: $NODEMAP ( 変数 ) # 出力１: $HASCOLOR_TABLE ( 変数 )
#
# HASCOLOR_TABLE
#  color=blue,EXTERM:1.83,EDGE:0.383102
#  color=yellow,EXTERM:0,EDGE:0.971905
#  color=blue,EXTERM:0,EDGE:2.401455
#  NONE,EXTERM:0,EDGE:1.533620
#  color=green,EXTERM:6,EDGE:1.868122
#  NONE,EXTERM:0,EDGE:0.000000
#  NONE,EXTERM:0,EDGE:1.961707
#  color=green,EXTERM:3,EDGE:2.674352
#  ＊詳細
#   1:COLOR:色情報
#   2:EXTERM:重要語スコア
#   3:EDGE:係り受けスコア
#
# cabocha出力結果に対し、 地名／人名／組織の場合はカラーコードを設定
#  B-LOCATION    (地域):"color=blue"
#  B-PERSON      (人名):"color=red"
#  B-ORGANIZATION(組織):"color=green"
#
function makeGraph.HASCOLOR_TABLE(){
  COLOR_TMP=$(echo "$COLOR_TABLE" | tr "\n" " " );
  #HASCOLOR_TABLE=`echo "$NODEMAP" | $awk -F " " '
  HASCOLOR_TABLE=`echo "$NODEMAP" | awk -F " " '
    BEGIN {
      HAS="" ;
      split("'"$COLOR_TMP"'" , tcolor , " " );
    } {
      HAS=$2 ;
      if ( tcolor[HAS+1] != "" ){
        print tcolor[HAS+1] ;
      }
    }' ` ;
  if [ $DEBUG == "TRUE" ]; then echo "HASCOLOR_TABLE : $HASCOLOR_TABLE" ; fi
}
#
# $HAS_TABLEの作成
# 入力１: $IS_TABLE ( 変数 ) # 入力２: $NODEMAP ( 変数 )
# 出力１: $HAS_TABLE ( 変数 ) # 出力２: $FILE_IS_TABLE ( ファイル )
#
#HAS_TABLE
#"決めた"
#"決めた"
#"１０日"
#"開幕の"
#"明治神宮大会への"
#"出場も"
#"決めた"
#"リーグ戦初完封"
#"リーグ戦初完封"
#"ツーシームなどの"
#"変化球が"
#"さえ"
#
function makeGraph.HAS_TABLE(){
   FILE_IS_TABLE="$TMP/is_table.tmp" ;
   echo "$IS_TABLE" > $FILE_IS_TABLE;
   HAS_TABLE=`echo "$NODEMAP" | $awk -F " " '
     BEGIN {
        HAS="" ;
     } {
       HAS=$2 ;
       COUNTER=0 ; 
       while (getline line < "'$FILE_IS_TABLE'" > 0) {
          if ( HAS == COUNTER && line != "") {
             print line ;
          } 
          COUNTER++ ;
       }
       close("'$FILE_IS_TABLE'");
     }' ` ;
  if [ $DEBUG == "TRUE" ]; then echo "HAS_TABLE : $HAS_TABLE" ; fi
}
#
# IS_TABLEに対応するCOLOR_TABLEの作成
# 入力: $NODEMAP ( 変数 ) # 出力: $COLOR_TABLE ( 変数 )
# COLOR_TABLE
#  color=blue,EXTERM:1.83,EDGE:0.383102
#  color=yellow,EXTERM:0,EDGE:0.971905
#  color=blue,EXTERM:0,EDGE:2.401455
#  NONE,EXTERM:0,EDGE:1.533620
#  color=green,EXTERM:6,EDGE:1.868122
#  NONE,EXTERM:0,EDGE:0.000000
#  NONE,EXTERM:0,EDGE:1.961707
#  color=green,EXTERM:3,EDGE:2.674352
#  ＊詳細
#   1:COLOR:色情報
#   2:EXTERM:重要語スコア
#   3:EDGE:係り受けスコア
#
# cabocha出力結果に対し、
# 地名／人名／組織／日付の場合はカラーコードを設定
#  B-LOCATION    (地域):"color=blue"
#  B-PERSON      (人名):"color=red"
#  B-ORGANIZATION(組織):"color=green"
#  B-DATE        (日付):"color=yellow"
#
function makeGraph.COLOR_TABLE(){
   COLOR_TABLE=`echo "$NODEMAP" | $awk -F " " '
      BEGIN{
         IS="" ;
         COLOR[0]="" ;
      } {
         IS=$1 ;
         #COLOR[IS]=$4;
         COLOR[IS]=$4 "," $5 "," $6 "," $1 "," $2;
      } {
      } END {
         for ( i=0; i<NR; i++){
           if ( COLOR[i] != "" ){
             print COLOR[i] ;
           }
         }
      }'` ;
  if [ $DEBUG == "TRUE" ]; then echo "COLOR_TABLE : $COLOR_TABLE" ; fi
}
#
# IS_TABLEの作成
# 入力: $NODEMAP ( 変数 ) # 出力: $IS_TABLE ( 変数 )
function makeGraph.IS_TABLE(){
   IS_TABLE=$( echo "$NODEMAP" | $awk -F " " '
      BEGIN{
         IS="" ;
         NAME[0]="" ;
      } {
         IS=$1 ;
         NAME[IS]=$3 ;
      } {
      } END {
         for ( i=0; i<NR; i++){
           if( NAME[i] != "" ){
             print "\"" NAME[i] "\"" ;
           }
         }
      }' ) ;
  if [ $DEBUG == "TRUE" ]; then echo "IS_TABLE : $IS_TABLE" ; fi
}
#
# cabochaコマンドで係り受け解析
# 入力: $CABOCHA ( 変数 ) # 出力: $NODEMAP ( 変数 )
function makeGraph.NODEMAP(){
  #重要語スコアを準備
  FILE_TERMEX="$TMP/termex.tmp" ;
  echo "$TERMEX" > "$FILE_TERMEX";
  #出力辞書データ cabochaの-f1オプションで出力
  #NODEMAP=`echo "$CABOCHA" | $awk '
  NODEMAP=$( echo "$CABOCHA" | awk '
    function ex_impr(str) {
      ex_score = 0 ;
      lARTERM=length(ARTERM) ;
      #for ( j = 0 ; j < length(ARTERM) ; j++ ) {
      for ( j = 0 ; j < lARTERM ; j++ ) {
        if (index(str, ARTERM[j]) > 0 ){
          #ex_score = ex_score + ARSCORE[j];
          ex_score += ARSCORE[j];
        }
      }
      close( "'$FILE_TERMEX'");
      return ex_score ;
    }
    BEGIN {
      NODE = "" ;
      NODE2 = "" ;
      LABEL = "" ;
      EDGE = "" ;
      x = 0 ;
      i = 0;
      while ( getline termex < "'$FILE_TERMEX'" > 0 ) {
        split(termex, TERM, ",") ;
        ARTERM[i]  = TERM[1];
        ARSCORE[i] = TERM[2];
        i++ ;
      }
      close( "'$FILE_TERMEX'");
    } {
      #* 0 6D 5/6 0.383100 行頭が*ではじまっている
      if ( $0 ~ /^\*/ ){
      #*があるたびに書き出しちゃう
        if ( NODE != "" ) {
          EXSCORE = "EXTERM:" ex_impr(LABEL);
          ##NODEMAP_LIST[x] = NODE " " LABEL ;
          if ( COLOR == "" ){
            # 色設定されていない場合
            # 明示的に「NONE」を指定
            COLOR = "NONE" ;
          }
          if ( LABEL == "" ){
            LABEL = "  " ;
          }
          ##NODEMAP_LIST[x] = NODE " " LABEL " " COLOR;
          NODEMAP_LIST[x] = NODE " " LABEL " " COLOR " " EXSCORE " " EDGE;
          x++ ;
          NODE = "" ; 
          LABEL = "" ;   
          COLOR = "" ;
        }
        #ノードをパースして出力
        gsub ( /D$/, "", $3) ;
        NODE = $2 " " $3 ;
        EDGE = "EDGE:" $5 ;
      } else if ( $0 ~ /^EOS/ )  {
        # ページ最後尾にEOS文字列があるのでこのタイミングで最終を出力
        EXSCORE = "EXTERM:" ex_impr(LABEL);
        if ( COLOR == "" ){
          COLOR = "NONE" ;
        }
        if ( LABEL == "" ){
          LABEL = "  " ;
        }
        #NODEMAP_LIST[x]  = NODE " " LABEL ;      
        #NODEMAP_LIST[x]  = NODE " " LABEL " " COLOR;      
        NODEMAP_LIST[x]  = NODE " " LABEL " " COLOR " " EXSCORE " " EDGE;
        x++ ;
      } else if ( $0 ~ /名詞/ ||  /助詞/ || /形容詞/ || /動詞/ || /記号/) {
        if ( $0 ~ /読点/ || /句点/ || /空白/ ) {
          next ; 
      }else{
          
        LABEL = LABEL "" $1 ; 
        #
        # 地域／人名／組織  の分類の場合、
        # 色設定を行う
        split($2, hinshi, ",");
        if (index(hinshi[2], "地名") > 0 ){ # 地域
          COLOR="color=blue" ;
        }else if (index(hinshi[2], "人名") > 0 ){ # 人名
          COLOR="color=red" ;
        }else if (index(hinshi[2], "組織名") > 0 ){ # 組織
          COLOR="color=green" ;
        }else if ( $3 == "B-DATE" || $3 == "I-DATE" ){ # 組織
          COLOR="color=brown" ;
        }
      }
    }
  } END {
    for ( i=0; i <= NR ; i++ ) {
      if ( NODEMAP_LIST[i] != ""){
        print NODEMAP_LIST[i] ; 
      }
    }
  } ' ) ;
  if [ $DEBUG == "TRUE" ]; then echo "NODEMAP : $NODEMAP" ; fi
}
#
# 用語と頻度の対応表（変数）からタグを抜いてcsv形式にする
# 入力: $TERM_EXTRACT_RESULT_LINE ( 変数 ) # 出力: $TERMEX ( 変数 )
function makeGraph.TERMEX(){
    TERMEX=$( echo "$TERM_EXTRACT_RESULT_LINE" | $awk ' {
       gsub ( /<\/KEY>/, "</KEY>\n", $0) ;
       gsub ( /<KEY>/,  "", $0) ;
       gsub ( /<SCORE>/, ",", $0) ;
       gsub ( /<\/SCORE><\/KEY>/, "", $0) ;
       if ( $0 != "" ) {
         print $0 ;
       }
    }')  ;
  if [ $DEBUG == "TRUE" ]; then echo "TERMEX : $TERMEX" ; fi
}
#
##########################################################
# グラフの生成
##########################################################
#
function makeGraph(){
    makeGraph.TERMEX ;
    makeGraph.NODEMAP ;
    makeGraph.IS_TABLE ;
    makeGraph.COLOR_TABLE ;
    makeGraph.HAS_TABLE ;
    makeGraph.HASCOLOR_TABLE ;
    makeGraph.IS_HAS_TABLE ;
    makeGraph.IS_TABLE_FIN ;
    makeGraph.HAS_TABLE_FIN ;
    makeGraph.JUUYOU_LINE ;
}
#
