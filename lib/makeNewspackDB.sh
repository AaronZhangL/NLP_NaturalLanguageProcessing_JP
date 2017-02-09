#
#########################################################################
#
# 2002年からのニュースパック過去記事約255万件の処理
#
#	タグ付け：ID/newsItemID/見出し/サブ見出し/本文/カテゴリ/日付 
#	分かち書き：本文からmecab -Owakati を行った結果を格納
#	記事ごとに分類されたカテゴリごとにファイル出力
#
# NEWSPACKDB : 全量ファイル
# W_NEWSPACKDB : 全量のわかちがきファイル
# カテゴリ名 : カテゴリごとに全量ファイル
# W_カテゴリ名 : カテゴリごとのわかちがきファイル
#
#########################################################################
function NPstep1(){
:> NEWSPACK_DB.step1 ;
cat csvlist | while read line; do
		cat "$line" >> NEWSPACK_DB.step1 ;	
done
}
#
function NPstep2(){
:> NEWSPACK_DB.step2 ;
cat NEWSPACK_DB.step1 | while read line; do
	echo "$line" | sed -e "s|&quot;||g" -e "s|&lt;[^;]*&gt;||g" >> NEWSPACK_DB.step2 ;
done
}
#
function NPstep3(){
	:> NEWSPACK_DB.step3 ;
	cat NEWSPACK_DB.step2 | while read line; do
		LINE=$( echo "$line" | sed -e  "s/\"\(.*\),\(.*\)\"/\"\1#\2\"/g" -e "s/,\"/,/g" -e "s/\",/,/g") ;
		  ID=$( echo "$LINE" | awk -F, '{ print $1; }' );
		 NID=$( echo "$LINE" | awk -F, '{ print $2; }' );
		 TTL=$( echo "$LINE" | awk -F, '{ print $3; }' );
		STTL=$( echo "$LINE" | awk -F, '{ print $4; }' );
		BODY=$( echo "$LINE" | awk -F, '{ print $5; }' );
		CATE=$( echo "$LINE" | awk -F, '{ print $6; } ' );	
		DATE=$( echo "$LINE" | awk -F, '{ print $7; } ' );	
		echo "<ID>$ID</ID><NID>$NID</NID><TTL>$TTL</TTL><STTL>$STTL</STTL><BODY>$BODY</BODY><CATE>$CATE</CATE><DATE>$DATE</DATE>" >> NEWSPACK_DB.step3 ;	
	done
}
#
function NPstep4(){
	cat NEWSPACK_DB.step3 | \
			sed -e "s|Main-|主要-|g"  \
					-e "s|National-|社会-|g"  \
					-e "s|Politics-|政治-|g"  \
					-e "s|Economics-|経済-|g"  \
					-e "s|Worldcup-|国際大会-|g"  \
					-e "s|World-|国際-|g"  \
					-e "s|Weather_Warning-|気象警報-|g"  \
					-e "s|Weather-|気象-|g"  \
					-e "s|Lifestyle/Human_Interest-|暮らし・話題-|g"  \
					-e "s|Culture/Entertainment-|文化・芸能-|g"  \
					-e "s|Science/Environment/Health-|科学・環境・医療・健康-|g"  \
					-e "s|Science/Environment-|科学・環境-|g"  \
					-e "s|Health-|医療・健康-|g"  \
					-e "s|Events-|予定-|g"  \
					-e "s|Obituaries-|おくやみ-|g"  \
					-e "s|Detail-|詳報-|g"  \
					-e "s|Features-|特集-|g"  \
					-e "s|Feature-|特集-|g"  \
					-e "s|Entertainment_Mobile-|エンタメモバイル-|g"  \
					-e "s|Entertainment_Sports-|エンタメスポーツ-|g"  \
					-e "s|Sports-|スポーツ-|g"  \
					-e "s|Entertainment_Culture-|エンタメカルチャー-|g"  \
					-e "s|Entertainment_Trends-|エンタメトレンド-|g"  \
					-e "s|-trends|-トレンド|g"  \
					-e "s|-travel|-おでかけ|g"  \
					-e "s|-pet|-ペット|g"  \
					-e "s|-beauty|-美容|g"  \
					-e "s|-gourmet|-グルメ|g"  \
					-e "s|Best_Shot_Photo-|フォトニュース-|g"  \
					-e "s|-best_shot_photo|-フォトニュース|g"  \
					-e "s|-main|-主要|g"  \
					-e "s|-national|-社会|g"  \
					-e "s|-politics|-政治|g"  \
					-e "s|-economics|-経済|g"  \
					-e "s|-securities|-株|g"  \
					-e "s|-exchange|-為替|g"  \
					-e "s|-new_products|-新商品|g"  \
					-e "s|-sports|-スポーツ|g"  \
					-e "s|-nbp_formatted|-プロ野球Ｆ|g"  \
					-e "s|-nbp|-プロ野球|g"  \
					-e "s|-mlb|-大リーグ|g"  \
					-e "s|-soccer_formatted|-サッカーＦ|g"  \
					-e "s|-soccer|-サッカー|g"  \
					-e "s|-sumo_formatted|-相撲Ｆ|g"  \
					-e "s|-sumo|-相撲|g"  \
					-e "s|-highschool_baseball_formatted|-高校野球Ｆ|g"  \
					-e "s|-highschool_baseball|-高校野球|g"  \
					-e "s|-worldgames|-国際大会|g"  \
					-e "s|-worldcup|-国際大会|g"  \
					-e "s|-world|-国際|g"  \
					-e "s|-weather_warning|-気象警報|g"  \
					-e "s|-weather|-気象情報|g"  \
					-e "s|-lifestyle/human_interest|-暮らし・話題|g"  \
					-e "s|-culture/entertainment|-文化・芸能|g"  \
					-e "s|-events|-予定|g"  \
					-e "s|-science/environment|-科学・環境|g"  \
					-e "s|-health|-医療・健康|g"  \
					-e "s|-obituaries|-おくやみ|g"  \
					-e "s|-detail|-詳報|g"  \
					-e "s|-features|-特集|g"  \
					-e "s|-feature|-特集|g"  \
					-e "s|-fights_topics|-格闘技の話題|g"  \
					-e "s|-this_week_fights|-今週の格闘技|g"  \
					-e "s|-fights_records|-格闘技の記録|g"  \
					-e "s|-formula_one|-Ｆ１|g"  \
					-e "s|-women_golf|-女子ゴルフ|g"  \
					-e "s|-golf|-ゴルフ|g"  \
					-e "s|-books|-新刊レビュー|g"  \
					-e "s|-cinema|-おすすめシネマ|g"  \
					-e "s|-music|-音楽玉手箱|g"  \
					-e "s|It-|情報科学-|g"  \
					-e "s|it-|情報科学-|g"  \
					-e "s|Reserved-||g"  \
					-e "s|-reserved||g"  \
					-e "s|reserved||g"  \
					-e "s|Reserved-reserved||g"  \
					-e "s|Earthquake/Tsunami/Volcano-|気象庁発表|g"  \
					-e "s|-earthquake|震源情報|g"  \
					-e "s|-tsunami|津波情報|g"  \
					-e "s|-front_line|-エンタメ・フロントライン|g" > NEWSPACK_DB.step4 ;
}
#
# わかちがきを追加
function NPstep5(){
	:> NEWSPACK_DB.step5 ;
  GT=2453774;
	COUNT=0;
	cat NEWSPACK_DB.step4 | while read line; do
		 TTL=$( echo "$line" | sed -e "s/^.*<TTL>//g" -e "s/<\/TTL>.*$//g" );
		STTL=$( echo "$line" | sed -e "s/^.*<STTL>//g" -e "s/<\/STTL>.*$//g" );
		BODY=$( echo "$line" | sed -e "s/^.*<BODY>//g" -e "s/<\/BODY>.*$//g" );
		WAKATI=$( echo "$TTL" "$STTL" "$BODY" | sed -e "s/　//g" | nkf -We | mecab -Owakati | nkf -wLu  ) ;
		echo "$line<WAKATI>$WAKATI</WAKATI>" >> NEWSPACK_DB.step5 ;
		echo "$((COUNT++))/$GT";
	done 	
	#mv NEWSPACK_DB.step5 NEWSPACKDB ;
}
#
# カテゴリごとにファイル出力
function NPstep6(){
  GT=2454026;
	COUNT=0;
	mkdir -p newspack ;
  /bin/rm -fr newspack/* ;
	:> W_NEWSPACKDB ;
	cat NEWSPACKDB | while read line; do
		WAKATI=$( echo "$line" | sed -e "s/^.*<WAKATI>//g" -e "s/<\/WAKATI>.*$//g" );
		echo "$WAKATI" >> newspack/W_NEWSPACKDB ;
		echo "$line" | sed -e "s/^.*<CATE>//g" -e "s/<\/CATE>.*$//g" -e "s/#/\n/g" | grep -v "^$" | while read line2; do
			OUT_CATEGORY=$( echo "$line2" | sed -e "s/-.*$//g" ) ;	
			if [ ! -f "newspack/W_$OUT_CATEGORY" ] && [ ! -z "newspack/W_$OUT_CATEGORY" ]; then
				:> "newspack/W_$OUT_CATEGORY" ;
			fi
			echo "$WAKATI" >> "newspack/W_${OUT_CATEGORY}" ;			
			#
			if [ ! -f "newspack/$OUT_CATEGORY" ] && [ ! -z "newspack/$OUT_CATEGORY" ]; then
				:> "newspack/$OUT_CATEGORY" ;
			fi
			echo "$line" >> "newspack/${OUT_CATEGORY}" ;
		done
		echo "$((COUNT++))/$GT";
	done
  /bin/cp NEWSPACKDB newspack/ ;
}
#
# NEWSPACKDBからわかちがきを除去
function NPstep7(){
  GT=2454026 ;
	COUNT=0;
	:> NEWSPACKDB.in ;
	cat NEWSPACKDB | while read line; do
		echo "$line" | sed -e "s/<WAKATI>.*<\/WAKATI>//g" >> NEWSPACKDB.in ;
		echo "$(( COUNT++)) /$GT" ;
	done 
	/bin/mv NEWSPACKDB.in NEWSPACKDB ;
}
#
function NPstep8(){
  GT=2454026 ;
	COUNT=0;
	:> NEWSPACKDB.in ;
	cat NEWSPACKDB | while read line; do
		echo "$line" | sed -e "s/<TTL>/<TITLE>/g" -e "s/<\/STTL>/<\/TITLE>/g" -e "s/<\/TTL><STTL>/  /g" >> NEWSPACKDB.in ;
		echo "$(( COUNT++)) /$GT" ;
	done
}
#
#NPstep1 ;
#NPstep2 ;
#NPstep3 ;
#NPstep4 ;
#NPstep5 ;
#NPstep6 ;
#NPstep7 ;
#NPstep8 ;
#
#exit ;
#
