#!/bin/bash 

cat list_csv.csv | awk -F, '{ print $3 ",,,10,名詞,固有名詞,組織,,*,*,,," ; }' |  \
      sed -e "s/株式会社//g" -e "s/有限会社//g" -e "s/合資会社//g" -e "s/合同会社//g" -e "s/合名会社//g" -e "s/一般社団法人//g" -e "s/公益法人//g" -e "s/一般財団法人//g" -e "s/特殊法人//g" -e "s/社会福祉法人//g" -e "s/公益社団法人//g" -e "s/公益財団法人//g" -e "s/特例民放法人//g" -e "s/学校法人//g" -e "s/宗教法人//g" -e "s/医療法人//g" -e "s/社会福祉法人//g" -e "s/職業訓練法人//g" -e "s/特定非営利活動法人//g" -e "s/特許業務法人//g" -e "s/（[^）]*）//g" > kiCode.csv ;

# /usr/local/etc/mecabrc に以下の追記
# userdic=/Users/suzukiiichiro/GoogleDrive/GitHub/NLP_NaturalLanguageProcessing_JP/lib/kiCode.dic" 

/usr/local/libexec/mecab/mecab-dict-index  \
    -d /usr/local/lib/mecab/dic/ipadic/ \
    -u list_csv.dic  \
    -f utf-8 -t utf-8 \
    kiCode.csv

