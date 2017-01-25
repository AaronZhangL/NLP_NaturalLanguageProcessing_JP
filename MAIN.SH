#
###############################################################
# メイン
###############################################################
#
# 実行方法
# ./MAIN.SH < in 
# または
# ./MAIN.SH -f in -c1 -m
#   -f  は入力ファイル名
#   -c  は解析モデル名(1-6)
#   -m  は解析モデル名の表示
#
#   詳しくは ./MAIN.SH -h 
#  
#通常モードは lib/main.sh
#フル出力モードは lib/full_main.sh

# ステップは次の通り
# 1. 機械学習による重要語抽出<-兄が頑張った
# 2. これまでの様々な手法を整理してドキュメントに残す <-ここ今
# 3. ニューラルネットワークによる重要語抽出（word2vec）
# 4. 日本語語彙体形を使ってカテゴリ分類

source config ;               #コンフィグファイル読み込み
source lib/parse.sh ; 
source lib/termExtract.sh ;
source lib/calcImp.sh ; 
source lib/mecabExtract.sh
source lib/cabochaExtract.sh ;
source lib/makeGraph.sh ;
source lib/opinionExtract.sh ;
source lib/summaryExtract.sh ;
source lib/print.sh ;         
#
usage_msg='usage:
    実行例 
    ./MAIN.SH -f in -c1

    MAIN.SH オプションは以下の通り...
     -d               デバッグモード

     -s               silentモード
                      余計なコメントを出力しない

     -f inputFile     

     -c number        1 : calc_imp_by_HASH_Freq（）
                      2 : calc_imp_by_HASH_TF（）
                      3 : calc_imp_by_HASH（延べ数）
                      4 : calc_imp_by_HASH（異なり数）
                      5 : calc_imp_by_HASH_PP（）
                      6 : calc_imp_by_DB（）
           
     -h               ヘルプメッセージの出力
                      実行例 
                        ./MAIN.SH -f in -c6

     -v               バージョン情報の出力
     '
#
#
function usage(){
  echo "$usage_msg" 1>&2 ;
}
#[ 0 = $# ] && { usage; exit 1; }
#
function version() {
    ver=$1
    ver=${ver#* }
    echo ${ver% $}
}
#
function selectCalc(){
  case "$1" in
    1)
      #NOLRFRQ 
      if [ "$LIST_MODEL" == "TRUE" ] ; then
      echo '計算モデルは以下の通り
                    + 1 : calc_imp_by_HASH_Freq（）
                      2 : calc_imp_by_HASH_TF（）
                      3 : calc_imp_by_HASH（延べ数）
                      4 : calc_imp_by_HASH（異なり数）
                      5 : calc_imp_by_HASH_PP（）
                      6 : calc_imp_by_DB（） ' ;
      fi
      LR=0 ;
      frq=1 ;
      ;;
    2)  
      #NOLRTF
      if [ "$LIST_MODEL" == "TRUE" ] ; then
      echo '計算モデルは以下の通り
                      1 : calc_imp_by_HASH_Freq（）
                    + 2 : calc_imp_by_HASH_TF（）
                      3 : calc_imp_by_HASH（延べ数）
                      4 : calc_imp_by_HASH（異なり数）
                      5 : calc_imp_by_HASH_PP（）
                      6 : calc_imp_by_DB（） ' ;
      fi
      LR=0 ;
      frq=2 ;
      ;;     
    3)
      #NOLRTOTAL
      if [ "$LIST_MODEL" == "TRUE" ] ; then
      echo '計算モデルは以下の通り
                      1 : calc_imp_by_HASH_Freq（）
                      2 : calc_imp_by_HASH_TF（）
                    + 3 : calc_imp_by_HASH（延べ数）
                      4 : calc_imp_by_HASH（異なり数）
                      5 : calc_imp_by_HASH_PP（）
                      6 : calc_imp_by_DB（） ' ;
      fi
      LR=1 ;
      frq=1 ;
      ;;
    4)
      #LRUNIQ
      if [ "$LIST_MODEL" == "TRUE" ] ; then
      echo '計算モデルは以下の通り
                      1 : calc_imp_by_HASH_Freq（）
                      2 : calc_imp_by_HASH_TF（）
                      3 : calc_imp_by_HASH（延べ数）
                    + 4 : calc_imp_by_HASH（異なり数）
                      5 : calc_imp_by_HASH_PP（）
                      6 : calc_imp_by_DB（） ' ;
      fi
      LR=2 ;
      frq=1 ;
      ;;
    5)
      #LRPP
      if [ "$LIST_MODEL" == "TRUE" ] ; then
      echo '計算モデルは以下の通り
                      1 : calc_imp_by_HASH_Freq（）
                      2 : calc_imp_by_HASH_TF（）
                      3 : calc_imp_by_HASH（延べ数）
                      4 : calc_imp_by_HASH（異なり数）
                    + 5 : calc_imp_by_HASH_PP（）
                      6 : calc_imp_by_DB（） ' ;
      fi
      LR=3
      frq=2 ;
      ;; 
    6)
      #LRTFDB
      if [ "$LIST_MODEL" == "TRUE" ] ; then
      echo '計算モデルは以下の通り
                      1 : calc_imp_by_HASH_Freq（）
                      2 : calc_imp_by_HASH_TF（）
                      3 : calc_imp_by_HASH（延べ数）
                      4 : calc_imp_by_HASH（異なり数）
                      5 : calc_imp_by_HASH_PP（）
                    + 6 : calc_imp_by_DB（） ' ;
      fi
      LR=1 ; # LR=2
      frq=1;
      stat_mode=1 
      ;;
    *)
      #calc_imp_by_HASH（延べ数） <>default
      if [ "$LIST_MODEL" == "TRUE" ] ; then
      echo '計算モデルは以下の通り
                      1 : calc_imp_by_HASH_Freq（）
                      2 : calc_imp_by_HASH_TF（）
                    + 3 : calc_imp_by_HASH（延べ数）
                      4 : calc_imp_by_HASH（異なり数）
                      5 : calc_imp_by_HASH_PP（）
                      6 : calc_imp_by_DB（） ' ;
      fi
      LR=1 ;
      frq=1 ;
      ;; 
    esac
}
# : をつけると値を受け取るという意味
DEBUG="FALSE" ;
LIST_MODEL="FALSE" ;
while getopts dmf:c:hv option; do
    case "$option" in
    d) 
        DEBUG="TRUE";
        ;;
    m)
        LIST_MODEL="TRUE" ;    
        ;;
    f)  
        inputFile="$OPTARG" ;
        ;;     
    c)
        calc_imp="$OPTARG" ;
        ;;
    h|\?)
        usage ;
        exit 0
        ;;
    v)
        version '$Revision: 1.00 $'
        exit 0
        ;;
    esac
done
shift $(($OPTIND - 1))
selectCalc "$calc_imp";
#
#
function Main(){
  if [ "$inputFile" == "" ] ; then
    # ./MAIN.SH < in の場合
    parse ;
  else
    # -f in に対応
    parse<"$inputFile" ;        #パラメータ処理
  fi
  termExtract ;                 #重要語解析
  mecabExtract ;                #形態素解析(人名地名組織名の抽出）
  cabochaExtract ;              #構文解析
  makeGraph ;                   #グラフの生成 
  opinionExtract ;              #評価表現の抽出
  summaryExtract ;              #要約の抽出
  printOut ;
}
#
Main ;
exit 0 ;




  #URLGETOPT:入力パラメータ
  #TITLE:見出し
  #DESCRIPTION:本文
  #perMax:要約率
  #summaxlength:要約後最大文字数
  #ArticleType:記事タイプ
  #
  #isAscii:日本語判定
  #
  #MECAB_OUT
  #TITLEまたはDESCRIPTIONの和布蕪解析結果。
  #表層形  品詞,品詞細分類1 ,品詞細分類2 ,品詞細分類3,活用形,活用型,原形,読み,発音
  #例:早大  名詞,固有名詞,組織,*,*,*,早大,ソウダイ,ソーダイ
  #
  #comNounList
  #和布蕪解析結果から名詞を取り出して、使用頻度を数えたもの。
  #名詞とは、
  #品詞が名詞であること
  #品詞再分類1が一般 or サ変接続 or 固有名詞 または
  #品詞再分類1が接尾でかつ品詞細分類2が一般 or サ変接続のもの。
  #但し、形容動詞は含まない。
  #複合名詞（名詞が連続する場合）は一つの名詞として取り扱う。
  #
#  #calc_imp_by_HASH_Freq
#  echo "1. calc_imp_by_HASH_Freq#######################" ;
#  # $awkTermExtractList_NOLRFRQ ;
#  #LR=0 ;
#  #frq=1 ;
#  Main 0 1 0 ;
#  
#  #calc_imp_by_HASH_TF
#  echo "2. calc_imp_by_HASH_TF#########################" ;
#  # $awkTermExtractList_NOLRTF
#  #LR=0 ;
#  #frq=2 ;
#  Main 0 2 0;
#
#  #calc_imp_by_HASH（延べ数） <>default
#  echo "3. calc_imp_by_HASH############################" ;
#  # $awkTermExtractList_LRTOTAL ;
#  #LR=1 ;
#  #frq=1 ;
#  Main 1 1 0 ;
#
#  #calc_imp_by_HASH（異なり数）
#  echo "4. calc_imp_by_HASH############################" ;
#  # $awkTermExtractList_LRUNIQ ;
#  #LR=2 ;
#  #frq=1 ;
#  Main 2 1 0 ;
#
#  #calc_imp_by_HASH_PP
#  echo "5. calc_imp_by_HASH_PP#########################" ;
#  # $awkTermExtractList_LRPP 
#  #LR=3
#  #frq=2 ;
#  Main 3 2 0;
#
#  #calc_imp_by_DB
#  echo "6. calc_imp_by_DB##############################" ;
#  # $awkTermExtractList_LRTFDB
#  #LR=1 ; # LR=2
#  #frq=1;
#  #stat_mode=1 
#  Main 1 1 1;
  
