##################################################################
# 日本語語彙体系の辞書データからオントロジーマッピングSVGと
# 語彙テーブルを作成
#
#
#$1 入力ファイル名
#$2 出力ファイル名
function GOImakeList(){
  mkdir -p step1 ;
  :>step1/$2.tmp ;
    cat "$1" | while read line; do
      if echo "$line" | grep "^[[:digit:]]" >/dev/null; then
         echo "$line" | sed -e "s/^/<TITLE>/g" -e "s/$/<\/TITLE><BODY>/g" | tr -d '\n' >> step1/$2.tmp ;
      else
         echo "$line" >> step1/$2.tmp  ;
      fi
    done

	:> step1/$2.tmp1 ;
  cat step1/$2 | while read line; do
		if echo "$line" | grep "<TITLE>" > /dev/null ; then 
			echo "$line" | sed -e "s/$/<\/BODY>/g" >> step1/$2.tmp1 ;
		fi
	done

	:> step1/$2.tmp2 ;
	cat step1/$2.tmp1 | while read line; do
		echo "$line" | sed -e "s/（/ /g" -e "s/）//g" >> step1/$2.tmp2 ;
	done

  wc -l $1 ;
	wc -l step1/$2.tmp ;
	wc -l step1/$2.tmp1 ;
  wc -l step1/$2.tmp2 ;
  /bin/cp step1/$2.tmp2 step1/$2

}

function GOImakeListStep2(){
	IN="$1" ; OUT="$2" ;
	:> "$OUT" ;
	cat "$1" | while read line; do 
		TITLE=$( echo "$line" | sed -e "s/<\/TITLE>.*$//g" -e "s/<TITLE>//g" -e "s/].*$/]/g");
		BODY=$( echo "$line" | sed -e "s/^.*<\/TITLE>//g"  ) ;
#		echo "$TITLE" ;
		echo "$TITLE" | while read line2; do
			iNUM=$( echo "$line2" | awk '{ print $1; }');
#			echo "iNUM : $iNUM" ;
			sTERM=$( echo "$line2" | awk '{ print $2; }' | sed -e "s/　.*$//g" );
#			echo "sTERM : $sTERM" ;
			sDAN=$( echo "$line" | sed -e "s/^.*\[//g" -e "s/\].*$//g" );
#			echo "sDAN : $sDAN" ;
			echo "$sDAN" | while read line3 ; do
				DAN=$( echo "$line3" | awk -F/ '{ print $1; }' );
#				echo "DAN : $DAN" ;
				OYA=$( echo "$line3" | awk -F/ '{ print $2; }' );
#				echo "OYA : $OYA" ;
				SSN=$( echo "$line3" | awk -F/ '{ print $3; }' );
#				echo "SSN : $SSN" ;
				HOE=$( echo "$line3" | awk -F/ '{ print $4; }' );
				if [ ! -z "$HOE" ]; then
					echo "###########################" ;
					exit ;
				fi
				echo "<NO>$iNUM</NO><GOI>$sTERM</GOI><DAN>$DAN</DAN><OYA>$OYA</OYA><SSN>$SSN</SSN>$BODY" >> "$OUT";
			done	
		done
	done	
}
#
function GOImakeListStep3(){
	IN=$1; OUT=$2;
	:> $OUT ;
	cat "$1" | while read line; do
		NO=$( echo "$line" | sed -e "s/^.*<NO>//g" -e "s/<\/NO>.*$//g" );
		GOI=$( echo "$line" | sed -e "s/^.*<GOI>//g" -e "s/<\/GOI>.*$//g" );
		OYA_NO=$( echo "$line" | sed -e "s/^.*<OYA>親//g" -e "s/<\/OYA>.*$//g" );
		DAN=$( echo "$line" | sed -e "s/^.*<DAN>段//g" -e "s/<\/DAN>.*$//g" );
		SSN=$( echo "$line" | sed -e "s/^.*<SSN>子孫//g" -e "s/<\/SSN>.*$//g" );
		BODY=$( echo "$line" | sed -e "s/^.*<BODY>//g" -e "s/<\/BODY>.*$//g" );
		OYA_GOI=$( cat step2/JG_LIST.TXT | grep "^<NO>$OYA_NO</NO>" | sed -e "s/^.*<GOI>//g" -e "s/<\/GOI>.*$//g" );
#		if [ ! -z "$OYA_GOI" ] && [ ! -z "$GOI" ]; then
	 		PAR=$(echo "\"$OYA_GOI\" -> \"$GOI\"" );	
			echo "<NO>$NO</NO><GOI>$GOI</GOI><OYA_NO>$OYA_NO</OYA_NO><OYA_GOI>$OYA_GOI</OYA_GOI><PAR>$PAR</PAR><DAN>$DAN</DAN><SSN>$SSN</SSN><BODY>$BODY</BODY>" >> $OUT
	#		echo "$PAR" | sed -e "s/^/\"/g" -e "s/$/\"/g" -e "s/->/\"->\"/g" -e "s/$/ [label=\"\" comment=\"\" penwidth=2]/g" >> $IS_HAS;
#		fi
	done
	vim $OUT $IS_HAS ;
}
#
function GOImakeListStep4(){
	mkdir -p step4 ;
  IN=$1; OUT=$2	
	:> "$OUT" ;
	cat "$1" | while read line; do
		NO=$( echo "$line" | sed -e "s/^.*<NO>//g" -e "s/<\/NO>.*$//g" );
		#echo "NO:$NO" ;
		KEIRO=$( cat TAG.TXT | grep "\-${NO}$" );
		echo "$line<KEIRO>$KEIRO</KEIRO>" >> $2 ;
	done
}
#
function GOImakeListStep5(){
	#make dot
	IN=$1 ; OUT=$2;
	mkdir -p step5 ;
	:>step5/dot.tmp;
	/bin/cp step4/JG_LIST.TXT step5/JG_LIST.TXT ;
# graphvizのインストール
#yum list available 'graphviz*'
#yum install 'graphviz*'
	cat "$1" | while read line; do
		PAR=$( echo "$line" | sed -e "s/^.*<PAR>//g" -e "s/<\/PAR>.*$//g" -e "s/ - / -> /g" );
	  addLINE=" [label=\"\" comment=\"\" penwidth=\"\" color=\"\"]";
		echo "$PAR""$addLINE">> step5/dot.tmp ;
	done	
 	DOTMAP=$( cat "step5/dot.tmp" );

# step5/digraph.dotの生成
cat <<- EOS >$OUT
  digraph G {
    size="500, 500";
    node [fontname=mincho fontsize=14 shape=plaintext,width=.1,height=.1 ];
  graph [
    charset = "UTF-8";
//		labelfload="false", 
		overlap = "false", 
		splines = "true", 
//    labelloc = "t",
//    labeljust = "c",
//    bgcolor = "#343434",
//    fontcolor = white,
//    fontsize = 18,
//    style = "filled",
//    rankdir = TB,
//    margin = 0.2,
//    layout = circo
//    layout = dot
//    layout = fdp
//    layout = neato
//    layout = osage
//    layout = sfdp
    layout = twopi
 ]
$DOTMAP 
 	}
EOS

	#dot -Tpng -o ont.png step5/digraph.dot ;
  #  実行には相当時間がかかりますができます。
  #  dot -Tsvg -o ont.svg step5/ont.dot ;

#画像の表示ミドルのインストール
# yum install eog 
#	eog ont.svg ;

 mv JG_LIST.TXT GOITAIKEI
}
#
#"何になったら好いと"->"思うな" [label="2.12" comment="273,274" penwidth=3 color="#35aa47"]
function GOIprintHTML(){
 	DOTMAP=$( cat "TAG.TXT" );

cat <<- EOS >ontology.html 
<html><head><meta charset="utf-8"><body>
<script type="text/vnd.graphviz" id="cluster">
  digraph G {
    size="500, 500";
    node [fontname=mincho fontsize=14 shape=plaintext,width=.1,height=.1 ];
  graph [
    charset = "UTF-8";
//		labelfload="false", 
		overlap = "false", 
		splines = "true", 
//    labelloc = "t",
//    labeljust = "c",
//    bgcolor = "#343434",
//    fontcolor = white,
//    fontsize = 18,
//    style = "filled",
//    rankdir = TB,
//    margin = 0.2,
//    layout = circo
//    layout = dot
//    layout = fdp
//    layout = neato
//    layout = osage
//    layout = sfdp
//    layout = twopi
 ]
$DOTMAP 
 	}
</script>
<script src="viz.js"></script>
<!-- script src="viz.js"></script -->
<script>
  function inspect(s) {
    return "<pre>" + s.replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/\\\\"/g, "&quot;") + "</pre>"
  }
  function src(id) {
    return document.getElementById(id).innerHTML;
  }
  function example(id, format, engine) {
    var result;
    try {
      result = Viz(src(id), format, engine);
      if (format === "svg")
        return result;
      else
        return inspect(result);
    } catch(e) {
      return inspect(e.toString());
    }
  }
   document.write(example("cluster", "svg"));
</script>
</body></html>
EOS
}

# step1
# out step1/JG_LIST.TXT
# GOImakeList J_GOI.TXT JG_LIST.TXT ;              #名詞
# step2
# GOImakeListStep2 step1/JG_LIST.TXT step2/JG_LIST.TXT  ;
# step3
# GOImakeListStep3 step2/JG_LIST.TXT step3/JG_LIST.TXT ;

# オントロジーマップと紐づくテーブルを作成
# step4
# GOImakeListStep4 step3/JG_LIST.TXT step4/JG_LIST.TXT ;

# オントロジーマップSVGを作るためのdotファイルを作成
# step5
# GOImakeListStep5 step4/JG_LIST.TXT step5/ont.dot ;

# オントロジーマップのHTML版
# dotファイルをヒアドキュメントする
# GOIprintHTML ;
# exit ;

