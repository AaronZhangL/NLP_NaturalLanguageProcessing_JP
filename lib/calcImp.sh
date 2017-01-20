#
##########################################################
# 重要度計算
##########################################################
#
#<>get_pre_post_pp2
# 連接情報取得,重要度計算 pp用
#
# 入力１: $NcontList ( 変数 )
# 入力２: $MAX_CMP_SIZE ( 変数 ) :default 1024; 半角空白区切りの単名詞リストの最大長 
# 入力３: $CmpNounListFile ( ファイル )
# 入力４: $average_rate ( 変数 )
# 入力５: $frq ( 変数 )
# 出力: $awkTermExtractList ( 変数 )
#
function get_pre_post_pp2(){
  awkTermExtractList=`echo $NcontList | $awk '
    BEGIN {
      MAX_CMP_SIZE=int("'$MAX_CMP_SIZE'") ;
      wc = 0;
      #頻度を取り出す（頻度はcmpNounListFileから取り出す）
      while ( getline termex < "'$CmpNounListFile'" > 0 ) {
        match( termex, /^.*([\.0-9]+)[[:blank:]](.*)$/, ex);
        #ex[1] 頻度 ex[2] 重要語
        #[重要語]=頻度 の形でハッシュを作る
        #print "ex2:" ex[2] ; #debug
        term_hash[ex[2]] += ex[1];
        CmpNounList[wc] = termex ;
        wc++ ;
      }
      count=0;
      average_rate="'$average_rate'";
      frq="'$frq'";
    }{
      #頻度を除いて重要語だけ取り出す。 ex:大学 野球 秋季 リーグ
      cmp_noun=$0;
      gsub( /^[[:blank:]]*/, "", cmp_noun) ;
      gsub( /^[0-9]*[[:blank:]]/, "", cmp_noun) ;
      freqc=term_hash[cmp_noun] ;
        
      #データがない場合は読み飛ばし
      if ( cmp_noun == "" ) { next; }
      #最大長に達した場合は読み飛ばし
      cmp_nounlength = length(cmp_noun) ;
      if ( cmp_nounlength > MAX_CMP_SIZE ){ next ; }
      #複合語の場合、連接語の情報をハッシュに入れる。
      #複合語をスペース区切りで分解する。
      #ex:大学 野球 秋季 リーグ -->大学
      #                            野球 
      #                            秋季
      #                            リーグ
#NounList
#三振
#完封
#斎藤
#早大
#東京
#連覇
#大学 野球
#IgnoreWords
#test 大学
      #連接情報取得処理をスキップするものがある。
      #IgnoreWords で指定した語と数値を無視する
      ## 1から始まって、１列目が１で、２列目が２
      NounListNum = split(cmp_noun, NounList, " ");
      for ( i = 1; i <= NounListNum; i++){
#	       print "NounList[" i "]= " NounList[i] ;
        for ( j = 1; j <= IgnoreWordsNum; j++){
           #print "IgnoreWords[" j "]= " IgnoreWords[j] ;
           if( NounList[i] == IgnoreWords[j] ) { 
              #print "delete:" NounList[i] ;
               delete NounList[i] ;
           }
        }
        ## 必要性不明
        #	  if( NounList[i] ~ /^[0-9\,\.]+/){
        #	     print "delete:" NounList[i] ;
        #	     delete NounList[i] ;
        #	  }
      }
      # 複合語でない場合は連接情報を取得しない。
      nounlength = length(NounList) ;
      if( nounlength < 2 ){ next ; }
      #連接情報取得処理。
      for ( i = 1; i < nounlength; i++){
        #print "NounList[" i "]= " NounList[i] ;
        noun_0=NounList[i] ;
        noun_1=NounList[i+1] ;
        comb_key=NounList[i]" "NounList[i+1] ;
        #TODO 要必要性確認 必要ならawk化
        #if [ -z "${comb[\"$comb_key\"]}" ] ; then
        #	  first_comb=1;
        #fi
        #連接語の延べ数 pre部分
        if ( stat_pre[noun_0] == "" ){ stat_pre[noun_0] = 0; }
        stat_pre[noun_0]=stat_pre[noun_0] + $freqc ;
        #連接語の延べ数 post部分
        if ( stat_post[noun_1] == "" ){ stat_post[noun_1] = 0; }
        stat_post[noun_1]=stat_post[noun_1] + $freqc ;
        #print "stat_pre:"noun_0":"stat_pre[noun_0] ;
        #print "stat_post:"noun_1":"stat_post[noun_1] ;
        # 前後の単語セットの連想配列と、単語セットで頻度を格納する連想配列を２つ作る
        # 前の単語がキーとなり、後ろの単語が値となる連想配列:pre_noun
        # 後ろの単語がキーとなり、前の単語が値となる連想配列:post_noun
        # 単語セットがキーとなり、値が頻度の連想配列:pre_post
        #単語ごとの連接語情報 pre部分
        if ( pre_noun[noun_0] == "" ){ 
          pre_nounfreq[noun_0] = 1 ;
          pre_post[noun_0,noun_1]=1 ;
        } else {
          pre_nounfreq[noun_0]++;
          pre_post[noun_0,noun_1]++ ;
        }
        pre_noun[noun_0]=noun_1 ;
        #print "pre_noun[" noun_0 "]=" pre_noun[noun_0] ;
        #print "pre_post[" noun_0 "," noun_1 "]=" pre_post[noun_0,noun_1] ;
        #単語ごとの連接語情報 post部分
        if ( post_noun[noun_1] == "" ){ 
          post_nounfreq[noun_1] = 1 ;
          pre_post[noun_1,noun_0]=1 ;
        } else {
          post_nounfreq[noun_1]++;
          pre_post[noun_1,noun_0]++ ;
        }
        post_noun[noun_1]=noun_0 ;
        #print "post_noun[" noun_1 "]=" post_noun[noun_1] ;
        #print "pre_post[" noun_1 "," noun_0 "]=" pre_post[noun_1,noun_0] ;
        #print "pre_nounfreq=" pre_nounfreq[noun_0];
        #print "post_nounfreq=" post_nounfreq[noun_1];
        stat[noun_0] = stat_pre[noun_0] ;
        stat[noun_1] = stat_post[noun_1] ;
        ## 移動元 ##
      } #nounlength for end
    }END{
      # 必要以上にループしてる## 移動元 ##から移動
      # 現段階のstat_preとstat_postに入っている全ての単名詞について処理
      # このループでは最終的にmy %stat_PP:パープレキシティ用の形態素別統計情報
      # に単語$noun1をキーとして$hを値にいれる
      for ( noun1 in stat ) {
        #noun1は日本語キー
        #print "noun1=" noun1 ; #debug
        #print "stat[" noun1 "]=" stat[noun1] ; #debug
        h = 0;
        work ="" ;
        # awkでは２次元配列が万全ではないので、シェルの考え方を活用する
        # シェルでもファイルを使って多次元配列のようなことをしているので、配列２つ使う
        ##全ての単名詞について処理 pre
        # 頻度を取り出す
        prefreq=stat_post[noun1] ; #なぜかprefreqをstat_postから取り出す原文
        if ( prefreq == "") {
          #print "prefreq null" ; #debug
          #何もしない
        }else{
          #print "prefreq="prefreq ;
          prefreq = prefreq + 1 ;
          for ( noun2 in pre_noun){
            preline = pre_noun[noun2] ; # 処理継続判定用
            if ( preline != noun1 ) { 
              #print "continue" ; #debug
              continue ; 
            }
            preppfreq = pre_post[noun1,noun2] ; #その単語が含まれる連接語全部の頻度を取得
            work = preppfreq / prefreq; 
            #print work "=" preppfreq "/" prefreq ;
            h = h - ( work  * log(work) ) ;
          }
        }
        ##全ての単名詞について処理 post
        # 頻度を取り出す
        postfreq=stat_pre[noun1] ; #なぜかpostfreqをstat_preから取り出す原文
        if ( postfreq == "") {
          #print "postfreq null" ; #debug
          #何もしない
        }else{
          #print "postfreq="postfreq ; #debug
          postfreq = postfreq + 1 ;
          for ( noun2 in post_noun){
            postline = post_noun[noun2] ; # 処理継続判定用
            if ( postline != noun1 ) { 
              #print "continue" ; #debug
              continue ; 
            }
            postppfreq = pre_post[noun1,noun2] ; #その単語が含まれる連接語全部の頻度を取得
            work = postppfreq / postfreq ; 
            h = h - ( work  * log(work) ) ;
          }
        }
        stat_PP[noun1]=h ;
        #print "stat_PP[" noun1 "]=" h ; #debug
        #print ""; #debug
      } # stat for end
    }END{
      ## ncont_list.txtではなくcmp_noun_list.txtを回したい。
      ## BEGIN節で呼び出しているので、そこで配列化。
      ## 一度作ったstat_PP連想配列をそのまま使えるのでENDで繋いで処理継続。
      #print "重要度計算スタート--------------------------------" ;
      for ( end_i =0; end_i<wc; end_i++){
         ## get_imp_pp部分  もう一回リストをなめて処理
         split(CmpNounList[end_i],CmpNoun) ;
         #頻度を取り出す
         freqc=CmpNoun[1] ;
         #print "freqc:" freqc ;
         #頻度を除いて重要語だけ取り出す。 ex:大学 野球 秋季 リーグ
         cmp_noun=CmpNounList[end_i] ;
         gsub( /^[[:blank:]]*/, "", cmp_noun) ;
         gsub( /^[0-9]*[[:blank:]]/, "", cmp_noun) ;
         #print "cmp_noun:"cmp_noun ;
         #データがない場合は読み飛ばし
         if ( cmp_noun == "" ) { continue; }
         #最大長に達した場合は読み飛ばし
         cmp_nounlength = length(cmp_noun) ;
         #print cmp_noun ;
         if ( cmp_nounlength > MAX_CMP_SIZE ){ continue ; }
         #重要語を単名詞に分解し、単名詞ごとにループで回し、先ほど取得した
         #パープレキシティ用の形態素別統計情報を加算する
         NounListNum = split(cmp_noun, NounList, " ");
         for ( i = 1; i <= NounListNum; i++){
            #print "NounList[" i "]= " NounList[i] ;
            word = NounList[i] ;
            for ( j = 1; j <= IgnoreWordsNum; j++){
            #IgnoreWords で指定した語と数値を無視する
            #print "IgnoreWords[" j "]= " IgnoreWords[j] ;
              if( NounList[i] == IgnoreWords[j] ) { 
                 #print "delete:" NounList[i] ;
                 delete NounList[i] ; continue ;
              }
            }
            #先ほど取得したパープレキシティ用の形態素別統計情報を重要度に加算する
            if ( stat_PP[word] != "" ){
              #print "stat_PP[" word "]=" stat_PP[word] ;
              imp = imp + stat_PP[word];
            }
            count++;
         } # NounListNum for end
         if ( count == 0 ) { count = 1; }
         imp = imp / (2 * average_rate * count ) ;
         if ( $frq != 0 ) {
           imp = imp + log(freqc + 1) ;
           #print "imp =" imp " + log(" freqc " + 1)" ;
         }
         imp = imp / log(2) ;
         print imp " " cmp_noun ; # 最終出力
         count = 0 ; imp = 0 ;
      } #end_i for end
    } '`
}
#<>modify_noun_list
# score順にソートする
#
function modify_noun_list(){ 
  awkTermExtractList=$(echo "$awkTermExtractList"| LANG=C sort -s -k1 -nr) ; 
}
#================================================================
#
# Calicurate importance of word by DB. （連接語統計DBから重要度を計算）
# And return sorted list by importance.
#
# usage: @array = $self->calc_imp_by_DB
#
#================================================================
#連接情報をDBに格納しておいて他の文書で使用された連接情報を重要度に反映する
calc_imp_by_DB(){
  imp="1";
  count="0";
  if [ "$average_rate" -eq 0 ];then
    echo "average_rate is invalid value";
    exit;
  fi 
  # 頻度をFrequency か TF のいずれでとるかを選択
  if [ "$frq" -eq 2 ];then
     calc_imp_by_HASH_TF;  
     NcontList="$awkTermExtractList" ;
  else
     NcontList="$comNounList";
  fi	  
  awkTermExtractList="";  
  #名詞ごとに回す 
  #「三振」「大学 野球」「秋季 高校 野球 大会」の単位でまわる
  while read n_count;do
    local freq=`echo "$n_count"|awk '{print $1;}'`;
    local cmp_noun=`echo "$n_count"|awk '{$1="";print $0;}'|sed -e "s|^ ||"`;
    #空ならスキップ
    if [ "$cmp_noun" = "" ];then
      continue;
    fi
    #単語の文字数が長すぎたらスキップ
    if [ "${#cmp_noun}" -gt "$MAX_CMP_SIZE" ];then
      continue;
    fi
    cmp_noun_array=(`echo "$cmp_noun"`);
    #単名詞ごとに回す
    #秋季 高校 野球 大会 だったら「秋季」「高校」「野球」「大会」の４回まわる
    for noun in "${cmp_noun_array[@]}";do
      if cat "$IgnoreWordsFile"|grep "^$noun$">/dev/null;then
        continue;
      fi
      if echo "$noun"|grep "^[0-9\.\,]*$" >/dev/null;then
        continue;
      fi
      stat_db_noun=`cat "$stat_db"|grep "^$noun,"`;
      #連接DBから他の文書で使われた連接情報を取り出す
      if [ -n "$stat_db_noun" ];then
        uniq_pre=`echo "$stat_db_noun"|awk -F, '{print $2;}'`;
        total_pre=`echo "$stat_db_noun"|awk -F, '{print $3;}'`;
        uniq_post=`echo "$stat_db_noun"|awk -F, '{print $4;}'`;
        total_post=`echo "$stat_db_noun"|awk -F, '{print $5;}'`;
      else
        uniq_pre="0";
        total_pre="0";
        uniq_post="0";
        total_post="0";
      fi
      # 連接語の延べ数をとる場合
      if [ "$LR" = "1" ];then
        imp=$(($imp*$(($total_pre + 1))*$(($total_post + 1)))); 
      ## 連接語の異なり数をとる場合
      elif [ "$LR" = "2" ];then
        imp=$(($imp*$(($uniq_pre + 1))*$(($uniq_post + 1)))); 
      fi
      count=$(($count + 1));
    done
    if [ "$count" -eq 0 ];then
      count=1;
    fi
    # 相乗平均で重要度を出す
    imp=`awk 'BEGIN{
        average_rate="'$average_rate'"; 
        count="'$count'";
        imp="'$imp'";
        frq="'$frq'";
        OFMT="%.6f" ;
          if ( frq != 0 ){
             imp = imp ^ (1 / (2 * average_rate * count));
             imp = imp * frq;
          } else {
             imp = imp ^ (2 / (2 * average_rate * count));
          }
          print imp;
    }'`;
    if [ -n "$awkTermExtractList" ];then
      awkTermExtractList="$awkTermExtractList
$imp,$cmp_noun";  
    else
      awkTermExtractList="$imp,$cmp_noun";  
    fi
    count="0";
    imp="1";
  done  < <(echo "$NcontList")
  #スコア順にsortする
  modify_noun_list; 
}

#
#<> calc_imp_by_HASH_PP
# <LRPP>（連接情報＋各単名詞のエントロピーのべき乗の合計）
#
# 入力１: $comNounList ( 変数 )
# 入力２: $MAX_CMP_SIZE ( 変数 )
# 入力３: $CmpNounListFile ( ファイル )
# 入力４: $average_rate ( 変数 )
# 入力５: $frq ( 変数 )
# 出力: $awkTermExtractList ( 変数 )
#
function calc_imp_by_HASH_PP(){
  imp=0;       # 専門用語全体の重要度
  count=0; # ループカウンター（専門用語中の単名詞数をカウント） 
  # 頻度をFrequency か TF のいずれでとるかを選択
  if [ "$frq" -eq 2 ];then
     calc_imp_by_HASH_TF;  
     NcontList="$awkTermExtractList" ;
  else
     NcontList="$comNounList";
  fi	  
  #連接情報取得,重要度計算
  get_pre_post_pp2;
  #スコア順にsortする
  modify_noun_list; 
}
#
#<> calc_imp_by_HASH_TF
# TFを使っての重要度計算
#
# 入力１: $comNounList ( 変数 )
# 入力２: $MAX_CMP_SIZE ( 変数 )
# 出力１: awkTermExtractList ( 変数 )
# 出力２: $CmpNounListFile ( ファイル )
#
function calc_imp_by_HASH_TF(){
    #
    #cmpNounListFile
    #2 リーグ
    #1 大学 野球
    #1 完封
    #1 秋季 リーグ
    #1 秋季 リーグ 早大
    #1 連覇
    #
    #awkLengthListの処理： 重要語をトークン数ごとに並べなおす
    #awkLengthList
    #東京,五輪,優勝（１トークン）
    #東京 五輪,リーグ 戦,適時 打（２トークン）
    #東京 五輪 オリンピック（３トークン）
    awkLengthList=`echo "$comNounList" | $awk '
    BEGIN {
        MAX_CMP_SIZE=int("'$MAX_CMP_SIZE'") ;
     } {
        #ex:5 大学 野球 秋季 リーグ frqc=5  cmp_noun=大学 野球 秋季 リーグ
        #頻度を取り出す ex:1
        freqc=$1 ;
        #頻度を除いて重要語だけ取り出す。 ex:大学 野球 秋季 リーグ
        #TODO 最短マッチになっているか確認
        cmp_noun=$0 ;
        gsub( /^[[:blank:]]*/, "", cmp_noun) ;
        gsub( /^[0-9]*[[:blank:]]/, "", cmp_noun) ;
        #データがない場合は読み飛ばし
        if ( cmp_noun == "" ) { next; }
        #最大長に達した場合は読み飛ばし
        cmp_nounlength = length(cmp_noun) ;
        if ( cmp_nounlength > MAX_CMP_SIZE ){ next ; }
        NounListNum = split(cmp_noun, NounList, " ");
        #重要語のトークン数を取得する
        #大学 野球 だと2
        #三振  だと 1
        #同じトークン数の要素にセパレータ区切りでアペンドしていく
        if (length(LengthArr[NounListNum]) > 1){
           LengthArr[NounListNum]=LengthArr[NounListNum] SUBSEP cmp_noun;
        }else{
           LengthArr[NounListNum]=cmp_noun;         
        }
        #LengthArr（セパレータはSUBSEPなので一見つながってる）
        #[1]=スライダーツーシーム三振二塁打優勝出場力投勝率変化球安打完封川和慶大打線斎藤早大
        #[2]=リーグ 戦勝ち 点早稲田 実最終 週適時 打
        #[3]=エース 加藤 幹明治 神宮 大会
        #[4]=千葉 経 大 付大学 野球 秋季 リーグ
     } END {
     for ( key in LengthArr ) {
        #awkLengthList にprint 
        #1 スライダーツーシーム三振二塁打優勝出場力投勝率変化球安打完封川和慶大打線斎藤早大
        #2 リーグ 戦勝ち 点早稲田 実最終 週適時 打
        #3 エース 加藤 幹明治 神宮 大会
        #4 千葉 経 大 付大学 野球 秋季 リーグ
         print key " " LengthArr[key];
     }
   } '`
   #awkTermExtractListの処理：
   echo -en "$comNounList" > $CmpNounListFile; #変数のまま処理できればベストだが。。。
   awkTermExtractList=$(echo -e $awkLengthList | $awk '
     BEGIN {
        #重要語リストでハッシュを作る
        #grep用、参照用、出力用の３つのハッシュを作る
        #[早大]=1
        #[大学 野球 秋季]=2
        #[明治 神宮]=1
        #term_hash:grep用
        #自分のトークン数がより多くの重要語をgrepしていくので
        #処理中のトークン数以下の重要語をgrep対象からはずしていく
        #srcterm_hash:参照用
        #TF処理前の頻度情報を保持
        #dstterm_hash:出力用
        #TF処理をして加算した頻度情報をもたせる
        while ( getline termex < "'$CmpNounListFile'" > 0 ) {
            match( termex, /^.*([\.0-9]+)[[:blank:]](.*)$/, ex);
            #ex[1] 頻度 ex[2] 重要語
            #[重要語]=頻度 の形でハッシュを作る
            term_hash[ex[2]] += ex[1];
            srcterm_hash[ex[2]] += ex[1];#参照する元のハッシュ
            dstterm_hash[ex[2]] += ex[1];#出力結果用のハッシュ（加算していく）
        }
        close( "'$CmpNounListFile'");
     } {
       #トークン数ごとに１ループ
       #より多いトークン数の重要語に含まれるか見る
       #含まれたらトークン数の多い重要語の頻度を加算する
       #awkLengthList
       #1 スライダーツーシーム三振二塁打優勝出場力投勝率変化球安打完封川和慶大打線斎藤早大
       #2 リーグ 戦勝ち 点早稲田 実最終 週適時 打
       #頻度を取り出す ex:1
       tokenCnt=$1 ;
       #頻度を除いて同じトークン数の重要語のグループを取り出す。 ex:リーグ 戦勝ち 点早稲田 実最終 週適時 打
       tokenList=$0 ;
       gsub( /^[[:blank:]]*/, "", tokenList) ;
       gsub( /^[0-9]*[[:blank:]]/, "",tokenList) ;
       #よりトークン数が大きい重要語と比較する
       #重要語がセパレータ SUBSEPで分割して配列に格納する
       #tokenArr
       #[1]=リーグ 戦
       #[2]=勝ち 点
       #[3]=早稲田 実
       #[4]=最終 週
       #[5]=適時 打
       n=split(tokenList,tokenArr,SUBSEP);
       #awkLengthListの重要語１個ずつループする
       for (i=1; i<=n; i++){
          #term_hashの重要語リストごとにgrepする
          #tokenArr[i]=大学 野球
          #word=大学 野球 秋季 リーグ
           regexp=tokenArr[i];
           for ( word in term_hash){
               #wordのトークン数が現在処理しているものより少ない場合は比較対象から
               #はずす
               tn=split(word,nounArr," ");
               if(tokenCnt >= tn){
                   delete term_hash[word];
                   continue;
               }
               #wordをtokenArr[i]でgrepする
               if (index(word, regexp) > 0 ){
               #wordにtokenArrが含まれたらwordが持っている頻度を加算する  
                  dstterm_hash[tokenArr[i]]+=srcterm_hash[word];
               }
           }
       }
     } END {
       for ( key in dstterm_hash ) {
           print dstterm_hash[key] " " key;
       }
     } ') ;
    #TF単独の場合
    if [ "$LR" -eq 0 ];then
        modify_noun_list; 
    fi	  
}
#
#<>calc_imp_by_HASH_Freq
# <NOLRFRQ>（連接情報を使わずに複合名詞（専門用語）の頻度で重み付け）
# 重要語の頻度をそのままスコアにする
#
# 入力: $comNounList ( 変数 )
# 入力: $MAX_CMP_SIZE ( 変数 )
# 出力: $awkTermExtractList ( 変数 )
#
function calc_imp_by_HASH_Freq(){
  #comNounListからサイズの長いものだけ省いてそのまま出力するだけ
  #comNounList
  #2 リーグ
  #1 大学 野球
  #1 完封
  #1 秋季 リーグ
  #1 秋季 リーグ 早大
  #1 連覇
  awkTermExtractList=$(echo "$comNounList" | $awk '
    BEGIN {
      MAX_CMP_SIZE=int("'$MAX_CMP_SIZE'") ;
    } {
      #ex:5 大学 野球 秋季 リーグ frqc=5  cmp_noun=大学 野球 秋季 リーグ
      #頻度を取り出す ex:1
      freqc=$1 ;
      #頻度を除いて重要語だけ取り出す。 ex:大学 野球 秋季 リーグ
      #TODO 最短マッチになっているか確認
      cmp_noun=$0 ;
      gsub( /^[[:blank:]]*/, "", cmp_noun) ;
      gsub( /^[0-9]*[[:blank:]]/, "", cmp_noun) ;
      #データがない場合は読み飛ばし
      if ( cmp_noun == "" ) { next; }
      #最大長に達した場合は読み飛ばし
      cmp_nounlength = length(cmp_noun) ;
      if ( cmp_nounlength > MAX_CMP_SIZE ){ next ; }
      #重要語をNounArrハッシュに格納する
      NounArr[cmp_noun]=freqc;
      #NounArr
      #[早大]=1
      #[大学 野球 秋季]=2
      #[明治 神宮]=1
   } END {
     for ( key in NounArr ) {
        #awkTermExtractList にprint 
        #1 早大
        #2 大学 野球 秋季
        #1 明治 神宮
        print NounArr[key] " " key;
     }
   } '| LANG=C sort -s -k1 -nr) ;
  #重要度順にソートする。
  #modify_noun_list;
}
#
#<>calc_imp_by_HASH
# 文中の語のみから重要度を計算し、重要度でソートした重要語リストを返す
#
# 入力１: $comNounList ( 変数 )
# 入力２: $MAX_CMP_SIZE ( 変数 ) :default 1024; 半角空白区切りの単名詞リストの最大長 
# 入力３: $LR ( 変数 )
# 入力４: $average_rate ( 変数 )# def: 1 重要度計算での連接情報と文中の用語頻度のバランス
# 入力５: $frq ( 変数 )
# 出力: $awkTermExtractList ( 変数 )
#
function calc_imp_by_HASH(){
  imp=1;        # 専門用語全体の重要度
  count=0;      # ループカウンター（専門用語中の単名詞数をカウント） 
  awkTermExtractList=$(echo "$comNounList" | $awk '
     BEGIN {
       #IgnoreWordsFile="'$IgnoreWordsFile'";
       IgnoreWordsStr="test" ; #配列初期化
       IgnoreWordsNum = split(IgnoreWordsStr, IgnoreWords, " ");
       MAX_CMP_SIZE=int("'$MAX_CMP_SIZE'") ; #def: 1024
       LR="'$LR'" ;   # def:1
       frq="'$frq'";  # def: 1
       average_rate="'$average_rate'"; #def: 1
       count=0 ; 
       wc = 1 ;
       imp = 1
       OFMT="%.6f" ;
     } {
       CmpNounList[wc++] = $0 ;
       freqc=$1 ;
       cmp_noun=$0 ;
       gsub( /^[[:blank:]]*/, "", cmp_noun) ;
       gsub( /^[0-9]*[[:blank:]]/, "", cmp_noun) ;
       if ( cmp_noun == "" ) { next; }
       cmp_nounlength = length(cmp_noun) ;
       if ( cmp_nounlength > MAX_CMP_SIZE ){ next ; } 
       NounListNum = split(cmp_noun, NounList, " ");
       #20151029
       for ( i = 1; i <= NounListNum; i++){
          if ( NounList[i] in IgnoreWords ){
            delete NounList[i] ;
          }
       } 
       #for ( i = 1; i <= NounListNum; i++){
       #  for ( j = 1; j <= IgnoreWordsNum; j++){
       #     if( NounList[i] == IgnoreWords[j] ) { 
       #         delete NounList[i] ;
       #     }
       #  }
       #}
       nounlength = length(NounList) ;
       if( nounlength < 2 ){ next ; } 
       for ( i = 1; i < nounlength; i++){
          noun_0=NounList[i] ;
          noun_1=NounList[i+1] ;
          comb_key=NounList[i]" "NounList[i+1] ;
          if ( stat_pre[noun_0] == "" ){ stat_pre[noun_0] = 0; }
          if ( stat_post[noun_1] == "" ){ stat_post[noun_1] = 0; }
          if ( LR == 1 ){  
            stat_pre[noun_0]=stat_pre[noun_0] + $freqc ;
            stat_post[noun_1]=stat_post[noun_1] + $freqc ;
          } else if ( LR == 2 && first_conb ) {
            stat_pre[noun_0]=stat_pre[noun_0] + 1 ;
            stat_post[noun_1]=stat_post[noun_1] + 1 ;
          } 
       } 
    }END{
       for ( end_i =1; end_i<wc; end_i++){
          split(CmpNounList[end_i],CmpNoun) ;
          freqc=CmpNoun[1] ;
          cmp_noun=CmpNounList[end_i] ;
          gsub( /^[[:blank:]]*/, "", cmp_noun) ;
          gsub( /^[0-9]*[[:blank:]]/, "", cmp_noun) ;
          if ( cmp_noun == "" ) { continue; }
          cmp_nounlength = length(cmp_noun) ;
          if ( cmp_nounlength > MAX_CMP_SIZE ){ continue ; }
          NounListNum = split(cmp_noun, NounList, " ");
          for ( i = 1; i <= NounListNum; i++){
              #20151029
              if ( NounList[i] in IgnoreWords ){
                delete NounList[i] ;
              }
           #  for ( j = 1; j <= IgnoreWordsNum; j++){
           #     if( NounList[i] == IgnoreWords[j] ) { 
           #        delete NounList[i] ;
           #     }
           #  }
             word = NounList[i] ;
             pre = stat_pre[word] ;
             post = stat_post[word] ;
             imp = imp * (pre + 1) * (post + 1);
             count++;
          } 
          if ( frq != 0 ){
             imp = imp ^ (1 / (2 * average_rate * count));
             imp = imp * freqc;
          } else {
             imp = imp ^ (2 / (2 * average_rate * count));
          }
          print imp " " cmp_noun ;
          TermExtractArr[end_i] = imp " " cmp_noun ;
          count = 0 ; 
          imp = 1; 
       } 
    } '| LANG=C sort -s -k1 -nr) ;
  #awkTermExtractList=`echo "$awkTermExtractList"| LANG=C sort -s -k1 -nr`; 
  #modify_noun_list;  #重要度順にソートする。
}
#
# Awk/bash共通 # 重要度計算
# 入力: comNounList ( 変数 ) # 入力: MAX_CMP_SIZE ( 変数 ) # 出力: awkTermExtractList ( 変数 )
function termExtract.calcImp(){
  get_word_done=1;
    if [ $LR -eq 0 ];then
      if [ $frq -eq 1 ];then
        calc_imp_by_HASH_Freq;
        awkTermExtractList_NOLRFRQ="$awkTermExtractList" ;
      elif [ $frq -eq 2 ];then
        calc_imp_by_HASH_TF;
        awkTermExtractList_NOLRTF="$awkTermExtractList" ;
      fi
    elif [ $LR -eq 3 ];then
      calc_imp_by_HASH_PP;
      awkTermExtractList_LRPP="$awkTermExtractList" ;
    #学習機能（連接統計DB）を使ってのLR重要度計算
    elif [ "$stat_mode" = "1" ];then
      calc_imp_by_DB;
    elif [ $LR -eq 1 -o $LR -eq 2 ]; then
      calc_imp_by_HASH;  #LR=1; frq=1;   #default
      awkTermExtractList_LRTOTAL="$awkTermExtractList" ;
      awkTermExtractList_LRUNIQ="$awkTermExtractList" ;
    else 
      :
    fi	  
}
