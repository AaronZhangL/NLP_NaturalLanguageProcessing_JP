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
#   -c  は解析モデル名(1-6) デフォルトは 3 : calc_imp_by_HASH（延べ数）
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

source config ;               
source lib/parse.sh ; 
source lib/main.sh ;
source lib/termExtract.sh ;
source lib/calcImp.sh ; 
source lib/mecabExtract.sh
source lib/cabochaExtract.sh ;
source lib/makeGraph.sh ;
source lib/opinionExtract.sh ;
source lib/summaryExtract.sh ;
source lib/getCategory.sh ;
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
             default<>3 : calc_imp_by_HASH（延べ数）
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
if [ 0 = $# ]; then usage; exit 1; fi
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
      #ここにロジックや計算手法の特長などを書いてほしい。
      #たくさん書いてくれれば、こちらで整理するので、まずは
      #いろいろ書いてみて
      #
      #
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
      #
      #
      #
      #
      #
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
      #
      #
      #
      #
      #
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
      #
      #
      #
      #
      #
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
      #
      #
      #
      #
      #
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
      stat_mode=1; 
      storage_mode=1;
      ;;
    *)
      # Default
      #
      #
      #
      #
      #
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
Main ; # lib/main.sh
exit 0 ;

