#
#########################################################
# パース処理
# parse.sh
#########################################################
#
# Awk版 # QUERY_STRING処理 日本語と英語の判定 # ASCIIだったらexitする 
# 入力: $DESCRIPTION ( 変数 )
function func_isAscii(){
  if echo "$DESCRIPTION" | cut -c1-12 | file - | LANG=C grep -i ASCII > /dev/null ; then
    exit ;
  else
    if [ $DEBUG == "TRUE" ]; then echo "isAscii : OK nonAscii" ; fi
  fi
}
#
# awk/bash版 POSTされた記事の種類を取得 # デフォルト値 ArticleType="editorial"
# 入力１: $URLGETOPT ( 変数 ) # 入力２: $ArticleType ( 変数 ) # 出力: $ArticleType ( 変数 )
function func_getArticleType() {
  ArticleType=$(echo "$URLGETOPT" | tr -d '\n' | $awk '{
    IGNORECASE=1 ;
    if (index($0, "atype=") > 0 ){
      gsub(/^.*atype=\x27/, "", $0) ;
      gsub(/\x27.*$/, "", $0) ;
      gsub(/\r/, "", $0) ;
      gsub(/^[●○■□△▽]/, "", $0) ;
      gsub(/<[^>]*>/, "", $0) ;
      print $0 ;
    }
  }');
  if [ $DEBUG == "TRUE" ]; then echo "ArticleType : $ArticleType" ; fi
}
#
# awk/bash版 POSTされた要約圧縮率を取得 # デフォルト値 maxlength=なし
# 入力１: $URLGETOPT ( 変数 ) # 入力２: $maxlength ( 変数 ) # 出力: $summaxlength ( 変数 )
function func_getSummaxlength() {
  summaxlength=$(echo "$URLGETOPT" | tr -d '\n' | $awk '{
    IGNORECASE=1 ;
    if (index($0, "summaxlength=") > 0 ){
      gsub(/^.*summaxlength=\x27/, "", $0) ;
      gsub(/\x27.*$/, "", $0) ;
      gsub(/\r/, "", $0) ;
      gsub(/\n/, "", $0) ;
      gsub(/^[●○■□△▽]/, "", $0) ;
      gsub(/<[^>]*>/, "", $0) ;
      if ( $0 ~ /^[0-9]*$/ ){
        print $0 ;
      }else{
        print "'$summaxlength'" ;
      }
    }else{
      print "'$summaxlength'" ;
    }
  }');
  if [ $DEBUG == "TRUE" ]; then echo "summaxlength : $summaxlength" ; fi
}
#
# awk/bash版 <> func_getPermax # POSTされた要約圧縮率を取得 # デフォルト値 perMax=50
# 入力１: $URLGETOPT ( 変数 ) # 入力２: $perMax ( 変数 ) # 出力: $perMax ( 変数 )
function func_getPermax() {
  perMax=$(echo "$URLGETOPT" | tr -d '\n' | $awk '{
    IGNORECASE=1 ;
    if (index($0, "permax=") > 0 ){
      gsub(/^.*permax=\x27/, "", $0) ;
      gsub(/\x27.*$/, "", $0) ;
      gsub(/\r/, "", $0) ;
      gsub(/\n/, "", $0) ;
      gsub(/^[●○■□△▽]/, "", $0) ;
      gsub(/<[^>]*>/, "", $0) ;
      if ( $0 ~ /^[0-9]*$/ ){
        print $0 ;
      }else{
        print "'$perMax'" ;
      }
    } else {
      print "'$perMax'" ;
    }
  }');
  if [ $DEBUG == "TRUE" ]; then echo "perMax : $perMax" ; fi
}
#
# awk/bash版 # パラメータをセット
function parse.setParam(){
  func_getPermax ;                # 要約圧縮率取得
  func_getSummaxlength ;          # 要約圧縮率取得
  func_getArticleType             # 記事タイプ取得
  func_isAscii ;                  #日本語と英語の判定 
}
#
# bash版 # POSTされた記事本文を取得（シェル） # 本文の最大取得文字数 maxLength=1000
function parse.getDescription.sh() {
  DESCRIPTION=$(echo "$URLGETOPT" | \
    tr -d '\n' | \
      sed -e "s/$/\n/g" | \
      cut -c1-"$maxLength" | \
      while read line ;do
        if echo "$line" | LANG=C grep -i "body=" > /dev/null; then
            echo "$line" | \
            sed -e "s/^.*body=\x27//g" \
                -e "s/\x27.*$//g" \
                -e "s/\r//g" \
                -e "s/^[●○■□△▽]//g" \
                -e "s/<[^>]*>//g";
        fi
    done);
  if [ $DEBUG == "TRUE" ]; then echo "DESCRIPTION : $DESCRIPTION" ; fi
}
#
# Awk版 # POSTされた記事本文を取得 # 本文の最大取得文字数 maxLength=3000
# 入力１: $URLGETOPT ( 変数 ) # 入力２: $maxLength ( 変数 ) # 出力: $DESCRIPTION ( 変数 )
function parse.getDescription.awk() {
  DESCRIPTION=$(echo "$URLGETOPT" | tr -d '\n' | cut -c1-"$maxLength" | $awk '{
    IGNORECASE=1 ;
    if (index($0, "body=") > 0 ){
      gsub(/^.*body=\x27/, "", $0) ;
      gsub(/\x27.*$/, "", $0) ;
      gsub(/\r/, "", $0) ;
      gsub(/^[●○■□△▽]/, "", $0) ;
      gsub(/<[^>]*>/, "", $0) ;
      print $0 ;
    }
  }') ;
  if [ $DEBUG == "TRUE" ]; then echo "DESCRIPTION : $DESCRIPTION" ; fi
}
#
# bash版 # POSTされた記事のタイトル（シェル） # $TITLE ;
function parse.getTitle.sh() {
  TITLE=$(echo ${URLGETOPT} | \
    while read line ;do
      if echo "$line" | LANG=C grep -i "title=" > /dev/null; then
        echo "$line" | \
          sed -e "s/^.*title=\x27//g" \
              -e "s/\x27.*$//g" \
              -e "s/\r//g" \
              -e "s/<[^>]*>//g" \
              -e "s/^[●○■□△▽]//g"; 
      fi
    done);
  if [ $DEBUG == "TRUE" ]; then echo "TITLE : $TITLE" ; fi
}
#
# Awk版 # POSTされた記事のタイトルを取得 # タイトルの最大取得文字数 maxLength=3000
# 入力１: $URLGETOPT ( 変数 ) # 入力２: $maxLength ( 変数 ) # 出力: $TITLE ( 変数 )
function parse.getTitle.awk() {
  TITLE=$(echo "$URLGETOPT" | tr -d '\n' | cut -c1-"$maxLength" | $awk '{
    IGNORECASE=1 ;
    if (index($0, "title=") > 0 ){
      gsub(/^.*title=\x27/, "", $0) ;
      gsub(/\x27.*$/, "", $0) ;
      gsub(/\r/, "", $0) ;
      gsub(/<[^>]*>/, "", $0) ;
      gsub(/^[●○■□△▽]/, "", $0) ;
      print $0 ;
    }
  }') ;
  if [ $DEBUG == "TRUE" ]; then echo "TITLE : $TITLE" ; fi
}
#
#bash/awk版 # POSTパラメータを分解 # 入力: 標準入力 # 出力: 標準出力
function urlGetOpt() {
  VarPrefix=
  LongFormat=no
  EvalCheck=true
  $awk -F'[&]' ' 
    BEGIN {
	    FieldSep = ("'"$LongFormat"'" == "yes") ? "\n" : " "
	    VarPrefix = "'"$VarPrefix"'"
	    evalcheck = ("'"$EvalCheck"'" == "true")
	    Hex ["0"] =  0; Hex ["1"] =  1; Hex ["2"] =  2; Hex ["3"] =  3;
	    Hex ["4"] =  4; Hex ["5"] =  5; Hex ["6"] =  6; Hex ["7"] =  7;
	    Hex ["8"] =  8; Hex ["9"] =  9; Hex ["A"] = 10; Hex ["B"] = 11;
	    Hex ["C"] = 12; Hex ["D"] = 13; Hex ["E"] = 14; Hex ["F"] = 15;
	    squote = sprintf ("%c", 39)
	    exitcode = 0
	  }{
	    gsub (/\+/, " ");
	    for ( field=1; field<=NF; ++field ) {
        if ( $field ~ /%[0-9A-F][0-9A-F]/ ) {
          newfield = ""
          for ( i=1; i<=length ($field); i++ ) {
            if ( substr ($field, i, 1) == "%" ) {
              dec = Hex [substr ($field, i+1, 1)] * 16 + \
              Hex [substr ($field, i+2, 1)]
              newfield = sprintf ("%s%c", newfield, dec)
              i += 2;
            } else {
              newfield = newfield substr ($field, i, 1);
            }
          }
          $field = newfield
		    }
        if (evalcheck && !match ($field, /^[a-zA-Z_][a-zA-Z_0-9]*=/)) {
            print "invalid assignment: " $field | "cat >&2"
            exit (exitcode=1);
        }
        if ( $field ~ /\=/ ) {
            newfield  = ""
            equalseen = 0
            fieldlength = length ($field)
            for ( i=1; i<=fieldlength; i++ ) {
              s = substr ($field, i, 1)
              if ( s == "=" ) {
                  if ( !equalseen ) s = s squote
                  equalseen = 1
              } else if ( equalseen ) {	# value
                if ( s == squote ) {
                  if ( i<fieldlength ) {
                      s = squote "\"" squote "\"" squote
                  }
                }
              }
              newfield = newfield s
            }
            if ( s != squote ) {
              $field = newfield squote
            } else {
              $field = newfield "\"" squote "\""
            }
          } else if ( evalcheck ) {
              print "invalid assignment: " $field | "cat >&2"
              exit (exitcode=1)
          }
	      }
	      for ( i=1; i<=NF; ++i ) {
		      printf ("%s%s", VarPrefix, $i)
          if ( i<NF ) printf (FieldSep); else printf ("\n");
        }
	    } END {
	      exit (exitcode)
	  }'
}
# bash版 # # パラメータ解析（シェル） # $URLGETOPT ;
function parse.getOPT.sh(){
  read QUERY_STRING;
  URLGETOPT=$(echo ${QUERY_STRING} | \
    sed -e "s/&nbsp;//g" \
        -e "s/&amp;//g" \
        -e "s/&quot;//g" \
        -e "s/&#039;//g" \
        -e "s/&lt;//g" \
        -e "s/&gt;//g" \
        -e "s/&<b>;//g" \
        -e "s/&<\/b>;//g" \
        -e "s/&<i>;//g" \
        -e "s/&<\/i>;//g" \
        -e "s/&<u>;//g" \
        -e "s/&<>\/u;//g" \
        -e "s/&nbsp;//g" \
        -e "s/&nbsp;//g" \
        -e "s/&nbsp;//g"  | \
     nkf -wLu | urlGetOpt ) ;
  if [ -z "$URLGETOPT" ]; then 
    exit ; 
  fi 
  if [ $DEBUG == "TRUE" ]; then echo "URLGETOPT : $URLGETOPT" ; fi
}
# AWK版 # パラメータ解析 # 入力: QUERY_STRING ( 環境変数 ) # 出力: $URLGETOPT ( 変数 )
function parse.getOPT.awk(){
  read QUERY_STRING ;
  URLGETOPT=$( echo "$QUERY_STRING" | $awk '{
      IGNORECASE=1 ;
      gsub(/&nbsp;/, "", $0) ;
      gsub(/&amp;/, "", $0) ;
      gsub(/&quot;/, "", $0) ;
      gsub(/&#039;/, "", $0) ;
      gsub(/&lt;/, "", $0) ;
      gsub(/&gt;/, "", $0) ;
      gsub(/<b>/, "", $0) ;
      gsub(/<\/b>/, "", $0) ;
      gsub(/<i>/, "", $0) ;
      gsub(/<\/i>/, "", $0) ;
      gsub(/<u>/, "", $0) ;
      gsub(/<\/u>/, "", $0) ;
      print $0 ;
  }' | nkf -wLu | urlGetOpt ) ;
  if [ -z "$URLGETOPT" ]; then exit ; fi 
  if [ $DEBUG == "TRUE" ]; then echo "URLGETOPT : $URLGETOPT" ; fi
}
#
#パラメータ処理
function parse(){
  parse.getOPT.awk ;
#  parse.getOPT.sh ;
  parse.getTitle.awk ;
#  parse.getTitle.sh ;
  parse.getDescription.awk ;
#  parse.getDescription.sh ;
  parse.setParam ;
}
#
