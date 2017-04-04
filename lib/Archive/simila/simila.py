#!/usr/bin/env python2.6
# encoding: utf-8
import sys
import nltk
from nltk.corpus import wordnet as wn
import codecs

sys.stdout = codecs.getwriter('utf_8')(sys.stdout)
sys.stdin = codecs.getreader('utf_8')(sys.stdin)
w1 = sys.argv[1]
w2 = sys.argv[2]
w1 =w1 + '.n.01'
w2 =w2 + '.n.01'
s1=wn.synset(w1)
s2=wn.synset(w2)
print s1.path_similarity(s2)
