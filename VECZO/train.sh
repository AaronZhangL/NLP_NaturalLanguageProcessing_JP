#!/bin/bash
#堀内作成
#カテゴリごとに学習を実施する

find rst -type f > file.txt;

while read fl;do
model="model/"`basename "$fl"|sed -e "s|\.txt|_doc2vec|"`
cat "$fl"|python train.py "$model";
#echo "cat \"$fl\"|python train.py \"$model\"";

done < file.txt
