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
##perlの場合の処理
#comnounlist
#高校 野球 1
#早大 3
#秋季 野球 大会 2
#文書総数 12
#
## 専門用語ごとにループ
#    foreach my $cmp_noun (keys %{$n_cont}) {
#
##cmp_noun  秋季 野球 大会
#
## 複合語の場合、連接語の情報をハッシュに入れる
##単名詞ごとにまわる。「秋季 野球 大会」の場合、「秋季」「野球」の２回まわる
##１つ後ろの単語とくっつけて連接語として連接情報を変数に格納する
##「秋季 野球」「野球 大会」が連接語
##「秋季 野球」
#stat{秋季}[0]=+2
#stat{野球}[1]=+2
#pre{野球}{秋季}=+1
#post{秋季}{野球}=+1
##「野球 大会」
#stat{野球}[0]=+2
#stat{大会}[1]=+2
#pre{大会}{野球}=+1
#post{野球}{大会}=+1
#
#
#（stat pre post は１文書内で共通で使用する）
#
#  #現在登録されている全ての単名詞分回す
#  #「高校」「野球」「早大」「秋季」「野球」「大会」
#  
#  noun1のループが野球に来た時
#  （野球は「秋季 野球 大会」だけでなく「高校 野球」でも登場
#  「高校 野球」
#stat{高校}[0]=1
#stat{野球}[1]=1
#pre{野球}{高校}=1
#post{高校}{野球}=1
#しているので　野球　の　連接情報の状態は以下の通り
#stat{野球}[0]=2
#stat{野球}[1]=3
#pre{野球}{秋季}=1
#pre{野球}{高校}=1
#post{野球}{大会}=1
#）
#
#単名詞のエントロピーを求める（後ろに連接するケース）
#stat{野球}[0] は存在する
#post{野球} でループする
#post{野球}{大会}
# work = 1(post{野球}{大会})  / (2(stat{野球}[0]) +1)  = 1/3
# h = 0 -  1/3 x log(1/3) =0.366204
# 
## 単名詞のエントロピーを求める（前に連接するケース）
#stat{野球}[1]は存在する
#pre{野球}でループする
#pre{野球}{秋季}=1
#  work = 1(pre{野球}{秋季}) /(3(stat{野球}[1]+1) = 1/4
#  h=0.366204 -  1/4 x log(1/4) =0.712778
#
#pre{野球}{高校}=1
#   word =1(pre{野球}{高校})/(3(stat{野球}[1]+1)=1/4
#   h=0.712778 -  1/4 x log(1/4) =1.05935
# 
#単名詞ごとのエントロピーを格納する
# stat_PP{野球}=1.05935
#
##重要度を計算する
##専門用語ごとに回す
#高校 野球 1
#早大 3
#秋季 野球 大会 2
#文書総数 12
#
##単名詞ごとにまわる。「秋季 野球 大会」の場合、「秋季」「野球」「大会」の３回まわる
# imp 0に　単名詞ごとのエントロピーを追加する
# imp + = 「秋季」のエントロピー +  「野球」のエントロピー +　「大会」のエントロピー
# 
# imp = imp /(2 x averagerate x 名詞とトークン数（「秋季 野球 大会」の場合 3)
# imp += log(2(秋季 野球 大会の出現頻度) +1 )
# imp = imp/log(2)
#
function get_pre_post_pp2(){
  awkTermExtractList=`echo "$NcontList" | $awk '
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
#専門用語ごとにループ
#高校 野球 1
#早大 3
#秋季 野球 大会 2
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
#単名詞ごとにまわる。「秋季 野球 大会」の場合、「秋季」「野球」の２回まわる
#１つ後ろの単語とくっつけて連接語として連接情報を変数に格納する
#「秋季 野球」「野球 大会」が連接語

      for ( i = 1; i < nounlength; i++){
#
        #print "NounList[" i "]= " NounList[i] ;
        noun_0=NounList[i] ; #noun_0「大学」
        noun_1=NounList[i+1] ; #noun_1「野球」
        comb_key=NounList[i]" "NounList[i+1] ; #comb_key「大学 野球」
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
  #単語（複合語）の頻度一覧を取得する
  #頻度をFrequency か TF のいずれでとるかを選択
  #Frequency だと comnounlist そのまま
  #TF なら　comnounlist をベースにして 包含関係にある名詞については頻度を加算。
  if [ "$frq" -eq 2 ];then
     calc_imp_by_HASH_TF;  
     NcontList="$awkTermExtractList" ;
  else
     NcontList="$comNounList";
  fi	  
  awkTermExtractList="";  
  #NounList
  #高校 野球 1
  #早大 3
  #秋季 野球 大会 2
  #単語（複合語）ごとに回す 
  #「高校 野球」「早大」「秋季 野球 大会」の単位でまわる
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
    #複合語を単名詞に分解してループして重要度を算出する
    #「秋季 野球 大会」だったら「秋季」「野球」「大会」の順で回る
    #単名詞ごとに回す
    for noun in "${cmp_noun_array[@]}";do
      if cat "$IgnoreWordsFile"|grep "^$noun$">/dev/null;then
        continue;
      fi
      if echo "$noun"|grep "^[0-9\.\,]*$" >/dev/null;then
        continue;
      fi
      #stat_DB から 連接情報を取り出す。
      #  uniq_pre total_pre uniq_post total_post
      #  秋季 0 0 1 2
      #  野球 1 2 1 2
      #  大会 1 2 0 0
      stat_db_noun=`cat "$stat_db"|grep "^$noun,"`;
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
      #連接語の延数から重要度を出す
      #秋季 1(imp) x ( 0(total_pre) + 1) x (2(total_post)+1)=3
      #(imp 秋季は連接語の最初なので1からスタートする）
      #野球 3(imp) x(2(total_pre)+1)x(2(total_post)+1)=27
      #(imp 秋季で計算した結果3を引き継ぐ)
      #大会 27(imp)x(2(total_pre)+1)x(0(total_post)+1)=81

      ## 連接語の異なり数をとる場合
      elif [ "$LR" = "2" ];then
        imp=$(($imp*$(($uniq_pre + 1))*$(($uniq_post + 1)))); 
      #連接語の異なり数から重要度を出す
      #秋季　1(imp)x(0(uniq_pre)+1)x(1(uniq_post)+1)=2
      #野球 2(imp)x(1(uniq_pre)+1)x(1(uniq_post)+1)=8
      #大会 8(imp)x(1(uniq_pre)+1)x(0(uniq_post)+1)=16
      fi
      count=$(($count + 1));
    done
    if [ "$count" -eq 0 ];then
      count=1;
    fi
    # 相乗平均で重要度を出す
    # 重要度 ^ (1 / (2 x average_rate x count(連接語のトークン数))
    #frq =0 以外の場合、最後に 複合語のfrq をかける 「秋季 野球 大会」が今回の文書で例えば2回し用されていれば 2かける。
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
  # FrequencyとTFはいずれも単語の出現頻度。
  # 違う点は、複合名詞が包含関係にある場合、包含される複合名詞のスコアを加算する。
  # 例えば、「高校 野球 大会」は「全国 高校 野球 大会」に包含されるので、「高校 野球 大会」の頻度に「全国 高校 野球 大会」の頻度を加算する
  if [ "$frq" -eq 2 ];then
     calc_imp_by_HASH_TF;  
     NcontList="$awkTermExtractList" ;
  else
     NcontList="$comNounList";
  fi	  
  #NcontList
  #高校 野球 1
  #早大 3
  #秋季 野球 大会 2
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
#複合単語の出現頻度がそのままスコアになる点はFreqと同じ。
# 違う点は、複合名詞が包含関係にある場合、包含される複合名詞のスコアを加算する。
# 例えば、「高校 野球 大会」は「全国 高校 野球 大会」に包含されるので、「高校 野球 大会」の頻度に「全国 高校 野球 大会」の頻度を加算する
#下の例だと、「高校 野球 大会」自体の出現頻度は3回だが、「全国 高校 野球 大会」という単語があり「高校 野球 大会」を包含する。「全国 高校 野球 大会」の出現頻度は2回なので、「高校 野球 大会」のスコアは2回分加算され 5になる
function calc_imp_by_HASH_TF(){
    #
    #cmpNounListFile
    #2 リーグ
    #1 大学 野球
    #1 完封
    #3 高校 野球 大会
    #2 全国 高校 野球 大会
    #1 連覇
    #
    #awkLengthListの処理： 重要語をトークン数ごとに並べなおす
    #awkLengthList
    #東京,五輪,優勝（１トークン）
    #東京 五輪,リーグ 戦,適時 打（２トークン）
    #東京 五輪 オリンピック（３トークン）
    #トークン数ごとに分けているが、ロジック的には名詞の包含関係をgrepして確認するためだけ。小さいトークン数から回していって自分より大きいトークン数の名詞と包含関係があるか順番に見ていっているだけ。
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
   awkTermExtractList=$(echo -e "$awkLengthList" | $awk '
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
  #出現頻度|名詞（複合名詞の場合、単名詞ごとにスペース区切りにしている）
  #2 早大
  #2 大学 野球 秋季
  #1 明治 神宮
  #シンプルに単語の出現頻度をそのままスコアリングに使用する。
  #comNounListの値をそのままスコアリングしているだけ。
  #複合名詞は単名詞ごとにスペース区切りになっているが、このロジックではそのまま使うだけなので意味はない。
  awkTermExtractList=$(echo "$comNounList" | $awk '
    BEGIN {
      MAX_CMP_SIZE=int("'$MAX_CMP_SIZE'") ;
    } {
      #ex:5 大学 野球 秋季  frqc=2  cmp_noun=大学 野球 秋季
      #頻度を取り出す ex:1
      freqc=$1 ;
      #頻度を除いて重要語だけ取り出す。 ex:大学 野球 秋季
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
#複合語ごとにループ
#comNounList
#高校 野球 1
#早大 3
#秋季 野球 大会 2
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
#名詞のトークンが２個以上なければ連接情報がないのでスキップする
       if( nounlength < 2 ){ next ; } 
#複合語を単名詞に分解してループして重要度を算出する
#「秋季 野球 大会」だったら「秋季」「野球」の順で回る
#１個後ろの単語とくっつけて連接語とし連接情報を見る
#「秋季 野球」「野球 大会」が連接語
       for ( i = 1; i < nounlength; i++){
          noun_0=NounList[i] ;
#noun_0 1ループ目「秋季」2ループ目「野球」
          noun_1=NounList[i+1] ;
#noun_1 1ループ目「野球」2ループ目「大会」
          comb_key=NounList[i]" "NounList[i+1] ;
#comb_key 1ループ目「秋季 野球」2ループ目「野球 大会」
          if ( stat_pre[noun_0] == "" ){ stat_pre[noun_0] = 0; }
          if ( stat_post[noun_1] == "" ){ stat_post[noun_1] = 0; }
#LR=1の場合
#連接語の延数から重要度を出す
#DBでいう total_pre total_post に該当する
          if ( LR == 1 ){  
            stat_pre[noun_0]=stat_pre[noun_0] + $freqc ;
            stat_post[noun_1]=stat_post[noun_1] + $freqc ;
#「秋季 野球」
# stat{秋季}[0] +2（秋季 野球 大会の出現頻度)
# stat{野球}[1] +2（秋季 野球 大会の出現頻度)
# 「野球 大会」
# stat{野球}[0] +2 （秋季 野球 大会の出現頻度)
# stat{大会}[1] +2 （秋季 野球 大会の出現頻度)
#
# stat{秋季}[2,0]
# stat{野球}[2,2]
# stat{大会}[0,2]

#LR=2の場合
#連接語の異なり数から重要度を出す
#DBでいう uniq_pre uniq_postに該当する
#first_comb が 1　の場合に +1 する
          } else if ( LR == 2 && first_conb ) {
            stat_pre[noun_0]=stat_pre[noun_0] + 1 ;
            stat_post[noun_1]=stat_post[noun_1] + 1 ;
#「秋季 野球」
# stat{秋季}[0] +0 or 1（「秋季 野球」が初登場の場合 +1)
# stat{野球}[1] +0 or 1（「秋季 野球」が初登場の場合 +1)
# 「野球 大会」
# stat{野球}[0] +0 or 1 （「野球 大会」が初登場の場合 +1)
# stat{大会}[1] +0 or 1 （「野球 大会」が初登場の場合 +1)
# stat{秋季}[1,0]
# stat{野球}[1,1]
# stat{大会}[0,1]
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
#重要度を出す
#pre と post の用語の使い方がDB と逆な気がスル
#逆でも変数名が違うぐらいの違いしかないので結果は同じ

#LR=1の場合
#秋季 1(imp) x ( 2(pre) + 1) x (0(post)+1)=3
#(imp 秋季は連接語の最初なので1からスタートする）
#野球 3(imp) x(2(pre)+1)x(2(post)+1)=27
#(imp 秋季で計算した結果3を引き継ぐ)
#大会 27(imp)x(0(pre)+1)x(2(total_post)+1)=81

#LR=2の場合
#秋季　1(imp)x(1(pre)+1)x(0(post)+1)=2
#野球 2(imp)x(1(pre)+1)x(1(post)+1)=8
#大会 8(imp)x(0(pre)+1)x(1(post)+1)=16
             word = NounList[i] ;
             pre = stat_pre[word] ;
             post = stat_post[word] ;
             imp = imp * (pre + 1) * (post + 1);
             count++;
          } 
#相乗平均で重要度を出す
#　重要度 ^ (1 / (2 x average_rate x count(連接語のトークン数))
#  frq =0 以外の場合、最後に 複合語のfrq をかける 「秋季 野球 大会」の場合は2かける 
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
#
#LR(連接情報)の設定  
#0 → LRなし（隣接情報を使わない）
#1 → 延べ数を取る
#2 → 異なり数を取る
#3 → パープレキシティを取る <>
#連接情報とは、複合名詞を単名詞に分割し、単名詞同士の前後関係を見るもの。
#例えば、複合名詞「高校野球大会」は「高校」「野球」「大会」の単名詞に分割できる。この場合の連接関係は「高校」「野球」と「野球」「大会」。

# FRQ
# 無効 0
# FRQ  1
# TF   2 <> 
# FRQは名詞の出現頻度。
# FRQは、シンプルに複合名詞の出現頻度をスコアリングする。
# TFは、複合名詞の出現頻度をスコアリングする点ではFRQと同じ。
# 違う点は、複合名詞が包含関係にある場合、包含される複合名詞のスコアを加算する。
# 例えば、「高校 野球 大会」は「全国 高校 野球 大会」に包含されるので、「高校 野球 大会」の頻度に「全国 高校 野球 大会」の頻度を加算する
#
# STAT
#0-> 使用しない 
#1-> 使用する
#
#STATモードは、他の文書の連接情報を蓄積しておきスコアリングに利用する。
function termExtract.calcImp(){
  get_word_done=1;
#LR=0 は連接情報を見ない。複合単語の出現頻度がそのままスコアになる。
    if [ $LR -eq 0 ];then
      if [ $frq -eq 1 ];then
#calc_imp_by_HASH_Freq
#複合単語の出現頻度がそのままスコアになる。
        calc_imp_by_HASH_Freq;
        awkTermExtractList_NOLRFRQ="$awkTermExtractList" ;
      elif [ $frq -eq 2 ];then
#calc_imp_by_HASH_TF
#複合単語の出現頻度がそのままスコアになる点はFreqと同じ。
# 違う点は、複合名詞が包含関係にある場合、包含される複合名詞のスコアを加算する。
# 例えば、「高校 野球 大会」は「全国 高校 野球 大会」に包含されるので、「高校 野球 大会」の頻度に「全国 高校 野球 大会」の頻度を加算する
        calc_imp_by_HASH_TF;
        awkTermExtractList_NOLRTF="$awkTermExtractList" ;
      fi
#LR=3は連接情報を見る。
#3はパプレキシティを見る。
    elif [ $LR -eq 3 ];then
      calc_imp_by_HASH_PP;
      awkTermExtractList_LRPP="$awkTermExtractList" ;
#学習機能（連接統計DB）を使ってのLR重要度計算
#LR=1 連接語の延数から重要度を出す
#LR=2 連接語の異なり数から重要度を出す
#frq=0 名詞の出現頻度をスコアリングに使用しない。 
#frq=1 Frequencyを利用する。
#frq=2 TFを利用する。
    elif [ "$stat_mode" = "1" ];then
      calc_imp_by_DB;
#文章中の連接情報を使ってのLR重要度計算
#ロジック的にはcalc_imp_by_DBと同じ。使用する連接情報が文章中のものに限定される点が異なる。
#LR=1 連接語の延数から重要度を出す
#LR=2 連接語の異なり数から重要度を出す
#frq=0 名詞の出現頻度をスコアリングに使用しない。 
#frq=1 Frequencyを利用する。
#frq=2 TFを利用する。
    elif [ $LR -eq 1 -o $LR -eq 2 ]; then
      calc_imp_by_HASH;  #LR=1; frq=1;   #default
      awkTermExtractList_LRTOTAL="$awkTermExtractList" ;
      awkTermExtractList_LRUNIQ="$awkTermExtractList" ;
    else 
      :
    fi	  
}
