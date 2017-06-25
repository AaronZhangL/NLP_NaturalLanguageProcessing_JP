#!/bin/bash

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

source ./config ;               
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

