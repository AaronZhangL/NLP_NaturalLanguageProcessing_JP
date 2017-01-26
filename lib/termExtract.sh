#
#########################################################
# 重要語抽出
# termExtract.sh 
# 重要語解析計算処理は calcImp.sh
#########################################################
#
#
# bash版 すべてのKEYをuniqしてスコアを振り直す
# 入力１: $TERM_EXTRACT_RESULT_LINE ( 変数 )
# 入力２: $TITLE_KEYS_RESULT_LINE ( 変数 )
# 出力： $KEYS_RESULT_LINE ( 変数 )
function termExtract.Rescore.sh(){
  #  本文の最大値だけ取り出す（一番左側)
  DESCRIPTION_SCORE=$(echo "$TERM_EXTRACT_RESULT_LINE" | sed -e "s|</SCORE>.*$||g" -e "s|^.*<SCORE>||g") ;
  # 本文の最大値をタイトルのスコアに加算
  KEYS_TITLE=$(echo "$TITLE_KEYS_RESULT_LINE" | sed -e "s|</KEY>|</KEY>\n|g" | LANG=C grep -i -v "^$" |
    while read line; do 
      TITLE=$(echo "$line" | sed -e "s|^<KEY>||g" -e "s|<SCORE>.*$||g") ;
      TITLE_SCORE=$(echo "$line" | sed -e "s|^.*<SCORE>||g" -e "s|</SCORE>.*$||g") ;
      GT_SCORE=$( echo "$TITLE_SCORE"+"$DESCRIPTION_SCORE" | bc) ;
      echo "<KEY>$TITLE<SCORE>$GT_SCORE</SCORE></KEY>" ;
    done | head -n$TERMEX_ITEM_COUNT |  tr -d "\n"  ;
  );
  KEYS_RESULT_LINE=$(echo "<KEYS>${KEYS_TITLE}${TERM_EXTRACT_RESULT_LINE}</KEYS>") ;
  if [ $DEBUG == "TRUE" ]; then echo "KEYS_RESULT_LINE : $KEYS_RESULT_LINE" ; fi
}
#
# Awk版 # すべてのKEYをuniqしてスコアを振り直す
# 入力１: $TERM_EXTRACT_RESULT_LINE ( 変数 )
# 入力２: $TITLE_KEYS_RESULT_LINE ( 変数 )
# 出力： $KEYS_RESULT_LINE ( 変数 )
function termExtract.Rescore.awk(){
  #本文の最大値だけ取り出す（一番左側)
  DESCRIPTION_SCORE_MAX=$(echo "$TERM_EXTRACT_RESULT_LINE" | $awk '{
    gsub (/<\/SCORE>.*$/, "", $0) ;
    gsub (/^.*<SCORE>/, "", $0) ;
    print $0 ;
  }') ;
  #タイトルのスコアに本文の最大値を加算
  KEYS_TITLE=$(echo "$TITLE_KEYS_RESULT_LINE" | sed -e "s|</KEY>|</KEY>\n|g" | $awk '  /./ {
    TERM=$0 ;
    gsub(/<SCORE>.*$/, "", TERM) ;
    gsub(/^.*<KEY>/, "", TERM) ;
    gsub(/<KEY>/, "", $0) ;
    gsub(/<\/KEY>/, "\n", $0) ;
    gsub(/^.*<SCORE>/, "", $0) ;
    gsub(/<\/SCORE>.*$/, "", $0) ;
    SCORE= $0 + '"$DESCRIPTION_SCORE_MAX"' ; #加算
    printf "<KEY>%s<SCORE>%.2f</SCORE></KEY>" , TERM , SCORE ;
  }' | $awk 'NR<='"$TERMEX_ITEM_COUNT"'');
  #KEYS_RESULT_LINE=$(echo "<KEYS>${KEYS_TITLE}${TERM_EXTRACT_RESULT_LINE}</KEYS>") ;
  KEYS_RESULT_LINE="<KEYS>${KEYS_TITLE}${TERM_EXTRACT_RESULT_LINE}</KEYS>" ;
  if [ $DEBUG == "TRUE" ]; then echo "KEYS_RESULT_LINE : $KEYS_RESULT_LINE" ; fi
}
#
# bash版 # 重要語リストと計算した重要度を変数に出力する
# 出力される重要語の数は以下のパラメータで制御
# in : $awkTermExtractList ; # out :$TermExtOut ; 
# $TERMEX_ITEM_COUNT # $1 : 見出しは空 本文はbc100が入る
function termExtract.execTerm.sh(){
  TermExtOut=$(echo "$awkTermExtractList" | \
    while read line;do
      #スコアを取り出す.小数点２桁にする
      local score=`echo $line| $awk '{print $1;}'`;
      score=`printf "%.2f" $score`;
      #重要語を表示用（単名詞区切なし）に加工
      local noun=`echo $line| $awk '{$1=""; print;}'|sed -e "s| ||g"`;
      #日付・時刻は表示しない
      if echo "$noun"|LANG=C grep -i -E '^(昭和)*(平成)*(\d+年)*(\d+月)*(\d+日)*(午前)*(午後)*(\d+時)*(\d+分)*(\d+秒)*$' > /dev/null ;then
        continue;
      fi
      #数値のみは表示しない
      if echo "$noun"|LANG=C grep -i '^[0-9]*$' >/dev/null ;then
        continue;
      fi
      #$1パラメータにbc100があれば抑制対象とする
      #見出しは全ての重要語を出力するが、本文は1.00以上の重要語を出力（新規追加）
      if [ "$1" = "bc100" ]; then
        #$scoreが1.00以上であれば出力（新規追加）
        if [ $(echo "$score > 1" | bc ) -eq 1 ]; then
          echo "<KEY>$noun<SCORE>$score</SCORE></KEY>";
        fi
      else
          echo "<KEY>$noun<SCORE>$score</SCORE></KEY>";
      fi
    done | head -n$TERMEX_ITEM_COUNT |  tr -d "\n"  ;
  );
  if [ $DEBUG == "TRUE" ]; then echo "TermExtOut : $TermExtOut" ; fi
}
#
# Awk版 # 重要語リストと計算した重要度を変数に出力する
# 入力： <score> <key>
#  1.41421 大学 野球
#  1 連覇
#  1 東京
# scoreは小数点２桁で出力する # 件数はTERMEX_ITEM_COUNT=10件まで出力
# 入力１: $awkTermExtractList ( 変数 ) # 入力２: $output_mode ( 変数 ) ## VOID ##
# 入力３: $TERMEX_ITEM_COUNT ( 変数 ) # 出力: $TermExtOut ( 変数 ) 
# 
function termExtract.execTerm.awk(){
  TermExtOut=$(echo "$awkTermExtractList" | $awk '
    BEGIN{
      bc100="'$1'" ;
    } {
      score=$1 ; #スコアを取り出す
      $1=""; #重要語を表示用（単名詞区切なし）に加工
      noun=$0 ;
      gsub( /[[:blank:]]/ , "" , noun ) ;
      #日付・時刻・数字のみは表示しない
      if (noun ~ /^(昭和)*(平成)*([0-9]+年)*([0-9]+月)*([0-9]+日)*(午前)*(午後)*([0-9]+時)*([0-9]+分)*([0-9]+秒)*$/) {
        next; 
      } else if (noun ~ /^[0-9]*$/) {
        next; 
      }
      if ( bc100 == "bc100" ){ 
        if ( score > 1 ){ #本文はbc100によりscore1以上だけを出力(※新規追加）
          printf "<KEY>%s<SCORE>%.2f</SCORE></KEY>" , noun , score ;
        }
      }else{ #見出しはすべてを出力(※新規追加）
        printf "<KEY>%s<SCORE>%.2f</SCORE></KEY>" , noun , score ;
      }
    }' | $awk 'NR<='"$TERMEX_ITEM_COUNT"'') ;
  if [ $DEBUG == "TRUE" ]; then echo "TermExtOut : $TermExtOut" ; fi
}
#
function termExtract.get_imp_word_while.sh(){
      line="$@" ;
      source terms.tmp ;
      part_of_speach=`echo "${line}"| sed -e "s/\,.*$//g" -e "s/^.* //g"` ;
      noun=`echo "${line}"| sed -e "s/ .*$//g"`;
      cl_1=`echo "${line}"| sed -e "s/^[^\,]*\,//g" -e "s/\,.*$//g"`;
      if [ "$part_of_speach" == "名詞" ]; then 
        cl_2=`echo "${line}"| sed -e "s/^.* //g" | $awk -F ',' '{ print $3 ; }'`;
        if [  \( "$cl_1" == "一般" -o  "$cl_1" == "サ変接続" -o "$cl_1" == "固有名詞" -o  \( "$cl_1" == "接尾"  -a \( "$cl_2" == "一般" -o "$cl_2" == "サ変接続" \) \) \) ]; then
          echo "terms=\"$terms $noun\"; must=\"0\"; " > terms.tmp ;
          return  ;
        elif [ \( \( "$cl_1" == "接尾" -a "$cl_2" == "形容動詞語幹" \) -o  "$cl_1" == "形容動詞語幹" -o  "$cl_1" == "ナイ形容詞語幹" \) ]; then
          echo "terms=\"$terms $noun\"; must=\"1\"; " > terms.tmp ;
          return ;
        else
          if [ "$must" == "0" ] ;then
             terms=$(echo "$terms" | sed -e "s/^ //g" -e "s/ $//g" -e "s/^本 //g" -e "s/ など$//g" -e "s/ ら$//g" -e "s/ 上$//g" -e "s/ 内$//g" -e "s/ 型$//g" -e "s/ 間$//g" -e "s/ 中$//g" -e "s/ 毎$//g" -e "s/ 等$//g");
             must="0" ; 
            if [ ! -z "$terms" ] ;then 
              echo "$terms"; 
            fi
            echo "terms=\"\"; must=\"0\"; " > terms.tmp ;
          fi
        fi 
      elif [ "$part_of_speach" == "記号" -a "$cl_1" == "アルファベット" ]; then
          echo "terms=\"$terms $noun\"; must=\"0\";" > terms.tmp
          return  ;
      elif [ "$part_of_speach" == "動詞" ]; then
         echo "terms=\"\"" > terms.tmp
      else 
        if [ "$must" == "0" ] ;then
           terms=$(echo "$terms" | sed -e "s/^ //g" -e "s/ $//g" -e "s/^本 //g" -e "s/ など$//g" -e "s/ ら$//g" -e "s/ 上$//g" -e "s/ 内$//g" -e "s/ 型$//g" -e "s/ 間$//g" -e "s/ 中$//g" -e "s/ 毎$//g" -e "s/ 等$//g");
           must="0" ;
          if [ ! -z "$terms" ] ;then 
            echo "$terms"; 
            :>terms.tmp ;
          fi
           echo "terms=\"\"; must=\"0\"; " > terms.tmp ;
        else
          :>terms.tmp ;
        fi
      fi
      #名詞でも形容動詞は重要語としてとりこまない
      if [ "$must" == "1" ] ; then
         echo "terms=\"\"; must=\"0\"; " > terms.tmp ;
      fi
}
#
# bash版 # 重要度取得
# 入力:$MECAB_OUT # 出力:$comNounList
function termExtract.get_imp_word.sh(){
  export -f termExtract.get_imp_word_while.sh  ;
  :>terms.tmp ;
  comNounList=$( echo "$MECAB_OUT" | nkf -Ew  | if [ -n "${TMP}" ] || [ "${reset_get_word}" = "1" ] ; then
    while read line ;do
      #echo "$line" | xargs -P6 -I % /bin/bash -c "termExtract.get_imp_word_while.sh %" ; 
      termExtract.get_imp_word_while.sh $line ;
    done | LANG=C sort -s -k1 | uniq -c | sed -e "s/^ *//g" ;
    elif [ "${LR}" = "0" ] && [ "${frq}" = "0" ] ; then
     exit;
    elif [ "${get_word_done}" = "0" ] ; then
      exit;
    fi 
  );
  if [ $DEBUG == "TRUE" ]; then echo "comNounList : $comNounList" ; fi
}
#
# Awk版 # 重要度取得
# 入力:$MECAB_OUT # 出力:$comNounList
#
#1 完封
#1 三振
#1 斎藤
#1 東京
#1 大学 野球
#1 連覇
#1 早大
#
function termExtract.get_imp_word.awk(){
  comNounList=$( echo "$MECAB_OUT" | nkf -Ew | $awk '
  BEGIN{
    get_word_done = "'$get_word_done'" ;
    LR = "'$LR'" ;
    frq = "'$frq'" ;
    TMP = "'$TMP'" ;
    if ( LR == 0 && frq == 0 ){
      exit;     # LR でも頻度でも重要度計算しないときは強制終了
    } else if ( TMP  != "" || reset_get_word == 1 ){
      # 処理継続
    } else if ( get_word_done == 0 ) {
      exit;
    }
  } {
    noun=$1;    #単語の解析結果 名詞,一般,*,*,*,*,大学,ダイガク,ダイガク
    val=$2;     #単語解析結果から先頭３つ（品詞,品詞細分類1,品詞細分類2）を抽出
    part_of_speach="";
    cl_1="";
    cl_2="";
    split(val , hArray, ",");
    if ( val != "" ) {
      part_of_speach=hArray[1]; #名詞
      cl_1=hArray[2];           #一般
      cl_2=hArray[3];           #サ変接続
    }
    if ( part_of_speach == "名詞" && (cl_1 == "一般" ||  cl_1 == "サ変接続" || cl_1 == "固有名詞" ||  ( cl_1 == "接尾"  && (cl_2 == "一般" || cl_2 == "サ変接続")) ) ){
      terms = terms " " noun; must  = 0; next;
    } else if ( part_of_speach == "名詞" && ( (cl_1 == "接尾" && cl_2 == "形容動詞語幹") || cl_1 == "形容動詞語幹" || cl_1 == "ナイ形容詞語幹") ) {
      terms = terms " " noun; must  = 1; next;
    }else if ( part_of_speach == "記号" && cl_1 == "アルファベット") {
      terms = terms " " noun; must  = 0; next;
    } else if (part_of_speach == "動詞") {
      terms = "";
    } else {
      if ( must == "0") {
        gsub(/^ /, "", terms); gsub(/ $/, "", terms); gsub(/^本 /, "", terms); gsub(/ など$/, "", terms);
        gsub(/ ら$/, ""  terms); gsub(/ 上$/, "", terms); gsub(/ 内$/, "", terms); gsub(/ 型$/, "", terms);
        gsub(/ 間$/, "", terms); gsub(/ 中$/, "", terms); gsub(/ 毎$/, "", terms); gsub(/ 等$/, "", terms);
        if ( terms != "") {
          terms_hash[terms] += 1;
        }
        terms = "";
      }
    }
    if (must == "1") {  #名詞でも形容動詞は重要語としてとりこまない
      terms = ""; must  = "0";
    }
  } END {
    for (key in terms_hash) {
      print terms_hash[key] " " key;
    }
  }' ) ;
  reset_get_word=0; 
  if [ -z "$comNounList" ] ;then exit ; fi
  if [ $DEBUG == "TRUE" ]; then echo "comNounList : "; echo "$comNounList" ; fi
}
#
# 標準入力に渡された文章を「。」区切りで改行する
# 複数の空白を一つにする。 句点「。」があれば改行をいれる。
# 「」（）の中であれば句点があっても改行をいれない
# 入力: 標準入力 # 出力: 標準出力
function func_KutenKaigyo(){
  LC_ALL="" ;
  awk '{
    KAGK=0; MARK=0; MAHK=0;
    gsub(/[[:blank:]]+/, "  ", $0);
    num = split($0,sa,"");
    for ( a = 1; a <= num ; a++ ) {
      printf "%s" , sa[a] ;
      if ( sa[a] == "「" ){ KAGK=1; }
      else if ( sa[a] == "」" ){ KAGK=0; }
      else if ( sa[a] == "（" ){ MARK=1; }
      else if ( sa[a] == "）" ){ MARK=0; }
      else if ( sa[a] == "(" ){ MAHK=1; }
      else if ( sa[a] == ")" ){ MAHK=0; }
      else if ( sa[a] == "。" ){
        if ( (KAGK+MARK+MAHK) == 0 ){
          printf "\n" ;
        } 
      }
    }
  }END{
    printf "\n" ;
  }' < /dev/stdin
}
#
# $1を形態素解析 タイトル 本文を引数に取る
# in  $TITLE # in  $DESCRIPTION # out $MECAB_OUT ;
function termExtract.execMecab(){
  MECAB_OUT=$( echo "$1" | func_KutenKaigyo | nkf -We | "$MECAB" -b 4096 ) ;
  if [ $DEBUG == "TRUE" ]; then echo "MECAB_OUT : " ; echo "$MECAB_OUT" | nkf -wLu ; fi
}
function termExtract.storage_stat(){
#comNounList
#高校 野球 1
#早大 3
#秋季 野球 大会 2
  termExtract.dbopen "$stat_lock";
  termExtract.dbopen "$comb_lock";
  # 複合名詞を単名詞に分割して、連接情報を登録する
  # 文中の専門用語ごとにループ
  while read n_count;do
  #freq=2
  #cmp_noun=秋季 野球 大会
    local freq=`echo "$n_count"|awk '{print $1;}'`;
    local cmp_noun=`echo "$n_count"|awk '{$1="";print $0;}'|sed -e "s|^ ||"`;
    #空ならスキップ
    if [ "$cmp_noun" = "" ];then
      continue;
    fi
    #単語の文字数が長すぎたらスキップ
    if [ "${#cmp_noun}" -gt "$MAX_CMP_SIZE" ];then
      continue;
    fi
    org_noun_list_array=(`echo "$cmp_noun"`);
    noun_array=();
    uniq_pre="";
    total_pre="";
    uniq_post="";
    total_post="";
    # メソッド IgnoreWords で指定した語と数値を無視する
    for i in "${org_noun_list_array[@]}";do
      #数字.,だけとかはスキップ
      if echo "$i"|grep "^[0-9\.\,]*$" >/dev/null;then
        continue;
      fi
      if ! cat "$IgnoreWordsFile"|grep "^${i}$" >/dev/null;then
        noun_array+=($i);
      fi
    done
  #複合語の場合にDBに格納する
  # 「秋季 野球 大会」だったら「秋季」「野球」の2回まわる
    if [ ${#noun_array[*]} -gt 1 ];then
      local cnt=$((${#noun_array[@]} - 1));
      for ((i = 0; i < $cnt; i++)) {
  # ループ内で１個後ろの単語とくっつけて連接語にし、連接情報を登録
  # 「秋季 野球」「野球 大会」が連接語になる
  # comb_key 「秋季 野球」「野球 大会」
        comb_key="${noun_array[i]} ${noun_array[$(($i + 1))]}";# 2つの単名詞の組を生成
        # 連接語が初登場の場合 first_comb =1
        if cat "$comb_db"|grep "^$comb_key," >/dev/null;then
          first_comb="0";
        else
          first_comb="1";
        fi
        #  単名詞ごとの連接統計情報[Pre(N), Post(N)]を累積
        #
        # post word (後ろにとりうる単名詞）        
        # 前の名詞をpost word （後ろにとりうる単名詞）という
        # 「秋季 野球」だったら「秋季」
        # 「野球 大会」だったら「野球」
        # _post に頻度を加算する
        # uniq_pre +0
        # total_pre +0
        # uniq_post +0 or +1 「秋季 野球 」がcomb_db上初登場だったら +1
        # total_post +frq 「秋季 野球 大会」なら +2
        stat_db_noun=`cat "$stat_db"|grep "^${noun_array[i]},"`;
        if [ -n "$stat_db_noun" ];then
          uniq_pre=`echo "$stat_db_noun"|awk -F, '{print $2;}'`;
          total_pre=`echo "$stat_db_noun"|awk -F, '{print $3;}'`;
          uniq_post=`echo "$stat_db_noun"|awk -F, '{print $4;}'`;
          total_post=`echo "$stat_db_noun"|awk -F, '{print $5;}'`;
        else
          uniq_pre="0";
          total_pre="0";
          uniq_post="0";
          total_post="0";
        fi
        if [ "$first_comb" = 1 ];then
          uniq_post=$((${uniq_post} + 1));
        fi
        total_post=$((${total_post} + ${freq}));
        #stat_dbに書き込む
        echo "${noun_array[i]},$uniq_pre,$total_pre,$uniq_post,$total_post" > "${stat_db}.tmp"
        cat "${stat_db}"|grep -v "^${noun_array[i]}," >> "${stat_db}.tmp";
        /bin/mv "${stat_db}.tmp" "${stat_db}";
        # pre word　（前にとりうる単名詞）
        # 後ろの名詞をpre word（前にとりうる単名詞）という
        # 「秋季 野球」だったら「野球」
        # 「野球 大会」だったら「大会」
        # uniq_pre +0 or +1 「野球 大会」がcomb_db上初登場だったら +1
        # total_pre +frq 「秋季 野球 大会」なら +2
        # uniq_post +0
        # total_post +0
        stat_db_noun=`cat "$stat_db"|grep "^${noun_array[$(($i + 1))]},"`;
        if [ -n "$stat_db_noun" ];then
          uniq_pre=`echo "$stat_db_noun"|awk -F, '{print $2;}'`;
          total_pre=`echo "$stat_db_noun"|awk -F, '{print $3;}'`;
          uniq_post=`echo "$stat_db_noun"|awk -F, '{print $4;}'`;
          total_post=`echo "$stat_db_noun"|awk -F, '{print $5;}'`;
        else
          uniq_pre="0";
          total_pre="0";
          uniq_post="0";
          total_post="0";
        fi
        if [ "$first_comb" = 1 ];then
          uniq_pre=$((${uniq_pre} + 1));
        fi
        total_pre=$((${total_pre} + ${freq}));
        #stat_dbに書き込む
        #uniq_pre total_pre uniq_post total_post
        #秋季 0 0 +1 +2
        #野球 +1 +2 +1 +2
        #大会 +1 +2 0 0
        #  （uniq_pre uniq_post は連接語が初登場の場合のみ+1）
        echo "${noun_array[$(($i + 1))]},$uniq_pre,$total_pre,$uniq_post,$total_post" > "${stat_db}.tmp"
        cat "${stat_db}"|grep -v "^${noun_array[$(($i + 1))]}," >> "${stat_db}.tmp";
        /bin/mv "${stat_db}.tmp" "${stat_db}";

        #comb_dbに書き込む
        #「秋季 野球 大会」なら 「秋季 野球」「野球 大会」を登録する。
        #秋季 野球 +2
        #野球 大会 +2
        comb_db_comb_key=`cat "$comb_db" |grep "^$comb_key,"`;
        if [ -n "$comb_db_comb_key" ];then
          comb_key_freq=`echo "$comb_db_comb_key"|awk -F, '{print $2;}'`;
          comb_key_freq=$((${comb_key_freq} + ${freq})); 
          echo "$comb_key,$comb_key_freq" >> "${comb_db}.tmp";
          cat "${comb_db}"|grep -v "^$comb_key," >> "${comb_db}.tmp"
          /bin/mv "${comb_db}.tmp" "${comb_db}";
        else
          echo "$comb_key,$freq" >> "${comb_db}";
        fi
      }
    fi
  done < <(echo "$comNounList")
  termExtract.dbclose "$stat_lock";
  termExtract.dbclose "$comb_lock";
}
function termExtract.dbclose(){
  local lock="$1";
  /bin/rm -f "$lock";
}
function termExtract.dbopen(){
  local lock="$1";
  local cnt="0";
  #lock_timeout秒たったらシカトして前へ進む
  while [ $cnt -lt $lock_timeout ];do
    if [ -e "$lock" ];then
      sleep "1";
      cnt=$(($cnt + 1));
      continue;
    else
      touch "$lock";
      break;
    fi
  done
}

# ========================================================================
# storage_df -- storage compound noun to Data Base File
# (DF [Document Frequency]DBの情報を蓄積）
# 
# ========================================================================
function termExtract.storage_df(){
#DF [Document Frequency]DB
#統計用のデータで重要度計算では使用しない
#単語（複合名詞も分割しない）の登場頻度を登録していく
#ついでに今まで登録した文書の総数も登録しとく
#
#高校 野球 1
#早大 3
#秋季 野球 大会 1
#文書総数 12
  termExtract.dbopen "$df_lock";
  while read cmp_noun;do
    #空ならスキップ
    if [ "$cmp_noun" = "" ];then
      continue;
    fi
    #単語の文字数が長すぎたらスキップ
    if [ "${#cmp_noun}" -gt "$MAX_CMP_SIZE" ];then
      continue;
    fi
    #
    cmp_noun_word=`echo "$cmp_noun"|awk '{$1="";print $0;}'|sed -e "s|^ ||"`;
    #単語を登録し、頻度を加算する(複数回登場しても１加算するだけfrq見ない)
    df_noun=`cat "$df_db"|grep "^$cmp_noun_word,"`;
    if [ -n "$df_noun" ];then
      df_noun_word=`echo "$df_noun"|awk -F, '{print $1;}'`;
      df_noun_freq=`echo "$df_noun"|awk -F, '{print $2;}'`;
      df_noun_freq=$(($df_noun_freq + 1));
      echo "$df_noun_word,$df_noun_freq" > "${df_db}.tmp";
    else
      echo "$cmp_noun_word,1" > "${df_db}.tmp";
    fi
    cat "$df_db"|grep -v "^$cmp_noun_word," >> "${df_db}.tmp";
    /bin/mv "${df_db}.tmp" "${df_db}";
  done < <(echo "$comNounList")
  # 文書数は#のハッシュで集計
  docs=`cat "$df_db"|grep "^#,"`;
  if [ -n "$docs" ];then
    docs_freq=`echo "$docs"|awk -F, '{print $2;}'`;
    docs_freq=$(($docs_freq + 1));
    echo "#,$docs_freq" > "${df_db}.tmp";
  else
    echo "#,1" > "${df_db}.tmp";
  fi
  cat "$df_db"|grep -v "^#," >> "${df_db}.tmp";
  /bin/mv "${df_db}.tmp" "${df_db}";
  termExtract.dbclose "$df_lock";
}
#
function termExtract.storage(){
  if [ "$storage_mode" = 1 -o "$storage_df" = "" ];then
    # 学習用DBにデータを蓄積
    if [ "$storage_df" = "1" ];then
    #単語の頻度を格納する（格納するだけで使ってない気が）
      termExtract.storage_df;
    elif [ "$LR" != "0" ];then
    #複合名詞の連接情報を格納する。
      termExtract.storage_stat;
    fi
  fi 
}
function termExtract(){
    termExtract.execMecab "$TITLE"; # 見出しの形態素解析
    termExtract.get_imp_word.awk;   # 重要語候補抽出
    #termExtract.get_imp_word.sh;    # 重要語候補抽出
    #重要語を抽出したら学習用のデータベースにすぐ蓄積する
    termExtract.storage; #学習用のデータを蓄積
    termExtract.calcImp ;                 # 重要度計算(awk とbashの共用）ここは最大重要課題
    termExtract.execTerm.awk;                 # 重要語リストと計算した重要度を変数に出力する。
    #termExtract.execTerm.sh;             # 見出しは全ての重要語を出力(※新規追加）
    TITLE_KEYS_RESULT_LINE="$TermExtOut" ; # 見出しの結果を格納
    #
    termExtract.execMecab "$DESCRIPTION" ;     # 本文の形態素解析
    termExtract.get_imp_word.awk;   # メソッド実行
    #termExtract.get_imp_word.sh;    # メソッド実行
    termExtract.calcImp ;                 # 重要度計算(awk とbashの共用）ここは最大重要課題
    termExtract.execTerm.awk "bc100" ;        # 重要語リストと計算した重要度をファイルに出力する。
    #termExtract.execTerm.sh "bc100";     # 本文はbc100によりスコア1.00以上の重要語を出力（※新規追加）
    TERM_EXTRACT_RESULT_LINE="$TermExtOut" ; #本文の結果を格納
    termExtract.Rescore.awk;                   # スコアの振り直し
    #termExtract.Rescore.sh ;              # 重要語を整列させてスコアを振り直す
}
