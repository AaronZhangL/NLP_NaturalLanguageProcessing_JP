#
###############################################################
# メイン
###############################################################
#
#デバッグモード
#DEBUG="TRUE" ;
DEBUG="FALSE" ;
#
source config ;               #コンフィグファイル読み込み
source lib/parse.sh ; 
parse ;                       #パラメータ処理

function Main(){

  LR=$1 ;
  frq=$2 ;
  stat_mode=$3 ;

  source lib/termExtract.sh ;
  source lib/calcImp.sh ; 
  termExtract ;                 #重要語解析
  source lib/mecabExtract.sh
  mecabExtract ;                #形態素解析(人名地名組織名の抽出）
  source lib/cabochaExtract.sh ;
  cabochaExtract ;              #構文解析
  source lib/makeGraph.sh ;
  makeGraph ;                   #グラフの生成 
  source lib/opinionExtract.sh ;
  opinionExtract ;              #評価表現の抽出
  source lib/summaryExtract.sh ;
  summaryExtract ;              #要約の抽出
  source lib/print.sh ;         #出力
  printOut ;
}

  #
  #calc_imp_by_HASH_Freq
  echo "1. calc_imp_by_HASH_Freq#######################" ;
  # $awkTermExtractList_NOLRFRQ ;
  #LR=0 ;
  #frq=1 ;
  Main 0 1 0 ;
  
  #calc_imp_by_HASH_TF
  echo "2. calc_imp_by_HASH_TF#########################" ;
  # $awkTermExtractList_NOLRTF
  #LR=0 ;
  #frq=2 ;
  Main 0 2 0;

  #calc_imp_by_HASH（延べ数） <>default
  echo "3. calc_imp_by_HASH############################" ;
  # $awkTermExtractList_LRTOTAL ;
  #LR=1 ;
  #frq=1 ;
  Main 1 1 0 ;

  #calc_imp_by_HASH（異なり数）
  echo "4. calc_imp_by_HASH############################" ;
  # $awkTermExtractList_LRUNIQ ;
  #LR=2 ;
  #frq=1 ;
  Main 2 1 0 ;

  #calc_imp_by_HASH_PP
  echo "5. calc_imp_by_HASH_PP#########################" ;
  # $awkTermExtractList_LRPP 
  #LR=3
  #frq=2 ;
  Main 3 2 0;

  #calc_imp_by_DB
  echo "6. calc_imp_by_DB##############################" ;
  # $awkTermExtractList_LRTFDB
  #LR=1 ; # LR=2
  #frq=1;
  #stat_mode=1 
  Main 1 1 1;
  
exit ;

