#!/bin/bash
#
#デバッグモード
DEBUG="TRUE" ;
#DEBUG="FALSE" ;
#
function Main(){
  source config ;               #コンフィグファイル読み込み
  source lib/parse.sh ; 
  parse ;                       #パラメータ処理
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
Main
exit ;
