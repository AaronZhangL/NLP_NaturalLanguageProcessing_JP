#!/usr/bin/env python
# -*- coding: utf-8 -*-

from gensim import models

sentence = models.doc2vec.LabeledSentence(
    words=[u'犬',u'今日',u'吠えた'], tags=["SENT_0"])
sentence1 = models.doc2vec.LabeledSentence(
    words=[u'猫', u'明日', u'吠えた'], tags=["SENT_1"])
sentence2 = models.doc2vec.LabeledSentence(
    words=[u'今', u'猫', u'魚'], tags=["SENT_2"])
sentence3 = models.doc2vec.LabeledSentence(
    words=[u'魚', u'泳ぐ', u'海'], tags=["SENT_3"])

sentences = [sentence, sentence1, sentence2, sentence3]

class LabeledLineSentence(object):
    def __init__(self, filename):
        self.filename = filename
    def __iter__(self):
        for uid, line in enumerate(open(filename)):
            yield LabeledSentence(words=line.split(), labels=['SENT_%s' % uid])

model = models.Doc2Vec(alpha=.025, min_alpha=.025, min_count=1)
model.build_vocab(sentences)

for epoch in range(10):
    model.train(sentences)
    model.alpha -= 0.002  # decrease the learning rate`
    model.min_alpha = model.alpha  # fix the learning rate, no decay

model.save("my_model.doc2vec")
model_loaded = models.Doc2Vec.load('my_model.doc2vec')

# ある文書に似ている文書を表示
#print ("SENT_0")
#print (model.docvecs.most_similar(["SENT_0"]) )
#print ("SENT_3")
#print (model.docvecs.most_similar(["SENT_3"]) )
#print ("SENT_1")
#print (model_loaded.docvecs.most_similar(["SENT_1"]) )

# ある単語に類似した単語を取得
#print (model.similar_by_word(u"魚"))

print (model.most_similar(positive=[u"猫", u"魚"]))
#
#test_1 = model.similarity(u"猫", u"魚")
#print(test_1)

