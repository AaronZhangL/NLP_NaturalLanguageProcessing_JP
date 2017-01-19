#
##########################################################
# 形態素解析
##########################################################
#
# bash版 # 組織名抽出
# 入力: $MECAB_OUT ( 変数 ) # 出力: $ORG_RESULT_LINE ( 変数 )
function mecabExtract.Org.sh(){
  ORG_RESULT_LINE=$( echo -n "<ORGS>"; echo "$MECAB_OUT" | nkf -Ew | LANG=C grep -i "組織" |\
    sed -e "s|\s.*$|</ORG>|g" -e "s|^|<ORG>|g" | LANG=C sort -s -k1 | uniq | tr -d "\n" ; echo -n "</ORGS>") ;
  if [ $DEBUG == "TRUE" ]; then echo "ORG_RESULT_LINE : $ORG_RESULT_LINE" ; fi
}
#
# Awk版 # 組織名抽出
# 入力: $MECAB_OUT ( 変数 ) # 出力: $ORG_RESULT_LINE ( 変数 )
function mecabExtract.Org.awk(){
  ORG_RESULT_LINE=$( echo "$MECAB_OUT" | nkf -Ew | $awk '
  BEGIN{
    TERM="" ;
  }{
    if (index($0, "組織") > 0 ){
      gsub(/[[:blank:]].*$/, "", $0) ;
      arTERM[$0]=$0 ;
    }
  }END{
    for ( i in arTERM){
      TERM=TERM "<ORG>" i "</ORG>"  ;
    }
    print "<ORGS>" TERM "</ORGS>";
  }')  ;
  if [ $DEBUG == "TRUE" ]; then echo "ORG_RESULT_LINE : $ORG_RESULT_LINE" ; fi
}
#
# awk版 地名抽出 (緯度経度情報付与なし)
# 入力: $MECAB_OUT ( 変数 ) # 出力: $GEO_RESULT_LINE ( 変数 )
#
function mecabExtract.Geo.awk() {
  GEO_RESULT_LINE=$( echo "$MECAB_OUT" | nkf -Ew | awk '
    BEGIN{
      TERM="" ;
    }{
      if ( $0 ~ /地域/){
        gsub(/[[:blank:]].*$/, "", $0) ;
        arTERM[$0]=$0 ;
      }
    }END{
      for ( i in arTERM){
        #1文字は対象外
        if ( i !~ /^.$/){
          TERM=TERM "<GEO>" i "</GEO>"  ;
        }
      }
      print "<GEOS>" TERM "</GEOS>";
    }')  ;
}
#
# bash版 人名抽出 
# 人名は、姓、名、姓名  等の種類があり、姓の直後に出現する名を姓名
# とし、姓単独で出現する場合も、姓名で出現した場合において姓名に姓を吸収する処
# 入力: $MECAB_OUT ( 変数 ) # 出力: $NAME_RESULT_LINE ( 変数 )
function mecabExtract.Name.sh(){
  NAME_RESULT_LINE=$( echo -n "<NAMES>"
    echo "$MECAB_OUT" | nkf -Ew | \
    while read line ;do
      if echo "$line" | LANG=C grep -i "固有名詞,人名" > /dev/null; then
        #空白から後ろを除去
        #斎藤    名詞,固有名詞,人名,姓,*,*,斎藤,サイトウ,サイトー
        line=$(echo "$line" | $awk '{ print $1; }');
      if [ "$maeword" != "" ] ;then 
        #名もあれば
        if [ "$maeword" != "$line" ] ;then
          echo "$maeword$line";
          maeword="" ;
        fi
      else
        #まずは姓を格納
        maeword="$line";
      fi
      #人名ではない
      elif [ "$maeword" != "" ] ;then
        echo "$maeword" ;
        maeword="";
      else
        maeword="";
      fi
    done | LANG=C sort -s -k1 | uniq | xargs -I % -n1 -P4 bash -c 'echo -n "<NAME>%</NAME>"' ;
    echo -n "</NAMES>";
  ); 
  if [ $DEBUG == "TRUE" ]; then echo "NAME_RESULT_LINE : $NAME_RESULT_LINE" ; fi
} 
#
# Awk版
# <> func_NAME
# 人名抽出 人名は、姓、名、姓名  等の種類があり、姓の直後に出現する名を姓名
#とし、姓単独で出現する場合も、姓名で出現した場合において姓名に姓を吸収する処
# 入力: $MECAB_OUT ( 変数 )
# 出力: $NAME_RESULT_LINE ( 変数 )
#
function mecabExtract.Name.awk(){
  NAME_RESULT_LINE=$( echo "$MECAB_OUT" | nkf -Ew | $awk '
    BEGIN {
      maeword = "";
      TERM = "" ;
    } {
      if ( $0 ~ /固有名詞,人名/){
      	#空白から後ろを除去
      	#斎藤    名詞,固有名詞,人名,姓,*,*,斎藤,サイトウ,サイトー
        gsub (/[[:blank:]].*$/, "", $0) ;
        if (maeword != "") {
	        #名もあれば
          if ( maeword != $0){
            #格納の重複を解消するためにハッシュに格納
            seimeilist[maeword $0] = maeword $0;
            maeword = "" ;
          }
        } else {
	         #まずは姓を格納
          maeword = $0;
        }
      }else{
        #人名ではない
        if ( maeword != "" ){
          seimeilist[maeword] = maeword ;
        }
        maeword = "";
      }
    } END {
      for ( i in seimeilist ){
        TERM = TERM "<NAME>" i "</NAME>" ; 
      }
      print "<NAMES>" TERM "</NAMES>";
    }' );
  if [ $DEBUG == "TRUE" ]; then echo "NAME_RESULT_LINE : $NAME_RESULT_LINE" ; fi
} 
#
function mecabExtract(){

    mecabExtract.Name.awk;        # 人名抽出
    #mecabExtract.Name.sh;

    mecabExtract.Geo.awk;         # 地名抽出

    mecabExtract.Org.awk;         # 組織名抽出
    #mecabExtract.Org.sh;

}
#
