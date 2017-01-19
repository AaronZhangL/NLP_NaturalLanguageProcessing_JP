#
###############################################################
# オントロジーによる要約
###############################################################
#
# <> func_Summarize
# 要約する
#
# 入力１: $awkTermExtractList ( 変数 )
# 入力２: $DESCRIPTION ( 変数 )
# 入力３: $perMax ( 変数 )
# 出力: $SUMMARY_RESULT_LINE ( 変数 )
#
#処理内容：
#１センテンスごとにスコアリングする
#センテンスごとにキーワードをgrepして含まれたらセンテンスのスコアを加算する
#マッチするキーワードとスコアはexec_TermOrgNameExtractの結果を使用する
#センテンスごとにループする。
#
# センテンスの単位
# 引数に渡された文章を「。」区切りで改行する
# 複数の空白を一つにする。
# 句点「。」があれば改行をいれる。
# 「」（）の中であれば句点があっても改行をいれない
# CRLFをLFに変換する。
#
# DESCRIPTION:
# 勝ち点４で明大と並んだが、勝率で上回った。早大は１１月１０日開幕の明治神宮大
# 会への出場も決めた。   斎藤はスライダーやツーシームなどの変化球がさえ、リーグ
# 戦初完封。被安打４で１５奪三振の力投で今季４勝目を挙げた。
# DESCRIPTIONを句点改行した状態:
# 勝ち点４で明大と並んだが、勝率で上回った。
# 早大は１１月１０日開幕の明治神宮大会への出場も決めた。
# 斎藤はスライダーやツーシームなどの変化球がさえ、リーグ戦初完封。
#
function summaryExtract.Summarize(){
  #重要語リストの改行をデリミタ（|）へ変換する
  TELln=`echo -e "$awkTermExtractList" | tr "\n" "|" ` ;
  SUMMARY_RESULT_LINE=`echo -e "$DESCRIPTION" | func_KutenKaigyo | \
    $awk -v aTELln="$TELln"  '
    function alength(A,  n, val) {
        n = 0
        for (val in A) n++
        return n
    }
    function _asort(A,  hold, i, j, n) {
        n = alength(A)
        for (i = 2; i <= n ; i++) {
            hold = A[j = i]
            while (A[j-1] > hold) {
                j--
                A[j+1] = A[j]
            }
            A[j] = hold
        }
        delete A[0 ]
        return n
    } 
    BEGIN {
    sentenceNo=1;#センテンス番号 1ずつインクリメントしていく
    gMax=0;#文章全体のバイト数
    perMax="'$perMax'"; #圧縮率
    summaxlength="'$summaxlength'"; #要約文字数
    #あらかじめ重要語とスコアのハッシュを作っておく
    #TermExtractList
    #3  早大
    #3  慶大
    #2  斎藤
    #1  エース 加藤 幹
    #1  大学 野球 秋季 リーグ
    split(aTELln, atarray, "|") ;
    for ( i=1 ; i <= length(atarray) ; i++ ){
      termex=atarray[i] ;
      #mawk未対応の記述
	    #match( termex, /^([\.0-9]*) (.*)$/, ex);
      split( termex, ex, " ");
            #ex[1] スコア ex[2] 重要語
            term_hash[ex[2]] += ex[1];
	    #ex[2]=早大 ex[1]=3.00000000000000
	    #ex[2]=大学 野球 秋季 ex[1]=1.83400808640933
	    #ex[2]=明治 神宮ex[1]=1.58740105196815 
    }
    #term_hash
    #[早大]=3
    #[慶大]=3
    #[斎藤]=2
    #[エース 加藤 幹]=1
    #[大学 野球 秋季 リーグ]=1
	}/[^ ]/{ 
  #空文字列の場合はスキップして次の行にいく
    if ($0 == NULL){
      next ;
    }
    #score:センテンスの点数
    score=0
    #BEGIN節で作った重要語リストをループで回しセンテンスに含まれるものがあるか見ていく
    for (ex_term in term_hash) {
      tmp_score=0;#重要語を構成するトークンごとに加算する
      TmpWords=0;#重要語を構成するトークンがどれだけ含まれるか
		  #重要語はトークンに分かれているのでトークンごとにマッチするか見ていく
		  #例: 
		  #$0:東京六大学野球秋季リーグは３０日、神宮球場で最終週の早大—慶大３回戦があり、早大が斎藤（１年、早稲田実）の活躍で慶大に７—０で大勝し、３季連続４０度目の優勝を果たした。
		  #ex_term:大学 野球 秋季 リーグ
		  #terms[1]:大学 terms[2]:野球 terms[3]:秋季 terms[4]:リーグ
		  #n:4
		  #重要語をトークンごとに半角スペース区切りでスプリットする
		  #TODOトークンごとに区切らずにくっつけてからgrepしたほうがいい？
      #トークンごとにループする
      n=split(ex_term, terms, " ") ;
      for (i = 1; i <= n; i++) {
        regexp=terms[i];
        #トークンがセンテンスに含まれるか判定する
        if (index($0, regexp) > 0 ){
          #マッチ数をカウントする
          TmpWords++;				
          #TODO awkの桁数がデフォだと6桁になる模様
			    #含まれたら重要語の持っている点数をtmp_scoreに加算する
				  #重要語のトークン数が多いほど点数が加算される
				  #大学 野球 秋季 リーグの重要語の点数が 1.8だとすると
				  #4回含まれることになるので1.8X4=7.2加算される
				  tmp_score+=term_hash[ex_term];
        }
      }
      #トークンの全てにマッチした場合だけtmp_scoreの点数をセンテンスの点数に加算する
      #重要語が「大学 野球 秋季 リーグ」の場合大学 野球だけ含まれて秋季 リーグが含
      #まれなかった場合は加算しない
      #n 重要語のトークン数
      #TmpWords センテンスに含まれていた重要語のトークンの個数
      if (n == TmpWords){
				score+=tmp_score;		
      } 
    }
	  #スコアリングの結果をハッシュに格納する
    #length($0) センテンスのバイト数
	  #$0:東京六大学野球秋季リーグは３０日、神宮球場で最終週の早大—慶大３回戦があり、早大が斎藤（１年、早稲田実）の活躍で慶大に７—０で大勝し、３季連続４０度目の優勝を果たした。
    #score:33.625
    intscore=int(score * 10000);
    SummaryRank_hash[sentenceNo]=sprintf("%10d%s%s%s%s%s%s%s%s", intscore, SUBSEP, sentenceNo, SUBSEP, length($0), SUBSEP, $0, SUBSEP, score);
    # 1 intscore 小数だとasortできないので、sort用に10000倍したスコア
    # 2 行番号
    # 3 本文の長さ
    # 4 本文
    # 5 スコア
    #段落番号をインクリメントする
    sentenceNo++;
    #文章のバイト数を追加する
    gMax+=length($0);
  }END{
    #SummaryRank_hashをscore順にソートする 
    #asort(SummaryRank_hash,SummaryRank_hash_s);
    hash_length = _asort(SummaryRank_hash);
    #全体の文字数を初期値とする。wc -c のような
    charMax= gMax * perMax / 100;
    if (summaxlength !=""){
      charMax=summaxlength + 0;
    }
	  #センテンスをスコア順にソート
    tmpMax=0;
    #for (i=NR; i>=1; i--) {
    for (i=hash_length; i>=1; i--) {
      #指定した圧縮率に達したらループを抜ける  
      #半角スペース区切りで分割する
      if (tmpMax >= charMax){
        break; 
      }
      split(SummaryRank_hash[i], sa, SUBSEP);
      intscore = sa[1];
      sentenceNo = sa[2];
      body_length = sa[3];
      body = sa[4];
      score = sa[5];
      SummaryRank_hash_sort[sentenceNo]=sprintf("%10d%s%s%s%s%s%s%s%s", intscore, SUBSEP, sentenceNo, SUBSEP, body_length, SUBSEP,body, SUBSEP, score);
      #バイト数を加算する
      tmpMax +=sa[3];
    }
	  # 出力はセンテンスの序列を維持したままとしたい。
    tmpMax = 0 ;
    for (i=1; i<=NR; i++) {
      split(SummaryRank_hash_sort[i], sa, SUBSEP);
      #if ( sa[1] > 0 ){
          #本文を出力
          printf "%s", sa[4];
          tmpMax +=sa[3];
      #}
    }
    #圧縮率を計算する
    #tmpMax:サマリーに使用する文章のバイト数の合計
    #gMax:文章全体のバイト数
    ratio= tmpMax * 100 / gMax ;
    summury_length= tmpMax;
    if(summaxlength !=""){
      printf "<SUMMARY_RATIO>%s文字</SUMMARY_RATIO>", summury_length ; 
    }else{
      printf "<SUMMARY_RATIO>%5.2f%%</SUMMARY_RATIO>", ratio ;
    }
  }'` ; 
  SUMMARY_RESULT_LINE_ONTOLOGY="$SUMMARY_RESULT_LINE" ; 
  if [ $DEBUG == "TRUE" ]; then echo "SUMMARY_RESULT_LINE : $SUMMARY_RESULT_LINE" ; fi
  SUMMARY_RESULT_LINE="<SUMMARY>$SUMMARY_RESULT_LINE_ONTOLOGY</SUMMARY>" ;
}
#
# オントロジーによる要約文抽出
# 入力１: $IS_TABLE_FIN ( 変数 )  IS_TABLEとTERMEXを重ねる
# 入力２: $HAS_TABLE_FIN ( 変数 )  HAS_TABLEとTERMEXを重ねる
# 入力３: $IS_HAS_TABLE ( 変数 )  HAS_TABLE
# 入力４: $TITLE_KEYS_RESULT_LINE
# 入力５: $DESCRIPTION
# 入力６: $HTML_EXTRACT_OPINIONS_RESULT_LINE
# 入力７: $JUUYOU_LINE
# 出力: $awkTermExtractList ( 変数 ) ノードとスコアのリスト
#
  #ノードによる重み付け
  #(1)単語毎の重要度：上記重要語の抽出アルゴリズムを用いて算出
  #(2)人名／地名／組織／日付の重要度：単語毎に1を加算する
  #(3)係り受けの数：オントロジー解析の結果より算出した単語毎に借り受けられた数を算出
#
function summaryExtract.calc_imp_by_HASH_ontology(){
  #RetNode=`echo -en "$IS_TABLE_FIN\n$HAS_TABLE_FIN" | LANG=C sort -s -k1 -u | $awk -F '@@@' '
  RetNode=`echo -en "$IS_TABLE_FIN\n$HAS_TABLE_FIN" | LANG=C sort -s -k1 -u | awk -F '@@@' '
    {
      exWord = $1;
      gsub(/peripheries.*$|\[|\"|/,"",exWord);
      exSum = $1;
      gsub(/^.*\(T|R.*$|\)\".*$/,"",exSum);
      exR = $1;
      gsub(/^.*R|\)\" .*$|T.*$||>\(/,"",exR);
      if ( length(exR) > 1 ){
       exSum = exSum + exR;
      }
     if (index($1, "color") > 0 ){
       exSum = exSum + 1;
     }
      print exSum " " exWord;
    }'`;
  #エッジによる重み付け
  #(4)係り受けの重要度：cabochaコマンドで出力されたものを用いる
  RetEdge=`echo -en "$IS_HAS_TABLE" | LANG=C sort -s -k1 -u | $awk -F '@@@' '
    {
      if (index($1,"\"\"->") > 0 ){
        next;
      }
      sahen = $1;
      gsub(/->.*$|\"/,"",sahen);
      uhen = $1;
      gsub(/^.*->| \[label.*$|\"/,"",uhen);
      label = $1;
      gsub(/^.*label=\"|\" comment.*$/,"",label);
      print label " " sahen " " uhen;
    }'`;
  #(5)タイトル、見出しを元にした重要度：タイトル、見出しより単語毎の重要度を加算する
  TKRL=`echo -en "$TITLE_KEYS_RESULT_LINE" | sed -e "s/<KEY>//g" -e "s/<SCORE>/ /g" -e "s/<\/SCORE><\/KEY>/|/g" -e "s/|$//g"`;
  RetNode=`echo -en "$RetNode" | $awk '
    BEGIN {
      split("'"$TKRL"'" , tkrl , "|" );
    } {
        for( i in tkrl){
          split(tkrl[i] , tk , " " );
          if (length(tk[1]) > 0 && index($2, tk[1]) > 0 ){
            $1 = $1 + tk[2];
          }
        }
        print $1 " " $2;
    }'`;
  #(6)文の位置情報による重要度：記事の前の方に出ている語の重要度を上げ、文の重要度を計算する
  DESC=`echo -en "$DESCRIPTION" |LANG=C grep -i -v '^\s*$' | func_KutenKaigyo | tr "\n" "|"`;
  RetNode=`echo -en "$RetNode" | $awk '
    BEGIN {
      split("'"$DESC"'" , desc , "|" );
    } {
        if (index(desc[1],$2) > 0 ){
          $1 = $1 + 1;
        }
        print $1 " " $2;
    }'`;
  #(7)意見評価表現を含むエッジのスコアを加算する
  #incへ設定した数が加算される
  #HTML_EXTRACT_OPINIONS_RESULT_LINE
  #<EX_OPINIONS><![CDATA[[著者] 批評+ 勝率で上回った。 [著者] 採否+
  #１１月１０日開幕の明治神宮大会への出場も決めた。]]></EX_OPINIONS>
  #RetEdge
  #3.65 慶大は 力尽きた
  #5.05 明大と 並んだが
  #0.00 決めた リーグ戦初完封
  #1.16 斎藤は リーグ戦初完封
  #3 開幕の 明治神宮大会への
  EXLINE=`echo "$HTML_EXTRACT_OPINIONS_RESULT_LINE"|tr -d "\n"|sed -e "s|\]||g" -e "s|\[||g" -e "s|\!||"`;
  RetEdge=$(echo -en "$RetEdge" | $awk '
  BEGIN {
    exline = "'"$EXLINE"'";
    inc = 1;
  }/./ {
    if (index(exline, $2$3) > 0 ){
      $1 = $1 + inc;
    }
    print $1" "$2" "$3 
  }');
  #(8)単語間のつながりと関係性情報の重要度：高い活性値を得た単語、句、文を重要と見なし加算する
  #\"早大—慶大\"->\"３回戦が\"->\"あり\"->\"果たした\"->\"上回った\"->\"決めた\"
  #  ->\"リーグ戦初完封\"->\"挙げた\"->\"加点した\"->\"力尽きた\"
  JL=`echo -en "$JUUYOU_LINE" | sed -e "s/->/|/g" -e "s/\"//g"` ;
  #JL=`echo -en "$JUUYOU_LINE" | sed -e "s/->/|/g" -e "s/\\\\\\\\\"//g"` ;
  RetNode=`echo -en "$RetNode" | LANG=C sort -s -k1 -u | $awk '
    BEGIN {
      split( "'"$JL"'" , jl , "|" );
    } {
        for( i in jl){
          if (length(jl[i]) > 0 && index($2, jl[i]) > 0 ){
             $1 = $1 + 1;
          }
        }
        print $1 " " $2;
    }'`;
  #不要な行をなくす
  RetEdge=$(echo -en "$RetEdge" | $awk '
    /./{
      if (index($1, "0.00") > 0 ){
        next;
      }
      print $1 " " $2 " " $3;
    }');
  awkTermExtractList=`echo -en "$RetNode\n$RetEdge"`;
  awkTermExtractList_ontology="$awkTermExtractList" ; 
  if [ $DEBUG == "TRUE" ]; then echo "awkTermExtractList : $awkTermExtractList" ; fi
}
#
function summaryExtract(){
    summaryExtract.calc_imp_by_HASH_ontology;
    summaryExtract.Summarize;
}
#
