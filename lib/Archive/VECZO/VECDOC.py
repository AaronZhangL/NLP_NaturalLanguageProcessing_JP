#!/usr/bin/env python
# -*- coding: utf-8 -*-

from gensim import models
import sys
import codecs
my_model = sys.argv[1]

sys.stdout = codecs.getwriter('utf_8')(sys.stdout)
sys.stdin = codecs.getreader('utf_8')(sys.stdin)

model_loaded = models.Doc2Vec.load(my_model)

#標準入力から文章のキーワードを取得
input_line = sys.stdin.readline()
itemlist = input_line.rstrip().split(' ')
# ある文書に似ている文書を表示
# ある単語に類似した単語を取得
#print itemlist
doc = list(input_line)
#print doc
new_doc_vec = model_loaded.infer_vector(doc)
#print new_doc_vec
#print (model_loaded.most_similar(positive=itemlist))
print model_loaded.docvecs.most_similar([new_doc_vec], topn=10)
