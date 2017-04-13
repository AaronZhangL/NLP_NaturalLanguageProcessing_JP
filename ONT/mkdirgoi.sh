#!/bin/bash
#にほんごごい体系のフォルダを作成する
GOITAIKEI="../lib/GOITAIKEI2";

cat "$GOITAIKEI" | while read l;do
  #dr=$(echo "$l" | sed -e "s|^.*<KEIROJ>||" -e "s|</KEIROJ>.*$||"|sed -e "s|-|/|g");
  dr=$(echo "$l" | sed -e "s|^.*<KEIRO>||" -e "s|</KEIRO>.*$||"|sed -e "s|-|/|g");
  id=$(echo "$l" | sed -e "s|^.*<NO>||" -e "s|</NO>.*$||");
  mkdir -p "$dr";
  echo "$l"  > "$dr/$id";
done
