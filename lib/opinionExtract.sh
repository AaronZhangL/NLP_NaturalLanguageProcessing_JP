#
###############################################################
#  評価表現抽出
###############################################################
#
#<>func_Color_ExtractOpinions
#評価タイプの種類ごとにルートへ色を付ける（awk）
#入力１：IS_HAS_TABLE（変数）
#入力２：HTML_EXTRACT_OPINIONS_RESULT_LINE（変数）
#出力１：IS_HAS_TABLE（変数、入力値を書き換えて出力とする）
#
function opinionExtract.IS_HAS_TABLE(){
  HEORL=`echo "$HTML_EXTRACT_OPINIONS_RESULT_LINE" |tr "\n" "|"`;
  IS_HAS_TABLE=`echo "$IS_HAS_TABLE" | $awk -v HEORL="$HEORL" '
  {
    output = $0;
    sahen = $0;
    gsub(/\"/, "", sahen);
    gsub(/->.*$/, "", sahen);
    uhen = $0;
    gsub(/^.*->\"/, "", uhen);
    gsub(/\" \[.*$/, "", uhen);
    n = split( HEORL, arrHEORL, "|");
    for(i = 1; i <= n; i++)
      if ( index(arrHEORL[i], sahen) != 0 && index(arrHEORL[i], uhen) != 0 ){
        if ( index(arrHEORL[i], "感情") != 0 ){
          gsub(/]$/, " color=\"#d84a38\"]", output);          
        }else if ( index(arrHEORL[i], "批評") != 0 ){
          gsub(/]$/, " color=\"#35aa47\"]", output);          
        }else if ( index(arrHEORL[i], "メリット") != 0 ){
          gsub(/]$/, " color=\"#4d90fe\"]", output);          
        }else if ( index(arrHEORL[i], "採否") != 0 ){
          gsub(/]$/, " color=\"#cc00cc\"]", output);          
        }else if ( index(arrHEORL[i], "出来事") != 0 ){
          gsub(/]$/, " color=\"#faa937\"]", output);          
        }else if ( index(arrHEORL[i], "当為") != 0 ){
          gsub(/]$/, " color=\"#5bc0de\"]", output);          
        }else if ( index(arrHEORL[i], "要望") != 0 ){
          gsub(/]$/, " color=\"#5bc0de\"]", output);          
        }
      }
      print output;
    }'`;
  if [ $DEBUG == "TRUE" ]; then echo "IS_HAS_TABLE : $IS_HAS_TABLE" ; fi
}
#
# tsv2out.plをシェル（awk）化して関数化
# TSV変換されたKNP処理結果を標準出力する
# 入力：$EXOPINIONS_TMP ( 変数 ) TSV形式のKNP処理結果 ＊EUC
# 出力：$HTML_EXTRACT_OPINIONS_RESULT_LINE ( 変数 ) 出力形式へ変換した処理結果 ＊UTF8
# 
function opinionExtract.tsv2out(){
  EXOPINIONS_RESULT_LINE=$(echo "$EXOPINIONS_TMP" | $awk -F"\t" '{ print  $3 "\t" $4 "\t" $7 "\t" $9 "\t" $8 }' | nkf -wLu  | LANG=C grep -i "\[" | sed -e "s/^.*\[/\[/g");
  HTML_EXTRACT_OPINIONS_RESULT_LINE="<EX_OPINIONS><![CDATA[$EXOPINIONS_RESULT_LINE]]></EX_OPINIONS>" ; 
  if [ $DEBUG == "TRUE" ]; then echo "EXOPINIONS_RESULT_LINE : $EXOPINIONS_RESULT_LINE"  | nkf -wLu ; fi
}
#
#<> func_pol_extract
# pol/extract.shを関数化
# 隠れ変数を持つ条件付き確率場を用いた評価極性分類を行う
#
# 入力：$polmdlfile
# 入力：$intsvfile(ファイル) ＊TSV変換したSVM処理結果
# 出力：TSV変換した極性分類処理結果(標準出力)
#
#  tsv2par.awk: tsv形式をpar形式に変換する
#  par2dat.awk: par形式をdat形式に変換する
#  out2tsv.awk: プログラムの出力をtsv形式に変換する
#
function func_pol_extract(){
  if [ "$#" -ne 2 ]
  then 
    echo "usage: $0 <*.mdl> <*.tsv> > <*.tsv>" 2>&1
    exit 1
  fi
  #local dir=`dirname $0`
  local dir=${EXOPPOL:-.}
  local tmp=${TMPDIR:-.}
  local exlib=${EXOPLIB:-.}
  local mdlfile=$1
  local tsvfile=$2
  local datfile=$tmp/test.$$.dat
  local outfile=$tmp/test.$$.out
  #20151027
  $dir/out2tsv.awk -f $exlib/utility.awk -v SCRIPT=$dir/out2tsv.awk $tsvfile $($dir/tsv2par.awk -f $exlib/utility.awk -v SCRIPT=$dir/tsv2par.awk $tsvfile | $dir/par2dat.awk -f $exlib/utility.awk -v SCRIPT=$dir/par2dat.awk $dictionary/dictionary.dic $dictionary/reverse.dic | $dir/lsm_classify $mdlfile) ;
#  $dir/tsv2par.awk -f $exlib/utility.awk -v SCRIPT=$dir/tsv2par.awk $tsvfile | $dir/par2dat.awk -f $exlib/utility.awk -v SCRIPT=$dir/par2dat.awk $dictionary/dictionary.dic $dictionary/reverse.dic | $dir/lsm_classify $mdlfile > $outfile 2> /dev/null
#  $dir/out2tsv.awk -f $exlib/utility.awk -v SCRIPT=$dir/out2tsv.awk $tsvfile $outfile
#
#  rm -f $outfile
}
#
#<> func_typ_extract
# typ/extract.shを関数化
# SVMにpairwise法を適用して，評価タイプの分類を行う
# 
# 入力１：$typftfile
# 入力２：$typmdlfile
# 入力３：TSV変換したCRF++の出力結果(ファイル)
# 出力  ：TSV変換したSVM処理結果(標準出力)
#
#   tsvconv.awk: tsvファイルから必要な情報だけを取り出す
#   makefv.awk : SVM用の素性ベクトルを作る
#   out2tsv.awk: SVMの出力をtsv形式に変換する
#
function func_typ_extract(){
    if [ "$#" -ne 3 ]
    then
      #echo "usage: test.sh <*.ft> <*.mdl> <*.tsv> > <*.tsv>" 1>&2
      exit 1
    fi
    #local dir=`dirname $0`
    local dir=${EXOPTYP:-.}
    local tmp=${TMPDIR:-.}
    local exlib=${EXOPLIB:-.}
    local ftfile=$1
    local mdlfile=$2
    local tsvfile=$3
    local fvfile=$tmp/test.$$.fv
    local svfile=$tmp/test.$$.sv
    local outfile=$tmp/test.$$.out
    $dir/tsvconv.awk -f $exlib/utility.awk -v SCRIPT=$dir/tsvconv.awk $tsvfile | \
      $dir/makefv.awk -f $exlib/utility.awk -v SCRIPT=$dir/makefv.awk | \
      $dir/../svmtools/svm_fv2sv $ftfile > $svfile
    $dir/../svmtools/svm_mc_classify $svfile $mdlfile $outfile > /dev/null 2>&1
    $dir/out2tsv.awk -f $exlib/utility.awk -v SCRIPT=$dir/out2tsv.awk $tsvfile $outfile
    rm -f $svfile $outfile
}
#
#<> func_svmtest
# src/svmtest.shを関数化
# 保持者と著者が同一かをSVMで判定するテスト用スクリプト
#
# 入力１：$ftfile(ファイル) ＊モデルファイル名:$1.src_ft
# 入力２：$svmmdlfile(ファイル) ＊モデルファイル名:$1.src_svmmdl
# 入力３：$tsvfile(ファイル) ＊XPR形式ファイル名
# 出力  ：tsv形式に変換したSVMの処理結果(標準出力)
#
function func_svmtest(){
    if [ "$#" -ne 3 ]; then
      #echo "usage: svmtest.sh <*.ft> <*.svmmdl> <*.tsv> > <*.tsv>" 1>&2
      exit 1
    fi
    #local dir=`dirname $0`
    local dir=${EXOPSRC:-}
    local tmp=${TMPDIR:-.}
    local exlib=${EXOPLIB:-.}
    local ftfile=$1
    local mdlfile=$2
    local tsvfile=$3
    local fvfile=$tmp/svmtest.$$.fv
    local fvfile0=$tmp/svmtest.$$.fv0
    local svfile=$tmp/svmtest.$$.sv
    local outfile=$tmp/svmtest.$$.out
    $dir/tsvconv.awk -f $exlib/utility.awk -v SCRIPT=$dir/tsvconv.awk $tsvfile|$dir/makefv.awk -f $exlib/utility.awk -v SCRIPT=$dir/makefv.awk|$dir/../svmtools/svm_fv2sv $ftfile > $svfile
    $dir/../svmtools/svm_classify $svfile $mdlfile $outfile > /dev/null 2>&1
    $dir/out2tsv.awk -f $exlib/utility.awk -v SCRIPT=$dir/out2tsv.awk $tsvfile $outfile
    rm -f $svfile $outfile
}
#
#<> func_crftest
# src/crftest.shを関数化
# 保持者をCRFで文中から抽出する訓練用スクリプト
# 入力１：$crfmdlfile(ファイル) ＊モデルファイル名:$1.src_crfmdl
# 入力２：$tmptsvfile(ファイル) ＊一時出力結果格納ファイル名
# 出力  ：tsv変換したCRF++の出力結果(標準出力)
#
function func_crftest(){
    crf_test=crf_test
    if [ "$#" -ne 2 ]
    then
      #echo "usage: crftest.sh <*.crfmdl> <*.tsv>" 1>&2
      exit 1
    fi
    #local dir=`dirname $0`
    local dir=${EXOPSRC:-}
    local tmp=${TMPDIR:-.}
    local exlib=${EXOPLIB:-.}
    local mdlfile=$1
    local tsvfile=$2
    local tagfile=$tmp/crftrain.$$.tag
    local otagfile=$tmp/crftrain.$$.otag
    #20151027
#    $dir/tsv2tag.awk -f $exlib/utility.awk -v SCRIPT=$dir/tsv2tag.awk $tsvfile|$crf_test -m $mdlfile > $otagfile
    $dir/otag2tsv.awk -f $exlib/utility.awk -v SCRIPT=$dir/otag2tsv.awk $tsvfile $($dir/tsv2tag.awk -f $exlib/utility.awk -v SCRIPT=$dir/tsv2tag.awk $tsvfile|$crf_test -m $mdlfile);
#    $dir/tsv2tag.awk -f $exlib/utility.awk -v SCRIPT=$dir/tsv2tag.awk $tsvfile|$crf_test -m $mdlfile > $otagfile
#    $dir/otag2tsv.awk -f $exlib/utility.awk -v SCRIPT=$dir/otag2tsv.awk $tsvfile $otagfile
#
#    rm -f $otagfile
}
#
#<> func_src_extract
# src/extract.shを関数化
# 評価表現が同定された後で，評価保持者を抽出する
# はじめにSVMを用いて評価保持者が著者であるかどうかを判定し，
# もし著者でないと判定された場合はCRFを用いて著者と
# 思われる文字列を抽出する
# 抽出できなかった場合は保持者は不定とする
#
# 入力１：$srcftfile (モデルファイル名:$1.src_ft)
# 入力２：$srcsvmmdlfile(モデルファイル名:$1.src_svmmdl)
# 入力３：$srccrfmdlfile(モデルファイル名:$1.src_crfmdl)
# 入力４：$intsvfile(XPR形式ファイル名)
# 出力  ：tsv変換したCRF++の出力結果(標準出力)
#
function func_src_extract(){
    if [ $# -ne 4 ]
    then
      #echo "usage: test.sh <*.ft> <*.svmmdl> <*.crfmdl> <*.tsv>" 1>&2
      exit 1
    fi
    local dir=${EXOPSRC:-}
    local tmp=${TMPDIR:-.}
    local ftfile=$1
    local svmmdlfile=$2
    local crfmdlfile=$3
    local tsvfile=$4
    local tmptsvfile=$tmp/test.$$.tsv
    func_crftest $crfmdlfile $(func_svmtest $ftfile $svmmdlfile $tsvfile );
}
#
#<> func_xpr_tsv2tag
# xpr/tsv2tag.awkを関数化
# *.tsv形式のデータをCRF++の入力フォーマットに変換する
# 評価表現がオーバーラップする場合最初に書かれた評価表現を優先
#
# 入力１：評価極性辞書(ファイル)
# 入力２：変換対称TSV(ファイル)
# 出力  ：CRF++用の入力文字列(標準出力)
#
function func_xpr_tsv2tag (){
    DIC="$1" ;
    TSV_FILE="$2" ;
    #xpr_tag=`awk -f $exlib/utility.awk -f - -v SCRIPT=$dir/tsv2tag.awk << 'EOF' "$DIC" "$TSV_FILE" 
    $awk -f $exlib/utility.awk -f - -v SCRIPT=$dir/tsv2tag.awk << 'EOF' "$DIC" "$TSV_FILE" 
        BEGIN {
          FS = "\t";
          if (ARGC < 2) {
            printf "usage: %s <dictionary> [<*.tsv>]\n", SCRIPT > "/dev/stderr";
            EXIT = 1;
            exit EXIT;
          }
          dicfile = ARGV[1];
          ARGV[1] = "";
          # 辞書の読み込み(w/ 形態素解析)+トライに格納
          ndic = dicread(dicfile, dicw, dicp, trie_flg, trie_val);
        } {
        #処理行数をカウント
          nlines++;
          sen = $5;
          xprall = $8;
          mrp = $10;
          nxpr = split(xprall, xprelem, /\\n/);
          n = ma(mrp, surf, base, cpos, fpos);
          # 極性タグ付与(trie探索)
          for (i = 1; i <= n; i++) pole[i] = "*";
          nlist = lookup(n, base, 1, n, trie_flg, trie_val, listv, listb, listl);
          for (i = 0; i < nlist; i++) {
            for (j = 0; j <= listl[i]; j++) {
              pole[listb[i] + j] = dicp[listv[i]];
            }
          }
          # BIOタグ付け
          for (i = 1; i <= n; i++) tag[i] = "O";
          for (z = 1; z <= nxpr; z++) {
            xpr = xprelem[z];
            p = position(sen, n, surf, xpr, 0);
            if (p == -1) {
                showError("xpr !in sen");
                printf " = Line:%d\n", nlines > "/dev/stderr";
                continue;
             }
            if (tag[PSTART] != "O" || tag[PEND] != "O") continue;
            tag[PSTART] = "B";
            for (i = PSTART + 1; i <= PEND; i++) tag[i] = "I";
          }
          # データ出力
          for (i = 1; i <= n; i++) {
            printf "%s\t%s\t%s\t%s\t%s\t%s\n", surf[i], base[i], cpos[i], fpos[i], pole[i], tag[i];
          }
          printf "\n";
        }
EOF
#`
#  echo "$xpr_tag" ;
  echo "" ; #元々の処理と出力を揃えるなら最後に空行を入れる
}
#
#<> func_xpr_otag2tsv
# xpr/otag2tsv.awkを関数化
# CRF++の出力をtsv形式に変換する
# ＊このファイルはEUC-JPで保存すること（ここまで原文コメント）
# $TSV_FILEと$OTAG_FILEがEUC-JPで、一部分だけこのawkで日本語置換し、他の部分はそのまま出力する
# すると１つのファイル中にEUC-JPで書かれた部分とUTF-8で書かれた部分が混在してしまい、正常に動作しない
# それを避けるために一旦どれもUTF-8で揃えてから処理し、最後の出力だけEUC-JPに変換（シェル移設コメント）
#
# 入力：TSV_FILE(ファイル)
# 入力：OTAG_DATA(変数) ＊CRF++用の入力データ
# 出力：TSV_U_FILE(ファイル) ＊入力ファイルをUTF変換
# 出力：TSV変換した処理結果(標準出力)
#
function func_xpr_otag2tsv(){
  TSV_FILE=$1 ;
  TSV_U_FILE=${TSV_FILE}.utf8
  cat "$TSV_FILE" | nkf -wLu > "$TSV_U_FILE" ;
  # 最終行マーク(===EOS===)を除去し、処理を行う
  xpr_tsv=`echo "$OTAG_DATA" | LANG=C grep -i -v "^===EOS===$" | \
           #$awk -f $exlib/utility.awk -v SCRIPT=$dir/otag2tsv.awk --source='  
           awk -f $exlib/utility.awk -v SCRIPT=$dir/otag2tsv.awk --source='  
    BEGIN {
      FS = "\t";
      OFS = "\t";
      if (ARGC < 2) {
        printf "usage: %s <*.tsv file> [<*.otag>]\n", SCRIPT > "/dev/stderr";
        EXIT = 1;
        exit EXIT;
      }
      tsvfile = ARGV[1];
      ARGV[1] = "";
      buf = "";
      cnt = 0;
      sen = "";
      extnum = 0;
    } {
      #処理行数をカウント
      nlines++;
      if (buf != "" && $7 != "I") {
        vec[cnt++] = buf;
        buf = "";
      }
      if ($0 == "") {
        extent[extnum] = "";
        for (i = 0; i < cnt; i++) extent[extnum] = extent[extnum] "\\n" vec[i];
        # 頭の改行除去。euc-jpだったら3文字分削る。utf-8だったら2文字分削る
        #extent[extnum] = substr(extent[extnum], 3);
        extent[extnum] = substr(extent[extnum], 2); 
        extsen[extnum] = sen;
        extnum++;
        cnt = 0;
        sen = "";
      } else {
        if ($7 == "B") buf = $1;
        if ($7 == "I") buf = buf $1;
        sen = sen $1;
      }
    } END {
      if (EXIT != "") exit EXIT;
      for (y = 0; ; ) {
        r = getline < tsvfile;
        if (r == 0) break;
        if (r < 0) error("file I/O error");
        if (extsen[y] != $5) {
          showError("sentence mismatch");
          printf " = Line:%d\n", nlines > "/dev/stderr";
        }
        if (extent[y] == "") {
          $6 = "";
          $7 = "";
          $8 = "";
          $9 = "";
        } else {
          tmp = extent[y];
          gsub(/\\n/, "\t", tmp);
          gsub(/[^\t]+/, "+1", tmp);
          gsub(/\t/, "\\n", tmp);
          $6 = tmp;
          tmp = extent[y];
          gsub(/\\n/, "\t", tmp);
          gsub(/[^\t]+/, "[著者]", tmp);
          gsub(/\t/, "\\n", tmp);
          $7 = tmp;
          $8 = extent[y];
          tmp = extent[y];
          gsub(/\\n/, "\t", tmp);
          gsub(/[^\t]+/, "当為", tmp);
          gsub(/\t/, "\\n", tmp);
          $9 = tmp;
        }
        y++;
        print;
      }
      if (y != extnum) error("#entities mismatch");
    } ' "$TSV_U_FILE" ` ;
  echo "$xpr_tsv"| nkf -We ; 
}
#
#<> func_xpr_extract
# ＊xpr/extract.shを関数化
#   CRFを用いて入力文から評価表現を抽出する．
#   手法や素性については，参考文献を参照．
#   参考文献
#  Tetsuji Nakagawa, Takuya Kawada, Kentaro Inui, Sadao Kurohashi: Extracting
#  Subjective and Objective Evaluative Expressions from the Web, In Proceedings
#  of the Second International Symposium on Universal Communication, pp.251-258,
#  December 2008.
#
# 入力：TSV形式ファイル（ファイル名）
# 出力：XPR形式ファイル(標準出力)
#
function func_xpr_extract(){
    crf_test=/usr/local/bin/crf_test ;
    if [ "$#" -ne 2 ]; then
      #echo "usage: test.sh <*.mdl> <*.tsv>" 1>&2
      exit 1
    fi
    #local dir=`dirname $0`
    local dir=${EXOPXPR:-.}
    local tmp=${TMPDIR:-.}
    local exlib=${EXOPLIB:-.}
    local mdlfile=$1
    local tsvfile=$2
    local tagfile=$tmp/train.$$.tag
    local otagfile=$tmp/train.$$.otag
    # awk外部ファイル内部化対応後
    OTAG_DATA=`func_xpr_tsv2tag $dictionary/dictionary.dic $tsvfile | \
               $crf_test -m $mdlfile  | \
               nkf -wLu && echo "===EOS===" `
               # 最後の空行もOTAG_DATA変数に含めるため、
               # crf_test実行後に最終行マークを付与
               # ＊最後の空行は大事
               #   func_xpr_otag2tsv では、空行を処理の基準としている
    func_xpr_otag2tsv $tsvfile
}
#
#<> func_Extract_Opinions
#  評価表現抽出文書の評価を行う
# juman/knpを利用し、文章の分析／分類を行う
#
# TSV形式のKNP結果へ以下の処理を行う
#  func_xpr_extract:評価表現を抽出する
#  func_src_extract:評価保持者を抽出する
#  func_typ_extract:評価タイプの分類を行う
#  func_pol_extract:評価極性分類を行う
#
# 入力１：$model モデルファイル（ファイル）
# 入力２：$EXOP_TSV ( 変数 ) TSV形式の処理文章
#         ＊TSV変換したKNP処理結果
# 出力  ：$EXOPINIONS_TMP ( 変数 ) TSV変換した処理結果
#
function opinionExtract.Extract_Opinions(){
  #func_extract ;
    # この関数で必要な環境変数定義
    LANG_BAK=$LANG;
    LC_ALL_BAK=$LC_ALL;
    export LANG=C
    export LC_ALL=C
    dir=`cd $(dirname $0) && pwd`
    tmp=${TMPDIR:-.}
    xprmdlfile=$model".xpr_mdl"
    srcftfile=$model".src_ft"
    srcsvmmdlfile=$model".src_svmmdl"
    srccrfmdlfile=$model".src_crfmdl"
    typftfile=$model".typ_ft"
    typmdlfile=$model".typ_mdl"
    polmdlfile=$model".pol_mdl"
    #scrftfile=$model".scr_ft"
    #scrmdlfile=$model".scr_mdl"
    intsvfile=$tmp/test.$$.intsv
    outtsvfile=$tmp/test.$$.outtsv
    #cp $tsvfile $intsvfile
    echo "$EXOP_TSV" | nkf -e > $intsvfile ;
    #外部スクリプトを同じファイル内の関数に変更
    #
    #関数呼び出し
    func_xpr_extract $xprmdlfile $intsvfile > $outtsvfile
    #cp $outtsvfile $intsvfile
    #
    #関数呼び出し
    #func_src_extract $srcftfile $srcsvmmdlfile $srccrfmdlfile $intsvfile > $outtsvfile
    cp $outtsvfile $intsvfile
    #
    #関数呼び出し
    func_typ_extract $typftfile $typmdlfile $intsvfile > $outtsvfile
    #cp $outtsvfile $intsvfile
    #
    #関数呼び出し
    #func_pol_extract $polmdlfile $intsvfile > $outtsvfile
    EXOPINIONS_TMP=`cat $outtsvfile` ;
    #FINAL
    rm -f $intsvfile $outtsvfile
    # この関数で変えた環境変数を元に戻す
    export LANG=$LANG_BAK;
    export LC_ALL=$LC_ALL_BAK ;
    if [ $DEBUG == "TRUE" ]; then echo "EXOPINIONS_TMP : $EXOPINIONS_TMP" | nkf -wLu ; fi
}
#
# <> func_tsvKakariuke
# 係り受けのデータをTSV形式に変換
#
# 入力: $KAKARIUKE_TMP( 変数 )
# 出力: $EXOP_TSV ( 変数 )
#
function opinionExtract.EXOP_TSV(){
  EXOP_TSV=$(echo "$KAKARIUKE_TMP" | $awk -F "|" ' BEGIN{
      documentID="exop_desc" ;
      lineCount=0 ;
      knpresult="";
      execsts=""; 
    }{
      ## セパレータ（｜）を分割し、それぞれの値を取得
      execsts = $1 ;
      sentence= $2 ;
      knpresult= $3 ;
      id++ ;
      sampleID = id;   
      sentenceID = id; 
      # mawkではswitch-case文不可
      if ( execsts == 1 ){
          checkTSV="0" ; ### 実装完了まで、仮値設定
                         ### しかしながら、checkTSV
                         ### は、現段階では未実装のまま
          if ( checkTSV == -1 ) {
            # エラー行数表示
            # printf STDERR " = Line:%d\n", $id; 
          }
          # 内容のコメントはシェル版参照
          printf  "%s\t%s\t%s\t%s\t%s\t\t\t\t\t%s\t\n",topic,sampleID,documentID,sentenceID,sentence,knpresult
          sampleID++;
      }else if (execsts == 0 ){
          printf "\t%s\t%s\t%s\t空白文\t\t\t\t\t空白_文:空白だ_文:形容詞_名詞:*_普通名詞\t3:0:D\t\t空白/くうはくa_文/ぶん\n",sampleID,documentID,sentenceID;
      }else if (execsts == -1 ){
      }else{
          printf "\t%s\t%s\t%s\t空白文\t\t\t\t\t空白_文:空白だ_文:形容詞_名詞:*_普通名詞\t3:0:D\t\t空白/くうはくa_文/ぶん\n",sampleID,documentID,sentenceID;
      }
    }
  '
  );
  if [ $DEBUG == "TRUE" ]; then echo "EXOP_TSV : $EXOP_TSV" ; fi
}
#
# jumanとknpでやっていたことを、cabocha(mecab)の処理とawkの整形で実装。
# 入力値は1行が長すぎると処理が重くなるので、句点単位で改行した文章。
# cabochaの結果としては、以下のようになる
#
# 入力  ：$CABOCHAEOS (複数行,変数)
# 出力  ：$TSV_KAKARIUKE (変数, 以下詳細)
# 出力1 ：execsts
#          1 : 正常
#          0 : 結果なし
#         -1 : ERROR
# 出力2 ：sentence (単一行)
#         ex)早大３連覇
# 出力3 ：knpresult
#         ex)早大_３_連覇:早大_３_連覇:名詞_名詞_名詞:組織名_数詞_サ変名詞 2_4:2_0:D_D
# ＊出力１〜３をパイプ（｜）区切りで返却する
#
function opinionExtract.KAKARIUKE_TMP(){
  KAKARIUKE_TMP=$(echo "$CABOCHAEOS"| $awk '
  BEGIN{
      count=1;
      surface="";
      parts="";
      parts_detail="";
      clauseno="";
      charno="";
      has="";
      depend="";
      sentence="0";
      wordcnt="0";
  }{
    if ( $0 ~ /^\*/ ) {
      cln = $2 ;
      hs = $3 ;
      gsub ( /D/, "", hs);
      if ( clauseno == "" ){
        clauseno = cln ;
      } else {
        clauseno = clauseno "_" cln ;
      }
      if ( has == "" ){
        has = hs ;
      } else {
        has = has "_" hs ;
      }
      wordcnt++ ;
      if ( count == 0 ) { next ; }
      if ( charno == "" ){
        charno = count ;
      } else {
        charno = charno "_" count ;
      }
    } else if ( $0 ~ /EOS/ ) {
      sentence = 1;
      words = surface ;
      gsub ( /_/, "", words );
      for ( i = 1; i <= wordcnt; i++){
        if ( i == 1 ) {
          dcnt = "D";
        }else{
          dcnt = dcnt "_D" ;
        }
      } # for i end
      gsub ( /-1/, "0", has) ;
      gsub ( /^1_/, "", charno);
      charno = charno "_" count ;
      result = sentence "|" words "|" surface ":" surface2 ":" parts ":" parts_detail "	" charno ":" has ":" dcnt ;
      results=results "\n" result;
      clauseno="";
      charno="";
      has="";
      surface="";
      surface2="";
      parts="";
      parts_detail="";
      count="1";
      wordcnt="0";
      dcnt="";
    } else {
      sf = $1;
      split($2, sf_arr, ",");
      ps = sf_arr[1];
      psd = sf_arr[2];
      sf2 = sf_arr[5] ;
      if ( surface == "" ){
        surface = sf ;
      } else {
        surface = surface "_" sf ;
      }
      if ( sf2 == "*" ) {
        sf2 = sf ;
      }
      if ( surface2 == "" ){
        surface2 = sf2 ;
      } else {
        surface2 = surface2 "_" sf2 ;
      }
      if ( parts == "" ){
        parts = ps ;
      } else {
        parts = parts "_" ps ;
      }
      if ( parts_detail == "" ){
        parts_detail = psd ;
      } else {
        parts_detail = parts_detail "_" psd ;
      }
      count++ ;
    }
  }END{
    if ( results != "" ) {print results };
  }' ) ;
  #if [ $DEBUG == "TRUE" ]; then echo "KAKARIUKE_TMP : $KAKARIUKE_TMP" ; fi
}
#
#graphVizで使用するcabocha処理は全文を一続きに扱っている。
#extractopinionでは「。」区切りで処理を分ける必要があるので
#cabochaの実行結果を編集し、「。」の後ろの行にEOSをつける
#
# 入力: $CABOCHA ( 変数 ) # 出力: $CABOCAEOS ( 変数 )
function opinionExtract.CABOCHAEOS(){
  CABOCHAEOS=`echo "$CABOCHA"| $awk '{
   if (  $0 ~ /EOS/ ){ 
    next; 
   }
   print $0;
   if (  $0 ~ /^。/ ){ 
     print "EOS";
   }
  }'`;
  if [ $DEBUG == "TRUE" ]; then echo "CABOCHAEOS : $CABOCHAEOS" ; fi
}
#
function opinionExtract(){
    opinionExtract.CABOCHAEOS;           #意見評価 cabochaの実行結果に「。」区切りでeosをつける
    opinionExtract.KAKARIUKE_TMP ;
    opinionExtract.EXOP_TSV ;
    opinionExtract.Extract_Opinions ;
    opinionExtract.tsv2out;
    opinionExtract.IS_HAS_TABLE ;
}
#
