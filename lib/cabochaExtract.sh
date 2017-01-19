#
##########################################################
# 構文解析
##########################################################
#
#<>han2zen
# 半角 英数字記号 を全角文字に変換する
#   abc(1+2) → ａｂｃ（１＋２）
# 半角カタカナ等も対象とする。（2007-11-27）
# 
# 入力：文字列(STDIN)
# 出力：変換後文字列(STDOUT)
#
function han2zen(){
# gsub(reg, s [, t])  において、
# 置換テキスト s では、 & は実際にマッチしたテキストで置き換えられる。
# \& を使用するとリテラルの & を得ることができます。
# さらに、"" 内では、"\\" → \となるので、 \\ を重ねて記載する必要がある。
#   例：  gsub(/＆/,"\\&");
#   sub() や gensub()でも同様。
#
  LANG=ja_JP.UTF-8 ;
  LC_ALL="" ;
  awk ' BEGIN{
      split("０１２３４５６７８９", az, "");
      split("0123456789", ah, "");
      split("ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ", bz, "");
      split("ABCDEFGHIJKLMNOPQRSTUVWXYZ", bh, "");
      split("ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ", cz, "");
      split("abcdefghijklmnopqrstuvwxyz", ch, "");
      split("‘〜’”：；［］＋−＊／＝！＠＃＄％＾＆＊（）＿｜．，＜＞？¥", dz, "");
      ### mawk error
      split("`~\047\":;[]+-*/=!@#$%^&*()_|.,<>?\\", dh, ""); 
      ### mawk error
      split("。「」、・ヲァィゥェォャュョッーアイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワン゛゜", kz, "");
      split("｡｢｣､･ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝﾞﾟ", kh, "");
      split("ウカキクケコサシスセソタチツテトハヒフヘホ", kzb, "");
      split("ヴガギグゲゴザジズゼゾダヂヅデドバビブベボ", kzd, "");
      split("ハヒフヘホ", kzc, "");
      split("パピプペポ", kze, "");
      for( e in dh){
        if(dh[e]=="(") dh[e] = "\\(";
        if(dh[e]==")") dh[e] = "\\)";
        if(dh[e]==".") dh[e] = "\\.";
        if(dh[e]=="|") dh[e] = "\\|";
        if(dh[e]=="^") dh[e] = "\\^";
        if(dh[e]=="$") dh[e] = "\\$";
        if(dh[e]=="[") dh[e] = "\\[";
        if(dh[e]=="]") dh[e] = "\\]";
      }
    } {
      # メインルーチン #
      for(e in ah)  gsub(ah[e],az[e]);  # 半角数字を全角に変換
      for(e in bh)  gsub(bh[e],bz[e]);  # 半角英字を全角に変換（大文字）
      for(e in ch)  gsub(ch[e],cz[e]);  # 半角英字を全角に変換（小文字）
      for(e in dh)  gsub(dh[e],dz[e]);  # 半角記号を全角記号へ変換
      for(e in kh)  gsub(kh[e],kz[e]);  # 半角カナを全角カナへ変換
      for(e in kzb) gsub(kzb[e] "゛",kzd[e]); # 全角カナ + ゛を濁点付の全角カナへ変換
      for(e in kzc) gsub(kzc[e] "゜",kze[e]); # 全角カナ + ゜を半濁点付の全角カナへ変換
      print;
    }' < /dev/stdin ;
}
#
# cabochaコマンドで係り受け解析
# 入力: $DESCRIPTION ( 変数 ) # 出力: $CABOCHA ( 変数 )
function cabochaExtract(){
  CABOCHA=$( echo "$DESCRIPTION" |han2zen| nkf -WLe | cabocha -f1 -d "$JUMANDIC"| nkf -wLu );
  if [ $DEBUG == "TRUE" ]; then echo "CABOCHA : $CABOCHA" ; fi
}
#
