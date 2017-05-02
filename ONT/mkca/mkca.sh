#!/bin/bash
#ニュースパックのカテゴリを自動生成するプログラムたたき台
#
function mkca(){
echo "$w";
#キーワードがどのノードの下に配置されるのか
#１文字のものはダメ
((${#w}<1))&&continue;
#使用回数が一定数以下のキーワードは組み込まない

#複数のカテゴリで満遍なく使用されているキーワードは組み込まない
#sg=$(cat newspack.txt |gawk -v FPAT='([^,]+)|(\"[^\"]+\")' '{print $5 " " $6}'|grep "$w");
sg=$(sary "$w" newspack_key.txt);
sc=$(echo "$sg" |awk '{print $1;}'|sed -e "s|\"||g"  -e "s|,|\n|g" |grep [-/]|grep -v Main |grep -v KeywordLine|sort|uniq -c|sort -n);
echo "$sc";
sum=$(echo "$sc"|awk '{s += $1} END {print s}');
cnt=$(echo "$sc"|tail -n1|awk '{print $1;}');
cat=$(echo "$sc"|tail -n1|awk '{print $2;}');
echo "cat:$cat";
#sports の場合 他のスポーツを足してあげないとダメ
if echo "$cat" |grep -e "Sports-sports" -e "Sports-worldgames" >/dev/null ;then
  #echo "worldgggg";
  #echo "$sc"|grep "Sports-worldgames";
  cnt=$(echo "$sc"|grep "Sports-"|awk '{s += $1} END {print s}');
fi
cat=$(echo "$sc"|tail -n1|awk '{print $2;}'|awk -F- '{print $2;}');
#201 Sports-worldgames
#311 Sports-sports

echo "$cnt/$sum";
echo "scale=1;($cnt/$sum)*100"|bc -l;
sflg=$(echo "scale=1;($cnt/$sum)*100  >= 65" | bc -l);
(("$sflg"==0))&&continue;
mflg=$(echo "scale=1;($cnt/$sum)*100  >= 80" | bc -l);
echo "$cat";


#例:ニューヨーク共同
#より深い階層があればそこに配置できないか調べる

dk=$(find CAT/ -type d |grep -i "$cat"|awk -F/ '{print $NF}'|grep -v "$cat"|grep -v "N_$w$");
echo "$dk";
path=$(find CAT -type d|grep -i "${cat}$");
echo "path:$path";
[[ -n "$dk" ]]&&{
  echo "デバック"
  echo "$dk"|while read d;do
    echo "###$d####";
    dpath=$(find CAT -type d|grep "${d}$");
    echo "dpath:$dpath";
    ls "$dpath"|grep "M_"|sed -e "s|M_||g"|nkf -wLu >tmpg;
    if [ -s tmpg ];then
      dsc=$(echo "$sg"|grep -f tmpg|awk '{print $1;}'|sed -e "s|\"||g"  -e "s|,|\n|g" |grep [-/]|grep -v Main |grep -v KeywordLine|wc -l);    
    else
      dsc=0;
    fi
    echo "dsc:$dsc";
    dsflg=$(echo "scale=1;($dsc/$cnt)*100  >= 30" | bc -l);
    if [ "$dsflg" = 1 ];then
      echo "$dpath";
    fi
  done;
  echo "TODO:より深い階層のノードに配置すべきかの判定基準"
  tpath=$(echo "$dk"|while read d;do
    dpath=$(find CAT -type d|grep "${d}$");
    ls "$dpath"|grep "M_"|sed -e "s|M_||g"|nkf -wLu >tmpg;
    if [ -s tmpg ];then
      dsc=$(echo "$sg"|grep -f tmpg|awk '{print $1;}'|sed -e "s|\"||g"  -e "s|,|\n|g" |grep [-/]|grep -v Main |grep -v KeywordLine|wc -l);    
    else
      dsc=0;
    fi
    dsflg=$(echo "scale=1;($dsc/$cnt)*100  >= 30" | bc -l);
    if [ "$dsflg" = 1 ];then
      echo "$dpath";
      break;
    fi
  done);  
  if [ -n "$tpath" ];then
    path="$tpath";
  fi
}
echo "path:$path";
#ノードとして独立させるべきか
#とりあえずWORDNETにあればノード化してるがTODO
ndflg=$( grep "$w" ../WORDNET);
#Wordnetや類語にあるものはノードとして独立させる
#ノードとして独立させる条件は要検討
#ノードとして独立させる場合
if [ -n "$ndflg" ];then
  mkdir -p "$path/N_$w"; 
  touch "$path/N_$w/M_$w"; 
else
#メインキーワードとして組み込む場合
  if [ "$mflg" = "1" ];then
    touch "$path/M_$w"; 
  else
#サブキーワードとして組み込む場合
    touch "$path/S_$w";
  fi
fi
}

function main(){
  cat "sp_cnt.txt"|awk '{print $2;}'|while read w;do
    mkca;
  done
}
main;
exit;
