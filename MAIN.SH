#!/bin/bash
#
#########################################################
# 自然言語処理解析システム
#########################################################
#
#   "Author"  suzuki.iichiro@kyodonews.jp
#   "perlMan" horiuchi.kotaro.ani
#   "pipeMan" kanazawa.hayato
#   "awkMan"  sugai.takayuki
#   "graphMan" akasaki.haruka
#
#1. 単一テキストを対象にした重要箇所抽出による要約アルゴリズムについて
#
#  要約手法１
#  連接情報を使わずに複合名詞（専門用語）の頻度で重み付けによる重要箇所抽出
#  [抽出のアルゴリズムについて]
#      重要度計算において、複合語の重みを使わず、重要度を用語の出現頻度で
#      計算する。ただし、用語が他の用語の一部として現れた場合もカウントす
#      る。  ＊Term Frequency(TF)による重要度計算
#      ＊ＴＦ処理：重要語の頻度をより詳しく見る
#        例えば、「大学 野球」の使用回数が２回だとして、
#        他に「大学 野球 秋季 リーグ」が１回 「大学 野球 リーグ」が
#        ２回使われていると、「大学 野球」は「大学 野球 秋季 リーグ」
#        「大学 野球 リーグ」の一部を構成しているので、「大学 野球」
#        の２回の他「大学 野球 秋季 リーグ」１回、 「大学 野球 リーグ」
#        ２回を足し頻度５とする  
#  要約手法２
#  連接情報を使わずに名詞の頻度で重み付けによる重要箇所抽出
#      [抽出のアルゴリズムについて]
#      重要度計算において、複合語の重みを使わず、重要度を用語の出現頻度で計算す
#      る。＊Frequencyによる重要度計算 
#
#  要約手法３
#  連接情報＋各単名詞の延べ数による重要箇所抽出
#      重要度計算において、連接語の重みを連接した単語の延べ数で計算する。例えば、
#      統計データで「大学」という語が「野球」の前に２回、「駅伝」の前に３回連接
#      したとすると。連接語の重みは次のとおり計算される。＊「大学」:５回 （「大
#      学野球」２回  ＋  「大学駅伝」３回） 
#
#  要約手法４
#  連接情報＋各単名詞の異なり数による重要箇所抽出
#
#  要約手法５
#  連接情報＋各単名詞のエントロピーのべき乗の合計による重要箇所抽出
#      [抽出のアルゴリズムについて]
#      重要度計算において、複合語の重みをパープレキシティで計算する。パープレキ
#      シティは情報理論で使われる指標で、本システムでは各単名詞に「情報理論的に
#      見ていくつの単名詞が連接可能か」を示している。これは、以下のようにして求
#      まる単名詞のエントロピーを元に、２のべき乗することで求められる。連接する
#      語のそれぞれの出現確率をP1～Pnとおくと、エントロピーの計算は次のように示
#      せる。なお対数の底は２である。
#      ＊(-1 * P1 * log(P1)) + (-1 * P2 * log(P2)) ....... + (-1 * Pn * log(Pn))
#              
#      例えば、統計データで、「大学」という語が「野球」の前に２回、「駅伝」の
#      前に３回連接（あわせると計５回連接）したとすると。単名詞のエントロピーは
#      次のとおりになる。出現確率は「大学野球」が 2/5, 「大学駅伝」が 3/5
#      である。 
#        ＊(-2/5 * log(2/5)) + (-3/5 * log(3/5))
#          「大学」13回   （「大学野球」2^2回  ＋  「大学駅伝」3^2回）
#
#  要約手法６
#  重要箇所(連接情報＋各単名詞の延べ数)＋人名・地名・組織名・係り受け関係のスコ
#  ア・係り受け数・形態素ラティスの重み付けグラフ経路探索アルゴリズムによるオン
#  トロジーを用いた自動要約
#      [抽出のアルゴリズムについて]
#      係り受けリストを組み合わせて作成できるすべての文章に対し、単語毎の重要度、
#      係り受けの重要度、人名／地名／組織の重要度を合算する。
#      これにより最も重要度の高い言葉がつながった文章が作成される。
#
#      (1)単語毎の重要度：上記重要語の抽出アルゴリズムを用いて算出
#      (2)人名／地名／組織／日付の重要度：単語毎に1を加算する
#      (3)係り受けの数：オントロジー解析の結果より算出した単語毎に借り受けられた数を算出
#      (4)係り受けの重要度：cabochaコマンドで出力されたものを用いる
#      (5)タイトル、見出しを元にした重要度：タイトル、見出しより単語毎の重要度を加算する
#      (6)文の位置情報による重要度：記事の前の方に出ている語の重要度を上げ、文の重要度を計算する
#      (7)手がかり表現の重要度：主張、結論、評価など（評価表現）の特別な語を含む文の重要度を加算する
#      (8)単語間のつながりと関係性情報の重要度：高い活性値を得た単語、句、文を重要と見なし加算する
#      (9)テキスト構造の重要度：文間の関係を解析し、重要度を加算する
#
#
#
#  自然言語処理によるテキスト自動要約 一般社団法人 共同通信社 メディアラボ 鈴木  維一郎
#
#  要旨: Webで必要な情報を見つけるという作業は悪夢である。Webで特定の情報を検索
#  していると、膨大な無関係の資料に途方に暮れ、肝心の検索している事項を見落とし
#  てしまう事がよくある。検索は不正確で、多くの場合、何千ものページへのポインタ
#  が返される。さらに求める情報を得るためには、検索された文書全体を読まなければ
#  ならない。本当に関連のあるWebページを見つける事ができたとしても、ページ内の検
#  索が難しかったり、情報が明確でなかったりする場合がある。
#
#  インターネットに情報が溢れる現在、膨大なWebから必要とする情報を効率よく探し出
#  したり、Web上に分散した情報を組み合わせ集約し、自動的に処理したりするための技
#  術が求められている。こうしたセマンティックWebの世界では、人工知能分野で研究さ
#  れてきたオントロジーの研究を取り入れている。こうした技術によりWebは巨大な知識
#  ベースとなり、様々な問題に対して推論を行い、有益な結論を導く事ができるように
#  なる。
#
#  Webは機械が理解可能な情報であり、標準によってきちんと定義され、人と情報の世界
#  においてある種の均衡状態となり、共有知識を介したコミュニケーションのための媒体
#  でなければならない。そのためには情報の把握を手助けしてくれる、情報に関する情報
#  「メタデータ」が必要である。
#
#  文書内からメタデータを効率良く抽出することで、機械が文書の構造および意味的定
#  義を理解し、行間の感情表現を特定し、文書の文脈を理解し、要旨を自動生成する事
#  が可能となる。
#
#  要旨抽出（以降機械要約）の技術は、自然言語処理(NLP Natural Language
#  Proccession)とも言われ、「言語解析」「重要箇所の特定」「言語生成」技術に区分
#  する事が出来る。
#
#    言語解析は次の四つの要素技術に細分化できる
#    １．形態素解析  テキストを品詞に分解する。（chasen/mecab)
#    ２．構文解析  単語間の構文的関係を決定し、その文の構造を決定する。(KNP/Cabocha)    
#    ３．意味解析  単語の語彙（意味）を決定する
#    ４．文脈解析  テキストの構造の決定、照応の解析、省略の補完を行う。
#
#  形態素解析技術により文中の単語は品詞に分解され、それらは一般に文法に基づき、
#  互いに関係を持ち、文にはその結果として構文的な構造が与えられるとされている。
#  たとえば英語の場合、動詞と目的語の名詞句から動詞句が構成され、主語の名詞句と
#  動詞句から文が形成されるという具合である。これら構造を得る処理が構文解析技術
#  である。
#
#  テキスト中の文は、互いに関係づけられており、テキスト全体は構造を持っていると
#  考えられる。その文間の関係を解析し、テキスト全体の構造を得る処理を文脈解析技
#  術という。照応とは、代名詞、定名詞句、「こそあど」と言われる指示詞などが文脈
#  中の別の単語と同じ対象を指示する言語対照である。一般にこの指示対象が何である
#  かは表層の情報からは明かではないため、指示対象を同定する照応解析は重要な問題
#  となる。
#
#  重要文抽出による要約
#  １．何らかの情報を本にして、各文の重要度を計算する。
#  ２．重要度が上位の文から順に、指定された要約率に達するまで文を選択する。
#  おおよそ「なんらからの情報」とは以下の六つが考えられる
#
#  （１）テキスト中の単語の重要度を利用する。(1950-ベイズ)<実装済み>
#    出現頻度(Term Frequency:tf)
#    単語が出現するテキスト数（Document furequency:df)
#    上記二つの掛け合わせ（tf* idf)など様々な単語の重み付け技法が利用できる。
#
#  （２）テキスト中のあるいは段落中での文の位置情報を利用する。(リード)＜実装済み＞
#    たとえば論文には、序論、本論、結論、新聞は、見出し、小見出しのあと、本文が
#    来る事が多い。このようなジャンルにより決まったテキストの構造を重要文抽出に
#    利用する。 
#
#  （３）テキストのタイトルなどの情報を利用する。＜実装済み＞ 
#    テキストに付与されたタイトルを持つ場合、このタイトル、見出しは、ある意味でテキ
#    スト本文の非常に簡潔な要約となっていると考えられる。そこで、タイトル、見出しに
#    現れる内容語を含む文が重要であると考え、タイトル、見出し中の単語を重要文抽出に
#    利用する手法が考えられる。
#
#  （４）テキスト中の手がかり表現を利用する。
#    テキスト中では、重要な文を直接明示する手がかり語が存在すると考えられる。論文な
#    どでは、「本研究では」「とめると」「我々は」などの表現を含む文は、主題を表すと
#    考えられる。
#
#  （５）テキスト中の文あるいは単語間のつながりの情報を利用する＜実装済み＞ 。
#    テキスト中の他の多くの文と強い関連がある文は、テキスト中で比較的中心的な役割を
#    果たしていると考える事が出来る。テキスト中の多くの文と強い関連がある文を重要な
#    文として抽出する手法が考えられる。
#    関連度は、二つの文中の意味的に関連がある単語(引きあいの多い単語)の出現頻度
#    を解析する事が多い、または類義語や同義語などの「川」と「橋」などといった意
#    味的な関連制を利用する事が多い。
#
#  （６）テキスト中の文間の関係を解析したテキスト構造を利用する。＜実装済み＞ 。
#    まず、利点として、長さに応じた要約を、得られた構造木のそれぞれのレベルで作成で
#    きる。テキスト構造に基づいて重要文を抽出しているので、単語の出現頻度などを用い
#    た手法に比べ、一貫性の高い要約が出来る。などである。
#
#  文の構造が得られたとして、どうやって重要な文を選ぶのか。文間の関係、それらは大
#  きく分類するなら、分銅しがたい媼関係、片方が片方よりも重要である関係に分ける事
#  が出来る。例えば、しかしなどが出てくる場合の「対比」、例えば等の「例示」、した
#  がってなどの「理由」、そのほかに、譲歩、正当化、証拠などの文章の意見を抽出し、
#  それら情報の値を要約文抽出の重要度に加えるなどの手法が考えられる。  
#        
#  文単位で抽出する事でテキストを短くする重要文抽出手法について説明、実装してき
#  たが、一文ごとに重要でない箇所を削り、あるいは重要な箇所を抽出し、情報をなる
#  べく減らさずに、テキストを短く表現し直す要約手法「文短縮手法」が今後の研究課
#  題である。
#  不要と思われる文字列を削除したり、表現をより簡潔な別の表現に言い換えるなど、
#  利用用途に応じた文字数、内容に置き換える技術が期待されている。
#  こうした技術発展の先には、機械が複数の文書をひとつの文書に再編成したり、文書
#  のトピックを特定し、同一のトピック群から正当と判断しうる同一テーマを持つ文書
#  を抽出し、文書内の疑問に対する理由を見つけ、応答する事さえも可能となると考え
#  る。
#  キーワードマッチングに変わるインテリジェントな検索、情報検索に変わる問い合わ
#  せ応答、オントロジーマッピングを介した部門間の文書交換や、機械による文書の自
#  動校正・校閲、再編成、さらにはSNSなどの話題や一般市民の意見をモデル化し、さま
#  ざまな問題を解決する糸口を導き出すといったこれまでと全く異なる新しい可能性の
#  実現は私たちのすぐ目の前まできている。
#  暖かくてファジーな右脳化された自分たちと、この明確に定義された左脳の世界を統
#  合しうる最良の方法を見つけなければならない。
#
#  キーワード:自然言語処理、形態素解析、重要語抽出、構文解析、意味解析、自動要約、
#  オントロジー、意見評価、感情表現抽出、カテゴリ分類、クラスタリング分類、セマ
#  ンティックWeb、自由作成要約、複数テキスト要約、セマンティクスの抽出と応用開発、
#  質問応答システム
#
#
#	目次
#	    0. セマンティックスの抽出
#            1. 単一テキストを対象にした重要箇所抽出による要約
#            2. 複数テキストを対象にした重要文抽出による要約
#            3. 単一テキスト、同一トピックの抽象化、言い換えによる要約作成
#            4. 複数テキスト、同一トピックの抽象化、言い換えによる要約作成
#            5. アルゴリズムについて
#            6. APIによる取得方法
#            7. 縦書き表示の充実
#            
#  我々は、新聞を読むとき、まず記事の見出しを見て、その記事の内容を推測し、その
#  記事を読むかどうか決めていると思われる。
#  これは、見出しが、記事の内容を簡潔に示す「要約」になっているからだと言える。
#  研究者の場合、タイトルで当たりをつけた後、論文のアブストラクトを読み、おもし
#  ろそうな論文を探す事は日常当たり前に行っているのではないだろうか。このよう
#  に、要約はわれわれの身近でずっと前から役に立っていたという事ができる。
#  近年検索エンジンが広く利用されるようになってきているが、システムが提示する検
#  索結果には、Webページの内容を短く紹介したものが併せて提示される場合もあるよう
#  である。これは、リンク先のページがユーザーの欲しいものかどうかを要約を見て判
#  断してもらおうという趣旨でつけられていると思われる．
#  ニュースの文字放送では、ニュースの原文自体ではなく、その要約と言えるような形
#  でニュースが配信されている。
#  ユーザーが大量の関連情報の中から必要な情報に効率的にアクセスするのを支援する
#  技術が求められている。さらに、アクセスした文書から必要としている内容を効率的
#  に特定するために、自動要約技術によって読み手の文書の量を制御し、短い時間で的
#  確に内容を把握する必要性が高くなっている。
#  テキスト自動要約とは、元のテキスト原文の内容をより短いテキストで簡潔にまとめ
#  る処理、あるいは、その処理の結果のテキストの事を言う。
#  テキスト情報から重要な情報のみを選択して提供し、要点の迅速把握を支援する技術
#  であり、読み手が読むテキストの量を制御できる事を目標としている。
#
#
#１．extract（抽出）とabstract（それ以外）
#===============================
#  テキスト自動要約は時に、情報抽出と対で（あるいは対比して）述べられる事があ
#  る。どちらもテキスト中の重要な情報を抜き出すという点では共通するが、情報抽出
#  は、あらかじめ決められた「枠」を埋める形で必要な情報を抜き出す。
#  情報検索結果のテキストを自動要約したものをユーザーに提示し、ユーザーは、シス
#  テムの提示した結果が適切なものであるかどうかを要約を見て判断する。同様に、テ
#  キスト分類あるいはテキストクラスタリングにより、分類、グループ化されたテキス
#  ト集合を入力として、テキスト集合の要約を作成するテキスト自動要約もあり得る。
#  質問応答はある意味で「究極の」情報アクセス技術であり、情報検索、情報抽出、テ
#  キスト自動要約など、現在研究されている他の情報アクセス技術は、質問応答技術の
#  要素技術と位置づけられないわけではない。
#
#  重要文抽出による要約
#    １．何らかの情報を元にして、各文の重要度を計算する
#    ２．重要度が上位の文から順に、指定された要約率に達するまで文を選択する。
#
#    アプローチ
#    １．テキスト中の単語の重要度を利用する★
#      テキスト中による出現する内容語はテキストの主題を示す傾向があるという仮説が情
#      報検索の分野などではしばしば用いられている。
#      テキスト中での出現頻度（Term frequency : tf法 )
#      出現頻度に加えてｋ単語が出現するテキスト数（document fequency : tf*idf法）
#      要約対象の文書中に現れる単語の頻度を計算し、その順に重要語を定義する方法。頻
#      度が多い語は、その文章の主題に大きく関係していいる後であるとする仮定の下に、
#      主に名詞の頻度を計算し、その語が多く含まれる文を重要文として抽出する方法がと
#      られている。
#      重要文抽出法のデメリットとしてテキストが複数の話題を含む場合に問題が生じる事
#      が指摘されている。
#
#    ２．テキスト中あるいは段落中での文の位置情報を利用する★★★★
#      　テキストは、そのジャンルに依存して、ある程度構造に規則性があると通常考えられ
#      ている。論文には、序論、本論結論、新聞は、見出し、小見出し、本文。テキスト中
#      で重要な文が出現する位置は、ある程度予測可能であると仮定して、テキスト中での
#      文の位置を元に、その文の重要度を計算する手法が考えられている。新聞の記事は、
#      「見出し」「小見出し」「本文」などのような、ある程度決まった構造を持ってい
#      る。また、内容のジャンルによって何らかの構造上の特等がある場合がある。新聞を
#      要約するときはタイトルや、記事の前の方に出ている語の重要度を上げ、文の重要度
#      を計算する。
#
#    ３．見出し、タイトルなどの情報を利用する★★
#      　タイトル、見出しは、ある意味でテキスト本文の時報に簡潔な要約となっていると考
#      えられる。そこで、タイトル、見出しに現れる内容語を含む文が重要であると考え、
#      タイトル、見出し中の単語を重要文抽出に利用する手法が考えられている。
#
#    ４．テキスト中の手がかり表現を利用する★★★
#      　論文では、「本研究では」「まとめると」「われわれは」などの表現を含む文は論文
#      の主題を表すと考えられる。主張、結論、評価などの特別な語を含む文を重要分とす
#      る。「欲しい」「望ましい」「要するに」「まとめると」等が考えられる。このよう
#      な文書の重要な記述部分を示す語を含む文や、その文に含まれる単語の重要度を他の
#      単語より上げる方法がある。
#
#    ５．テキスト中の文あるいは単語間のつながりと関係性情報を利用する。
#      　テキスト中の他の多くの文と強い関連がある文は、テキスト中で中心的な役割を果た
#      していると考える事ができそうである。テキスト中の多くの文と強い関連がある文を中
#      ような文として抽出する手法。意味的に関連があるというのは、類義語（synonym）や連
#      想により意味的な関連があると思われるような場合を言う。類義語の情報を得るにはシ
#      ソーラス（類語辞典）を利用する事が多い。接続詞、照応関係などから文間・単語間の
#      つながりと、その関係の解析を行ってい要約する方法。文書を意味ネットワーク化し
#      て、その上でコネクショニスト・モデルを用いて、接点の活性値の収束値を重要度とし
#      て計算する要約方法。
#
#      　Skorokhod ko は文をノード、文間の関係をリンクするとするグラフをテキストから
#      構成し、多くの文と関係のある文が重要であるという考えに基づき、重要文を抽出す
#      る手法を示している。文中の単語が同一概念を参照しているような文間にリンクがあ
#      るとしている。
#
#      　マニラは、テキスト中の単語などがノードであり、その間の隣接制、構文的関係、
#      共参照関係、語彙的類似性などの関係をアークで表現したグラフでテキストを表現
#      し、このグラフ中での活性値の伝搬により、高い活性値を得た単語、句、文を重要と
#      見なす重要文抽出手法を示している。
#
#      ・他の多くのノードとリンクで結ばれているノードは（段落は）、複数の段落に渡る
#        主題について議論していると考え抽出する。
#      ・最初のノード（先頭段落）あるいは、他のノードとのリンクが多いノードから開始
#        し、それよりもテキスト中で後ろにある。もっとも類似するノードを再帰的に抽出する。
#      ・テキストがセグメント（ある話題のまとまり）に分割できるのであれば、セグメン
#        トからまんべんなく段落を抽出するのがテキスト全体をカバーする要約を作る上でよ
#        いと考えられている。
#      ・新しい話題が始まると、通常その先頭の段落で、その主題について述べる事が多
#        い。セグメントの先頭の段落を抽出すると良い事になる。
#  
#    ６．テキスト中の文間の関係を解析したテキスト構造を利用する。
#      文同士が対等な関係、または片方が片方よりも重要である関係
#      「例示」たとえば「理由」したがってなどの意味的な表現はより重要である。
#
#    ７．オントロジー
#      　システムは内容を理解した上で、重要な部分を要約しているわけではない。内容の理
#      解そのものが、現在のコンピュータで難しい事が原因である。構文解析や意味解析の手
#      法が不足しているだけでなく、人間の持っている常識や当該分野の知識などが不足して
#      いるのである。このような知識の不足に対して、オントロジーの研究が進められてい
#      る。これは概念辞書とも言われるもので、人間の持っている知識を構造化してコン
#      ピュータで扱えるよう電子化したデータベースである。＜いまここ＞
#
#
###############################################################################
# 入力ファイル in 
#title=早大３連覇  斎藤が１５奪三振、初完封  東京六大学野球&body=東京六大学野球秋季リーグは３０日、神宮球場で最終週の早大—慶大３回戦があり、早大が斎藤（１年、早稲田実）の活躍で慶大に７—０で大勝し、３季連続４０度目の優勝を果たした。勝ち点４で明大と並んだが、勝率で上回った。早大は１１月１０日開幕の明治神宮大会への出場も決めた。   斎藤はスライダーやツーシームなどの変化球がさえ、リーグ戦初完封。被安打４で１５奪三振の力投で今季４勝目を挙げた。打線は１回、松本（３年、千葉経大付）の適時打と本田（４年、智弁和歌山）の３点二塁打で４点を先取し、その後も加点した。慶大は３連投のエース加藤幹（４年、川和）が力尽きた。&perMax=50&summaxLength=
#
# 実行例
# $ time ./MAIN.SH < in
#
# 実行結果
# 1. コンソールに出力されます
# 2. index.htmlが生成されてオントロジーレイアウトが表現されます。
#
###############################################################################
# 実行に必要なライブラリなど
# libc/libglibのインストール
#
# #linux
# yum install libc.so.6 ;
# yum install libglib-2.0.so.0
#
# #mac 
# sudo port install glib2
#
########
# saryのインストール
#
# #linux
# rpm -ihv libsary10-1.2.0-4mdk.i586.rpm  
# rpm -ihv sary-1.2.0-4mdk.i586.rpm
#
# $ ln -s /usr/local/bin/sary /usr/bin/sary ;
#
########
# gtk2/pkgconfigのインストール
#
# sudo port install gtk2 ;
# sudo port install pkgconfig ;
#
#
########
# gcc/g++ installのインストール
#
# yum install gcc
# yum install gcc-c++
#
########
# mecab/mecab dic のインストール
#
# mecabのインストール
# wget http://code.google.com/p/mecab/downloads/detail?name=mecab-0.996.tar.gz
# tar -zxvf mecab-0.996.tar.gz
# cd mecab-0.996
# ./configure 
# make
# make check 
# make install 
# ln -s /usr/local/bin/mecab /usr/bin/mecab ;
#
# 形態素解析 mecab dicのインストール
# mecab-ipadicのインストール
# wget https://mecab.googlecode.com/files/mecab-ipadic-2.7.0-20070801.tar.gz
# tar -zxvf mecab-ipadic-2.7.0-20070801.tar.gz
# cd mecab-ipadic-2.7.0-20070801
# ./configure 
# make 
# make check 
# make install 
#
########
# darts のインストール
#
# tar xzvf darts-0.3.tar.gz
# cd darts-0.3
# make clean 
# ./configure
# make clean ;
# make
# make check
# make install
# 
#
########
# TinySVMのインストール
#
# # sudo port install tinysvm
# #でもよい。
# tar xzvf TinySVM-0.09.tar.gz
# cd TinySVM-0.09
# make clean 
# ./configure
# make clean ;
# make
# make check
# make install
# 
# # mac
# # sudo port install tinysvm
#
########
# YumChaのインストール
#
# tar xzvf yamcha-0.33.tar.gz
# cd yamcha-0.33
# make clean 
# ./configure
# make
# make check
# make install
# cd ../ ;
# ln -s /usr/local/bin/yamcha /usr/bin/yamcha ;
#
# コンパイルエラー発生
# error: strlen was not declared in this scope
#
# 対応は以下の通り。
# $ vim src/common.h
# #include < string.h >  (追加)
#
# コンパイルエラー発生
# error: atoi is not a member of ‘std’
#
# 対応は以下の通り。
# $ vim libexec/mkdarts.cpp
# #include < cstdlib >
#
# つまるところ、gcc 4.2 以前と gcc 4.3 の違いに起因するようです。
# ggcc 4.2 以前では、string.h や stdlib.h のようなヘッダファイルは
# 明示的にインクルードしていなくても、そのヘッダファイルでプロトタイプ宣言されている関数を呼び出すことができました。
# gcc 4.3 では明示的なインクルードが必要です。
# とりあえず、 src/common.h に #include <string.h> を追加して make してみます
#
########
# CRF++のインストール
#
# tar xvf CRF++-0.58.tar.gz
# cd CRF++-0.58
# make clean 
# ./configure
# make
# make install
# ln -s /usr/local/bin/crf_learn /usr/bin/crf_learn ;
# ln -s /usr/local/bin/crf_test /usr/bin/crf_test ;
# ldconfig
#
########
# cabochaのインストール
#
# tar zxvf  cabocha-0.60.tar.gz
# cd cabocha-0.60
# 
# # デフォルトはEUC です。
# make clean 
# LIBS=-liconv ./configure --with-posset=IPA
# make
# make install
# ln -s /usr/local/bin/cabocha /usr/bin/cabocha
# ldconfig
#
# コンパイルエラー発生
# error: strlen was not declared in this scope
#
# 対応は以下の通り。
# $ vim src/common.h
# #include <string.h>  (追加)
#
# コンパイルエラー発生
# error: ‘::unlink’ has not been declared
#
# 対応は以下の通り。
# $ vim src/utils.cpp
# #include <unistd.h>  (追加)
#
# コンパイルエラー発生
# chunk_learner.cpp:6:10: fatal error: 'crfpp.h' file not found
# コマンドライン上で、xcode-select --installを実行
# xcodeのコマンドラインツールをインストールされます。
#
# 対応は以下の通り。
# /usr/local/include/crfpp.h  があることを確認する
# .bash_profileでC_INCLUDE_PATHを設定する
# vim /Users/root/.bash_profile
# export C_INCLUDE_PATH=/usr/local/include:$C_INCLUDE_PATH
# 下記で確認する
# echo $C_INCLUDE_PATH
#
########
# jumanのインストール
#
# tar zxvf juman-6.01.tar.gz ;
# cd juman-6.01 ;
# ./configure ;
# make clean ;
# make ;
# make install ;
# ln -s /usr/local/bin/juman /usr/bin/juman ;
# ldconfig  ;
# 
########
# tinycdbのインストール
#
# tar -zxvf tinycdb-0.78.tar.gz ;
# cd tinycdb-0.78
# make clean ;
# make
# make install ;
# ln -s /usr/local/bin/cdb /usr/bin/cdb ;
# ldconfig  ;
#
########
# KNPのインストール
#
#tar -zxvf knp-3.01.tar.gz ;
#cd knp-3.01
#./configure ;
#make clean ;
#make ;
#make install ;
#ln -s /usr/local/bin/knp /usr/bin/knp ;
#ldconfig  ;
#
#make 実行時  下記エラーの場合
#  /bin/sh: line 0: ulimit: stack size: cannot modify limit: Invalid argument
# vim dict/ebcf/Makefile
# SsをSへ書き換える
#
########
# 意見（評価表現）抽出ツールのインストール
#
# #tar -zxvf extractopinion-1.2.tar.gz ;
# # ra カレントディレクトリで
# mv extractopinion-1.2 ../ ;
# cd ../extractopinion-1.2 ;
# cd svmtools
# make clean ;
# make ;
# cd ../pol ;
# make clean ;
# make ;
# ldconfig  ;
#
# #Apacheで動作させるために必要(whichにcrf_testが通っていなければ)
# ln -s /usr/local/bin/crf_test /usr/bin/crf_test ;
# ./extract.sh in8 ;
#
#
########
# macab-jumandicのインストール
#
# $ cd gzArchive 
# $ cd mecab-jumandic-5.1-20070304
# $ ./configure 
# $ make 
# $ sudo make install 
#
########
# JdepP
#
# $ cd gzArchive 
# $ tar -zxvf jdepp-latest.tar.gz
# $ cd jdepp-2015-02-08 
# $ ./configure --with-corpus=kyoto-partial --disable-autopos-train
# $ make 
# $ sudo make install 
# $ ln -s /usr/local/bin/jdepp /usr/bin/jdepp
# $ make model ;
# $ make install ;
#
######################################################


#
#########################################################
# コンフィグレーション
#########################################################
#
  cd `dirname $0`  ;
  #awk='/bin/mawk' ;
  awk="`which gawk`" ;
  #MECAB="/usr/local/bin/mecab" ;
  MECAB="`which mecab`" ;
  #日本語処理のために環境変数LANGを設定
  export LANG=ja_JP.UTF-8
  export LC_ALL=C ;
  #ログファイル
  LOG="$TMP/LOG.TXT";
  #ライブラリのディレクトリ
  LIBDIR="lib";
  #TMPディレクトリ
  TMP="TMP/TMP_`date +%F_%H-%M-%S_%N`";
  mkdir -p "$TMP";
  chmod -R 777 "$TMP"; 
  # 本文の最大取得文字数
  maxLength=3000
  #出力される重要語の数
  TERMEX_ITEM_COUNT=10 ;
  # 重要語抽出の設定
      ####################
      #calc_imp_by_HASH_Freq;
      ####################
      #LR=0;
      #frq=1;
      #
      # LR(連接情報)の設定  
          #    0 → LRなし（隣接情報を使わない）<>
          #    1 → 延べ数を取る
          #    2 → 異なり数を取る
          #    3 → パープレキシティを取る
      # FRQ
          # 無効 0 
          # FRQ  1<>
          # TF   2
      ####################
      #calc_imp_by_HASH_TF;
      ####################
      #LR=0;
      #frq=2;
      #
      # LR(連接情報)の設定  
          #    0 → LRなし（隣接情報を使わない）<>
          #    1 → 延べ数を取る
          #    2 → 異なり数を取る
          #    3 → パープレキシティを取る
## FRQ
          # 無効 0
          # FRQ  1
          # TF   2 <>
      ####################
      #calc_imp_by_HASH; (延べ数)
      ####################
      LR=1;   #default
      frq=1;  #default
      #
      # 延べ数をとるのか異なり数のどちらを選ぶのか。
      # LR(連接情報)の設定  
          #    0 → LRなし（隣接情報を使わない）
          #    1 → 延べ数を取る <>
          #    2 → 異なり数を取る <>
          #    3 → パープレキシティを取る
      # FRQ 
          # 無効 0
          # FRQ  1 <>
          # TF   2
      ####################
      #calc_imp_by_HASH;(異なり数)
      ####################
      #LR=2;
      #frq=1;
      #
      # 延べ数をとるのか異なり数のどちらを選ぶのか。
      # LR(連接情報)の設定  
          #    0 → LRなし（隣接情報を使わない）
          #    1 → 延べ数を取る <>
          #    2 → 異なり数を取る <>
          #    3 → パープレキシティを取る
      # FRQ 
          # 無効 0
          # FRQ  1 <>
          # TF   2
      ####################
      #calc_imp_by_HASH_PP;
      ####################
      #LR=3;
      #frq=2;
      #
      # LR(連接情報)の設定  
          #    0 → LRなし（隣接情報を使わない）
          #    1 → 延べ数を取る
          #    2 → 異なり数を取る
          #    3 → パープレキシティを取る <>
      # FRQ
          # 無効 0
          # FRQ  1
          # TF   2 <> 
  

  #jumanディクショナリ
  JUMANDIC="extractopinion-1.2/jumandic";
  # 形態素解析のパラメータなしでも 1  →  強制取込 
  reset_get_word=0;
  ## 形態素解析のデータを 1 → 取込済 0 → 未取込
  get_word_done=0;
  # 専門用語全体の重要度
  MAX_CMP_SIZE=1024; # 半角空白区切りの単名詞リストの最大長 
  average_rate=1; # 重要度計算での連接情報と文中の用語頻度のバランス
  #絞り込みをかけた重要語候補を出力するTMPファイル
  CmpNounListTmpFile="$TMP/cmp_noun_list_tmp.txt";
  #重要語、頻度を出力するファイル
  CmpNounListFile="$TMP/cmp_noun_list.txt";
  #重要語、頻度を出力するファイル
  NcontListFile="$TMP/ncont_list.txt";
  #複合名詞を半角スペース区切りで分割するTMPファイル
  #OrgNounListFile="$TMP/org_noun_list.txt";
  nounFile="$TMP/noun.txt";
  #重要度計算対象外にする語を指定
  IgnoreWordsFile="$TMP/ignorewords.txt";
  touch "$IgnoreWordsFile"; ## 現状スクリプト内では空のまま
  #重要度計算対象外にする語を検索用に加工したもの
  IgnoreWordsFileTmp="ignorewords.tmp";
  # 出力モードを指定
  # 1 → 専門用語＋重要度、2 → 専門用語のみ
  # 3 → カンマ区切り
  ##my $output_mode = 1;
  #出力モードをパラメータで制御できるようにする。
  #output_mode=1;
  #要約時の圧縮率 POSTパラメータ&permax=50というような指定で要約率を指定することができる。
  perMax=50 ;

  #HTMLで出力するかどうかの判定
  #printHtml="no" ;

  #スポーツ用語を取得するかどうかの判定
  sportsFlg="no" ;
  #スポーツ人名学習するかどうかの判定
  studyName="yes" ;
  #意見評価ディレクトリ
  exopdir="extractopinion-1.2";
  #意見評価 中間ファイルを一時的に保存するディレクトリ
  export TMPDIR="$TMP"
  #意見評価 モデルファイルのプレフィックス
  export model=$exopdir/modeldata/model/model
  #意見評価 辞書のディレクトリ
  export dictionary=$exopdir/dic
  #意見評価 環境変数設定
  export EXOPLIB=$exopdir/lib
  export EXOPDIC=$exopdir/dic
  export EXOPXPR=$exopdir/xpr
  export EXOPSRC=$exopdir/src
  export EXOPPOL=$exopdir/pol
  export EXOPTYP=$exopdir/typ

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
#
#########################################################
# 重要語抽出
# termExtract.sh 
# 重要語解析計算処理は calcImp.sh
#########################################################
#
#
# bash版 すべてのKEYをuniqしてスコアを振り直す
# 入力１: $TERM_EXTRACT_RESULT_LINE ( 変数 )
# 入力２: $TITLE_KEYS_RESULT_LINE ( 変数 )
# 出力： $KEYS_RESULT_LINE ( 変数 )
function termExtract.Rescore.sh(){
  #  本文の最大値だけ取り出す（一番左側)
  DESCRIPTION_SCORE=$(echo "$TERM_EXTRACT_RESULT_LINE" | sed -e "s|</SCORE>.*$||g" -e "s|^.*<SCORE>||g") ;
  # 本文の最大値をタイトルのスコアに加算
  KEYS_TITLE=$(echo "$TITLE_KEYS_RESULT_LINE" | sed -e "s|</KEY>|</KEY>\n|g" | LANG=C grep -i -v "^$" |
    while read line; do 
      TITLE=$(echo "$line" | sed -e "s|^<KEY>||g" -e "s|<SCORE>.*$||g") ;
      TITLE_SCORE=$(echo "$line" | sed -e "s|^.*<SCORE>||g" -e "s|</SCORE>.*$||g") ;
      GT_SCORE=$( echo "$TITLE_SCORE"+"$DESCRIPTION_SCORE" | bc) ;
      echo "<KEY>$TITLE<SCORE>$GT_SCORE</SCORE></KEY>" ;
    done | head -n$TERMEX_ITEM_COUNT |  tr -d "\n"  ;
  );
  KEYS_RESULT_LINE=$(echo "<KEYS>${KEYS_TITLE}${TERM_EXTRACT_RESULT_LINE}</KEYS>") ;
  if [ $DEBUG == "TRUE" ]; then echo "KEYS_RESULT_LINE : $KEYS_RESULT_LINE" ; fi
}
#
# Awk版 # すべてのKEYをuniqしてスコアを振り直す
# 入力１: $TERM_EXTRACT_RESULT_LINE ( 変数 )
# 入力２: $TITLE_KEYS_RESULT_LINE ( 変数 )
# 出力： $KEYS_RESULT_LINE ( 変数 )
function termExtract.Rescore.awk(){
  #本文の最大値だけ取り出す（一番左側)
  DESCRIPTION_SCORE_MAX=$(echo "$TERM_EXTRACT_RESULT_LINE" | $awk '{
    gsub (/<\/SCORE>.*$/, "", $0) ;
    gsub (/^.*<SCORE>/, "", $0) ;
    print $0 ;
  }') ;
  #タイトルのスコアに本文の最大値を加算
  KEYS_TITLE=$(echo "$TITLE_KEYS_RESULT_LINE" | sed -e "s|</KEY>|</KEY>\n|g" | $awk '  /./ {
    TERM=$0 ;
    gsub(/<SCORE>.*$/, "", TERM) ;
    gsub(/^.*<KEY>/, "", TERM) ;
    gsub(/<KEY>/, "", $0) ;
    gsub(/<\/KEY>/, "\n", $0) ;
    gsub(/^.*<SCORE>/, "", $0) ;
    gsub(/<\/SCORE>.*$/, "", $0) ;
    SCORE= $0 + '"$DESCRIPTION_SCORE_MAX"' ; #加算
    printf "<KEY>%s<SCORE>%.2f</SCORE></KEY>" , TERM , SCORE ;
  }' | $awk 'NR<='"$TERMEX_ITEM_COUNT"'');
  #KEYS_RESULT_LINE=$(echo "<KEYS>${KEYS_TITLE}${TERM_EXTRACT_RESULT_LINE}</KEYS>") ;
  KEYS_RESULT_LINE="<KEYS>${KEYS_TITLE}${TERM_EXTRACT_RESULT_LINE}</KEYS>" ;
  if [ $DEBUG == "TRUE" ]; then echo "KEYS_RESULT_LINE : $KEYS_RESULT_LINE" ; fi
}
#
# bash版 # 重要語リストと計算した重要度を変数に出力する
# 出力される重要語の数は以下のパラメータで制御
# in : $awkTermExtractList ; # out :$TermExtOut ; 
# $TERMEX_ITEM_COUNT # $1 : 見出しは空 本文はbc100が入る
function termExtract.execTerm.sh(){
  TermExtOut=$(echo "$awkTermExtractList" | \
    while read line;do
      #スコアを取り出す.小数点２桁にする
      local score=`echo $line| $awk '{print $1;}'`;
      score=`printf "%.2f" $score`;
      #重要語を表示用（単名詞区切なし）に加工
      local noun=`echo $line| $awk '{$1=""; print;}'|sed -e "s| ||g"`;
      #日付・時刻は表示しない
      if echo "$noun"|LANG=C grep -i -E '^(昭和)*(平成)*(\d+年)*(\d+月)*(\d+日)*(午前)*(午後)*(\d+時)*(\d+分)*(\d+秒)*$' > /dev/null ;then
        continue;
      fi
      #数値のみは表示しない
      if echo "$noun"|LANG=C grep -i '^[0-9]*$' >/dev/null ;then
        continue;
      fi
      #$1パラメータにbc100があれば抑制対象とする
      #見出しは全ての重要語を出力するが、本文は1.00以上の重要語を出力（新規追加）
      if [ "$1" = "bc100" ]; then
        #$scoreが1.00以上であれば出力（新規追加）
        if [ $(echo "$score > 1" | bc ) -eq 1 ]; then
          echo "<KEY>$noun<SCORE>$score</SCORE></KEY>";
        fi
      else
          echo "<KEY>$noun<SCORE>$score</SCORE></KEY>";
      fi
    done | head -n$TERMEX_ITEM_COUNT |  tr -d "\n"  ;
  );
  if [ $DEBUG == "TRUE" ]; then echo "TermExtOut : $TermExtOut" ; fi
}
#
# Awk版 # 重要語リストと計算した重要度を変数に出力する
# 入力： <score> <key>
#  1.41421 大学 野球
#  1 連覇
#  1 東京
# scoreは小数点２桁で出力する # 件数はTERMEX_ITEM_COUNT=10件まで出力
# 入力１: $awkTermExtractList ( 変数 ) # 入力２: $output_mode ( 変数 ) ## VOID ##
# 入力３: $TERMEX_ITEM_COUNT ( 変数 ) # 出力: $TermExtOut ( 変数 ) 
# 
function termExtract.execTerm.awk(){
  TermExtOut=$(echo "$awkTermExtractList" | $awk '
    BEGIN{
      bc100="'$1'" ;
    } {
      score=$1 ; #スコアを取り出す
      $1=""; #重要語を表示用（単名詞区切なし）に加工
      noun=$0 ;
      gsub( /[[:blank:]]/ , "" , noun ) ;
      #日付・時刻・数字のみは表示しない
      if (noun ~ /^(昭和)*(平成)*([0-9]+年)*([0-9]+月)*([0-9]+日)*(午前)*(午後)*([0-9]+時)*([0-9]+分)*([0-9]+秒)*$/) {
        next; 
      } else if (noun ~ /^[0-9]*$/) {
        next; 
      }
      if ( bc100 == "bc100" ){ 
        if ( score > 1 ){ #本文はbc100によりscore1以上だけを出力(※新規追加）
          printf "<KEY>%s<SCORE>%.2f</SCORE></KEY>" , noun , score ;
        }
      }else{ #見出しはすべてを出力(※新規追加）
        printf "<KEY>%s<SCORE>%.2f</SCORE></KEY>" , noun , score ;
      }
    }' | $awk 'NR<='"$TERMEX_ITEM_COUNT"'') ;
  if [ $DEBUG == "TRUE" ]; then echo "TermExtOut : $TermExtOut" ; fi
}
#
function termExtract.get_imp_word_while.sh(){
      line="$@" ;
      source terms.tmp ;
      part_of_speach=`echo "${line}"| sed -e "s/\,.*$//g" -e "s/^.* //g"` ;
      noun=`echo "${line}"| sed -e "s/ .*$//g"`;
      cl_1=`echo "${line}"| sed -e "s/^[^\,]*\,//g" -e "s/\,.*$//g"`;
      if [ "$part_of_speach" == "名詞" ]; then 
        cl_2=`echo "${line}"| sed -e "s/^.* //g" | $awk -F ',' '{ print $3 ; }'`;
        if [  \( "$cl_1" == "一般" -o  "$cl_1" == "サ変接続" -o "$cl_1" == "固有名詞" -o  \( "$cl_1" == "接尾"  -a \( "$cl_2" == "一般" -o "$cl_2" == "サ変接続" \) \) \) ]; then
          echo "terms=\"$terms $noun\"; must=\"0\"; " > terms.tmp ;
          return  ;
        elif [ \( \( "$cl_1" == "接尾" -a "$cl_2" == "形容動詞語幹" \) -o  "$cl_1" == "形容動詞語幹" -o  "$cl_1" == "ナイ形容詞語幹" \) ]; then
          echo "terms=\"$terms $noun\"; must=\"1\"; " > terms.tmp ;
          return ;
        else
          if [ "$must" == "0" ] ;then
             terms=$(echo "$terms" | sed -e "s/^ //g" -e "s/ $//g" -e "s/^本 //g" -e "s/ など$//g" -e "s/ ら$//g" -e "s/ 上$//g" -e "s/ 内$//g" -e "s/ 型$//g" -e "s/ 間$//g" -e "s/ 中$//g" -e "s/ 毎$//g" -e "s/ 等$//g");
             must="0" ; 
            if [ ! -z "$terms" ] ;then 
              echo "$terms"; 
            fi
            echo "terms=\"\"; must=\"0\"; " > terms.tmp ;
          fi
        fi 
      elif [ "$part_of_speach" == "記号" -a "$cl_1" == "アルファベット" ]; then
          echo "terms=\"$terms $noun\"; must=\"0\";" > terms.tmp
          return  ;
      elif [ "$part_of_speach" == "動詞" ]; then
         echo "terms=\"\"" > terms.tmp
      else 
        if [ "$must" == "0" ] ;then
           terms=$(echo "$terms" | sed -e "s/^ //g" -e "s/ $//g" -e "s/^本 //g" -e "s/ など$//g" -e "s/ ら$//g" -e "s/ 上$//g" -e "s/ 内$//g" -e "s/ 型$//g" -e "s/ 間$//g" -e "s/ 中$//g" -e "s/ 毎$//g" -e "s/ 等$//g");
           must="0" ;
          if [ ! -z "$terms" ] ;then 
            echo "$terms"; 
            :>terms.tmp ;
          fi
           echo "terms=\"\"; must=\"0\"; " > terms.tmp ;
        else
          :>terms.tmp ;
        fi
      fi
      #名詞でも形容動詞は重要語としてとりこまない
      if [ "$must" == "1" ] ; then
         echo "terms=\"\"; must=\"0\"; " > terms.tmp ;
      fi
}
#
# bash版 # 重要度取得
# 入力:$MECAB_OUT # 出力:$comNounList
function termExtract.get_imp_word.sh(){
  export -f termExtract.get_imp_word_while.sh  ;
  :>terms.tmp ;
  comNounList=$( echo "$MECAB_OUT" | nkf -Ew  | if [ -n "${TMP}" ] || [ "${reset_get_word}" = "1" ] ; then
    while read line ;do
      #echo "$line" | xargs -P6 -I % /bin/bash -c "termExtract.get_imp_word_while.sh %" ; 
      termExtract.get_imp_word_while.sh $line ;
    done | LANG=C sort -s -k1 | uniq -c | sed -e "s/^ *//g" ;
    elif [ "${LR}" = "0" ] && [ "${frq}" = "0" ] ; then
     exit;
    elif [ "${get_word_done}" = "0" ] ; then
      exit;
    fi 
  );
  if [ $DEBUG == "TRUE" ]; then echo "comNounList : $comNounList" ; fi
}
#
# Awk版 # 重要度取得
# 入力:$MECAB_OUT # 出力:$comNounList
#
#1 完封
#1 三振
#1 斎藤
#1 東京
#1 大学 野球
#1 連覇
#1 早大
#
function termExtract.get_imp_word.awk(){
  comNounList=$( echo "$MECAB_OUT" | nkf -Ew | $awk '
  BEGIN{
    get_word_done = "'$get_word_done'" ;
    LR = "'$LR'" ;
    frq = "'$frq'" ;
    TMP = "'$TMP'" ;
    if ( LR == 0 && frq == 0 ){
      exit;     # LR でも頻度でも重要度計算しないときは強制終了
    } else if ( TMP  != "" || reset_get_word == 1 ){
      # 処理継続
    } else if ( get_word_done == 0 ) {
      exit;
    }
  } {
    noun=$1;    #単語の解析結果 名詞,一般,*,*,*,*,大学,ダイガク,ダイガク
    val=$2;     #単語解析結果から先頭３つ（品詞,品詞細分類1,品詞細分類2）を抽出
    part_of_speach="";
    cl_1="";
    cl_2="";
    split(val , hArray, ",");
    if ( val != "" ) {
      part_of_speach=hArray[1]; #名詞
      cl_1=hArray[2];           #一般
      cl_2=hArray[3];           #サ変接続
    }
    if ( part_of_speach == "名詞" && (cl_1 == "一般" ||  cl_1 == "サ変接続" || cl_1 == "固有名詞" ||  ( cl_1 == "接尾"  && (cl_2 == "一般" || cl_2 == "サ変接続")) ) ){
      terms = terms " " noun; must  = 0; next;
    } else if ( part_of_speach == "名詞" && ( (cl_1 == "接尾" && cl_2 == "形容動詞語幹") || cl_1 == "形容動詞語幹" || cl_1 == "ナイ形容詞語幹") ) {
      terms = terms " " noun; must  = 1; next;
    }else if ( part_of_speach == "記号" && cl_1 == "アルファベット") {
      terms = terms " " noun; must  = 0; next;
    } else if (part_of_speach == "動詞") {
      terms = "";
    } else {
      if ( must == "0") {
        gsub(/^ /, "", terms); gsub(/ $/, "", terms); gsub(/^本 /, "", terms); gsub(/ など$/, "", terms);
        gsub(/ ら$/, ""  terms); gsub(/ 上$/, "", terms); gsub(/ 内$/, "", terms); gsub(/ 型$/, "", terms);
        gsub(/ 間$/, "", terms); gsub(/ 中$/, "", terms); gsub(/ 毎$/, "", terms); gsub(/ 等$/, "", terms);
        if ( terms != "") {
          terms_hash[terms] += 1;
        }
        terms = "";
      }
    }
    if (must == "1") {  #名詞でも形容動詞は重要語としてとりこまない
      terms = ""; must  = "0";
    }
  } END {
    for (key in terms_hash) {
      print terms_hash[key] " " key;
    }
  }' ) ;
  reset_get_word=0; 
  if [ -z "$comNounList" ] ;then exit ; fi
  if [ $DEBUG == "TRUE" ]; then echo "comNounList : "; echo "$comNounList" ; fi
}
#
# 標準入力に渡された文章を「。」区切りで改行する
# 複数の空白を一つにする。 句点「。」があれば改行をいれる。
# 「」（）の中であれば句点があっても改行をいれない
# 入力: 標準入力 # 出力: 標準出力
function func_KutenKaigyo(){
  LC_ALL="" ;
  awk '{
    KAGK=0; MARK=0; MAHK=0;
    gsub(/[[:blank:]]+/, "  ", $0);
    num = split($0,sa,"");
    for ( a = 1; a <= num ; a++ ) {
      printf "%s" , sa[a] ;
      if ( sa[a] == "「" ){ KAGK=1; }
      else if ( sa[a] == "」" ){ KAGK=0; }
      else if ( sa[a] == "（" ){ MARK=1; }
      else if ( sa[a] == "）" ){ MARK=0; }
      else if ( sa[a] == "(" ){ MAHK=1; }
      else if ( sa[a] == ")" ){ MAHK=0; }
      else if ( sa[a] == "。" ){
        if ( (KAGK+MARK+MAHK) == 0 ){
          printf "\n" ;
        } 
      }
    }
  }END{
    printf "\n" ;
  }' < /dev/stdin
}
#
# $1を形態素解析 タイトル 本文を引数に取る
# in  $TITLE # in  $DESCRIPTION # out $MECAB_OUT ;
function termExtract.execMecab(){
  MECAB_OUT=$( echo "$1" | func_KutenKaigyo | nkf -We | "$MECAB" -b 4096 ) ;
  if [ $DEBUG == "TRUE" ]; then echo "MECAB_OUT : " ; echo "$MECAB_OUT" | nkf -wLu ; fi
}
#
function termExtract(){
    termExtract.execMecab "$TITLE"; # 見出しの形態素解析
    termExtract.get_imp_word.awk;   # 重要語候補抽出
    #termExtract.get_imp_word.sh;    # 重要語候補抽出
    termExtract.calcImp ;                 # 重要度計算(awk とbashの共用）ここは最大重要課題
    termExtract.execTerm.awk;                 # 重要語リストと計算した重要度を変数に出力する。
    #termExtract.execTerm.sh;             # 見出しは全ての重要語を出力(※新規追加）
    TITLE_KEYS_RESULT_LINE="$TermExtOut" ; # 見出しの結果を格納
    #
    termExtract.execMecab "$DESCRIPTION" ;     # 本文の形態素解析
    termExtract.get_imp_word.awk;   # メソッド実行
    #termExtract.get_imp_word.sh;    # メソッド実行
    termExtract.calcImp ;                 # 重要度計算(awk とbashの共用）ここは最大重要課題
    termExtract.execTerm.awk "bc100" ;        # 重要語リストと計算した重要度をファイルに出力する。
    #termExtract.execTerm.sh "bc100";     # 本文はbc100によりスコア1.00以上の重要語を出力（※新規追加）
    TERM_EXTRACT_RESULT_LINE="$TermExtOut" ; #本文の結果を格納
    termExtract.Rescore.awk;                   # スコアの振り直し
    #termExtract.Rescore.sh ;              # 重要語を整列させてスコアを振り直す
}
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
    elif [ $LR -eq 1 -o $LR -eq 2 ]; then
      calc_imp_by_HASH;  #LR=1; frq=1;   #default
      awkTermExtractList_LRTOTAL="$awkTermExtractList" ;
      awkTermExtractList_LRUNIQ="$awkTermExtractList" ;
    elif [ $LR -eq 3 ];then
      calc_imp_by_HASH_PP;
      awkTermExtractList_LRPP="$awkTermExtractList" ;
    else 
      :
    fi	  
}
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
#
###############################################################
# オントロジー構築
###############################################################
#
# ※どこで使用されているのか不明
#
# 現在の階層のリストを渡すと一つ上のノードを見つける
# 再帰呼び出しされる
#
# 入力１: $TMP_DEPTH_LIST ( 引数、ファイル )
# 入力２: $NODE_DEPTH ( 引数、変数 )
# 入力３: $NODE_HISTORY ( 引数、変数 )
# 入力４: $TOTAL_SCORE ( 引数、変数 )
# 入力: $IS_HAS_TABLE ( 変数 )
# 入力: $TMP_HISTORY_LIST ( ファイル )
# 入力: $IS_HAS_TABLE_FIN ( 変数 )
# 
function func_search_pre_node (){
  local PRE_DEPTH_LIST="$1" ;
  local NODE_DEPTH=$(($2 + 1 ));
  local NODE_HISTORY="$3" ;
  local TOTAL_SCORE="$4" ;
  echo "$nextpath" | $awk  \
  -v PRE_DEPTH_LIST="$PRE_DEPTH_LIST" \
  -v NODE_DEPTH="$NODE_DEPTH" \
  -v NODE_HISTORY="$NODE_HISTORY" \
  -v TOTAL_SCORE="$TOTAL_SCORE" \
  -v ishs_table_fin="$ishs_table_fin" \
  -v ishs_table="$ishs_table" \
  '
  # 再帰処理関数
  function search_pre_node(node_depth,node_hist,ttl_score,predepath,
                           nextp_n, np, p, sahen,  ## ここからは、local変数
                           NODE_SCORE, a, EDGE_SCORE,
                           TMP_TOTAL_SCORE, TMP_NODE_HIST,
                           sahenNo, tmpdepath, matchword1, matchword2  ){
    # 次のノードのパス（現ノードをインクリメント）
    node_depth = node_depth + 1 ;
    #
    # MAIN処理部 パスリスト毎に処理を行う
    nextp_n=split(predepath , np , "|" ) ;
    for ( p = 1 ; p <= nextp_n ; p++ ){
    #  空の場合はスキップ
      if ( np[p] == "" ){
        continue ;
      }
      #
      # 左辺を抽出
      sahen=np[p] ;
      gsub(/->.*$/,"",sahen); 
      #
      # NODE_SCORE計算
      # IS_HAS_TABLE_FINからスコアを抽出
      NODE_SCORE= 0 ;
      for ( a = 1 ; a <= ih_tf_n ; a++ ){
        if (index(sa[a], sahen) > 0 ){
          NODE_SCORE = sa[a] ;
          gsub(/^.*comment=/, "" , NODE_SCORE ) ;
          gsub(/].*$/, "" , NODE_SCORE ) ;
          break ;
        }
      }
      if ( NODE_SCORE == "" ){ NODE_SCORE = 0 } ;
      #
      # EDGH_SCORE計算
      EDGE_SCORE = np[p] ;
      gsub(/^.*label=\"/,"",EDGE_SCORE); 
      gsub(/\" .*/,"",EDGE_SCORE); 
      if ( EDGE_SCORE == "" ){ EDGE_SCORE = 0 } ;
      #
      # TOTAL_SCORE に、NODE_SCORE,EDGE_SCOREを加算
      TMP_TOTAL_SCORE = ttl_score + NODE_SCORE + EDGE_SCORE ;
      #
      # 経路に、現在のNODEを追加
      TMP_NODE_HIST = sahen "->" node_hist ;
      #
      # 左辺の番号を取得
      # ＊左辺文字列だけでなく、文字列＋番号で検索するため
      sahenNo = np[p] ;
      gsub(/^.*comment=\"/,"",sahenNo); 
      gsub(/,.*$/,"",sahenNo); 
      #
      # IS_HAS_TABLEから、左辺に対応する上位ノードを探索
      tmpdepath = "";
      NODE_SCORE= 0 ;
      matchword1 = "," sahenNo "\"" ;
      matchword2 = "->" sahen ;
      for ( a = 1 ; a <= ih_t_n ; a++ ){
        if (index(saa[a], matchword1) > 0 ){
          if (index(saa[a], matchword2) > 0 ){
            tmpdepath = tmpdepath "|" saa[a] ;
          }
        }
      }
      #
      # 再帰呼び出し(対応する左辺の上位ノードがあった場合のみ)
      if ( tmpdepath != "" ){
        search_pre_node( node_depth , TMP_NODE_HIST , TMP_TOTAL_SCORE , tmpdepath);
      }
      #
      # 経路／スコアを出力(最終出力)
      printf "%.2f %s\n" , TMP_TOTAL_SCORE , TMP_NODE_HIST ; 
    }
  }
  BEGIN{
    # IS_HAS_TABLE_FIN 読み込み
    ih_tf_n=split(ishs_table_fin , sa , "|" ) ;
    # IS_HAS_TABLE 読み込み
    ih_t_n=split(ishs_table , saa , "|" ) ; 
  }
  {
    nextpath = $0 ;
    search_pre_node( NODE_DEPTH , NODE_HISTORY , TOTAL_SCORE ,nextpath);
  }
  ' ;
}

#
# 係り受けリストから、最も重要度の高い道を見つける。
#
# 入力１: $IS_HAS_TABLE ( 変数 )  係り受けの一覧
# 入力２: $IS_HAS_TABLE_FIN ( 変数 )  重要語の一覧
# 出力: $JUUYOU_LINE ( 変数 ) 最も重要度が高い道
#
# 係り受けリストを組み合わせて作成できるすべての文章に対し、
# 単語毎の重要度、係り受けの重要度、人名／地名／組織の重要度を合算する。
# これにより最も重要度の高い言葉がつながった文章が作成される。
#
#    係り受けリストを組み合わせて作成できるすべての文章に対し、単語毎の重要度、係り受けの重要度、人名／地名／組織の重要度を合算する。
#    これにより最も重要度の高い言葉がつながった文章が作成される。
#    
#    単語毎の重要度：上記重要語の抽出アルゴリズムを用いて算出
#    係り受けの重要度：cabochaコマンドで出力されたものを用いる
#    人名／地名／組織の重要度：単語毎の重要度が基本であるが、それが0である場合は1とする
#    例）
#    ■ 係り受けとその重要度リスト
#      "４点を"->"先取し" [label="3.09"]
#      "先取し"->"加点した" [label="0.00"]
#      "その後も"->"加点した" [label="3.10"]
#      "加点した"->"力尽きた" [label="0.00"]
#      "慶大は"->"力尽きた" [label="3.65"]
#      "３連投の"->"エース加藤幹" [label="0.32"]
#      "エース加藤幹"->"（４年" [label="0.00"]
#      "（４年"->"力尽きた" [label="0.00"]
#      "川和）が"->"力尽きた" [label="0.00"]
#    ■ 重要語リスト
#      エース加藤幹 1.59
#      慶大 3.00
#    ■ 人名リスト
#      加藤幹
#    ■ 地名リスト
#      川和
#    ■ 組織リスト
#      慶大
#    ■ 重要度の計算
#      "４点を"->"先取し"->"加点した"->"力尽きた"
#        (1)係り受けの計算
#           3.09 + 0.00 + 0.00 = 3.09
#        (2)重要語、人名、地名、組織の計算
#           0 + 0 + 0 + 0  = 0
#        (3) (1)と(2)の合計値
#           3.09 + 0 = 3.09
#        
#      "その後も"->"加点した"->"力尽きた"
#        (1)係り受けの計算
#           3.10 + 0.00 = 3.10
#        (2)重要語、人名、地名、組織の計算
#           0 + 0 + 0 = 0
#        (3) (1)と(2)の合計値
#           3.10 + 0 = 3.10
#        
#      "慶大は"->"力尽きた"
#        (1)係り受けの計算
#           3.65 = 3.65
#        (2)重要語、人名、地名、組織の計算
#           3.00 + 0 = 3.00
#        (3) (1)と(2)の合計値
#           3.65 + 3.00 = 6.65
#        
#      "３連投の"->"エース加藤幹"->"（４年"->"力尽きた"
#        (1)係り受けの計算
#           0.32 + 0.00 + 0.00 = 0.32
#        (2)重要語、人名、地名、組織の計算
#           0 + 1.59 + 0 + 0 = 0
#        (3) (1)と(2)の合計値
#           0.32 + 1.59 = 1.91
#        
#      "エース加藤幹"->"（４年"->"力尽きた"
#        (1)係り受けの計算
#           0.00 + 0.00 = 0.00
#        (2)重要語、人名、地名、組織の計算
#           1.59 + 0 + 0 = 0
#        (3) (1)と(2)の合計値
#           0.00 + 1.59 = 1.59
#        
#      "川和）が"->"力尽きた"
#        (1)係り受けの計算
#           0.00 = 0.00
#        (2)重要語、人名、地名、組織の計算
#           1 + 0 = 1.00
#        (3) (1)と(2)の合計値
#           0.00 + 1.00 = 1
#        
#    文章ごとに点数を上記のように計算した結果、
#    最も合計値が高い「"慶大は"->"力尽きた"」を要約文とする。
# 
#
# 現段階ではシェルでファイル出力ありで書く。
# 動きが完成したらawkに置き換える
# -> awkへの移植完了
#
function makeGraph.JUUYOU_LINE(){
  ## makeDigraph で定義していたが、ここでやるべき。重要度の一覧
  IS_HAS_TABLE_FIN=`echo -e "$IS_TABLE_FIN\n$HAS_TABLE_FIN" | LANG=C sort -s -k1 -u` ; 
  #echo "$IS_HAS_TABLE_FIN" ; #debug
  #echo "$IS_HAS_TABLE" ; #debug
  # IS_HAS_TABLE_FIN,IS_HAS_TABLEを１行で変数化
  ishs_table_fin=$(echo "$IS_HAS_TABLE_FIN" | tr "\n" "|" );
  ishs_table=$(echo "$IS_HAS_TABLE" | tr "\n" "|" ); 
  NODE_DEPTH=1;
  HISTORY_LIST="${TMP}/HISTORY_LIST" ;
  TMP_HISTORY_LIST="${TMP}/HISTORY_LIST.tmp" ;
  :>$TMP_HISTORY_LIST ;
  # スタート位置は一番下のノード
  TAIL_POSITION=`echo "$IS_HAS_TABLE" | tail -n1 | sed -e "s/^.*->//g" -e "s|\[label.*||g"` ;
  TMP_DEPTH_LIST="${TMP}/NODE_${NODE_DEPTH}_LIST" ;
  uhenNo=`echo "$IS_HAS_TABLE" | tail -n1 | sed -e "s/^.*comment=.*,//g" -e "s|\" pen.*$||g"` ;
  #echo "$IS_HAS_TABLE" |LANG=C grep -i ",${uhenNo}\" pen"| LANG=C grep -i "\->${TAIL_POSITION}" > "$TMP_DEPTH_LIST"
  nextpath=`echo "$IS_HAS_TABLE" |LANG=C grep -i ",${uhenNo}\" pen"| LANG=C grep -i "\->${TAIL_POSITION}" | tr "\n" "|" `;
  #echo "depth $NODE_DEPTH 終了" ;
  # 現在の階層のリストを渡すと一つ上のノードを見つける
  #func_search_pre_node "$TMP_DEPTH_LIST" "$NODE_DEPTH" "$TAIL_POSITION" "0";
  RESULTLINE=`func_search_pre_node "$TMP_DEPTH_LIST" "$NODE_DEPTH" "$TAIL_POSITION" "0"`;
  
  #cat "$TMP_HISTORY_LIST" | sort -n > "$HISTORY_LIST" ;
  echo  "$RESULTLINE" | LANG=C sort -s -k1 -n > "$HISTORY_LIST" ;
  #cat "$HISTORY_LIST" ; #debug
  # 重要度が最も高い道が決定
  JUUYOU_LINE=$(tail -n1 $HISTORY_LIST | $awk '{ print $2; }' );
  #JUUYOU_LINE=$(tail -n1 $HISTORY_LIST | $awk '{ print $2; }' | sed -e 's|"|\\\"|g');
  # 例
  #JUUYOU_LINE="\\\"早大が\\\"->\\\"果たした\\\"->\\\"上回った\\\"->\\\"決めた\\\"->\\\"リーグ戦初完封\\\"->\\\"挙げた\\\"->\\\"加点した\\\"->\\\"力尽きた\\\"";
  if [ $DEBUG == "TRUE" ]; then echo "JUUYOU_LINE : $JUUYOU_LINE" ; fi
}
#
# HAS_TABLEとTERMEXを重ねる # IS_TABLEの各要素について、以下の条件で出力する
# ・重要後(TERMEXに合致)
# ・色設定(HASCOLOR_TABLEに合致)
#   ＊重要語スコアが０、及び色設定がされている場合、
#     重要語スコアは１として出力する
#
# 入力１: $TERMEX ( 変数 ) # 入力２: $HAS_TABLE ( 変数 ) # 入力３: $HASCOLOR_TABLE ( 変数 )
# 出力: $HAS_TABLE_FIN ( 変数 )
#
#HAS_TABLE_FIN
#"１０日"[peripheries=1 color=yellow label="１０日<BR>(0)" comment=1]
#"適時打と"[peripheries=1  label="適時打と<BR>(1.41)" comment=1.41]
#"松本（３年"[peripheries=1 color=red label="松本（３年<BR>(0)" comment=1]
#"エース加藤幹"[peripheries=1 color=red label="エース加藤幹<BR>(1.59)" comment=1.59]
#"リーグ戦初完封"[peripheries=1  label="リーグ戦初完封<BR>(1.68)" comment=1.68]
#"明治神宮大会への"[peripheries=1 color=blue label="明治神宮大会への<BR>(1.59)" comment=1.59]
#
function makeGraph.HAS_TABLE_FIN(){
  COLOR_TMP=$(echo "$HASCOLOR_TABLE" | tr "\n" " " );
  #HAS_TABLE_FIN=`echo "$HAS_TABLE" | $awk '
  HAS_TABLE_FIN=`echo "$HAS_TABLE" | awk '
  BEGIN{
    icolor=1;
    RtableNum=split("'"$RTABLE"'",ratbl, ":");
    for ( i=1; i<=RtableNum; i++){
      split(ratbl[i],rtmp," ");
      Rcount[rtmp[2]]=rtmp[1];
    }
    split("'"$COLOR_TMP"'" , tcolor , " " );
  }
  {
    has_table=$0; 
    split( tcolor[icolor] , col , "," );
    COLOR = col[1] ;  # 色設定を取得
    # 重要後スコアを取得
    EXSCORE = col[2] ; 
    gsub ( /EXTERM:/, "", EXSCORE) ;
    # NODEから、" を除去し、LABEL情報を生成
    _label = has_table ;
    gsub( /"/ , "" , _label );
    RCNT=Rcount[_label];
    if (RCNT != ""){
      rc=sprintf("%.2f" ,RCNT);
      RCNT="R"rc; 
  
    }
    ex=sprintf("%.2f" ,EXSCORE);
    LABEL = "label=\"" _label "<BR>" "(T" ex RCNT ")\"";
    COMMENT = "comment=" EXSCORE ;
    # COLOR設定がNONEの場合は、設定値を削除
    if ( COLOR == "NONE" ){
      COLOR="" ;
    } 
    # 重要後スコアの小数点を切り下げ
    gsub ( /\.../, "", EXSCORE) ;
    # 色設定有りで、重要語スコアが０の場合は、
    # スコア最小値「１」を設定
    if ( COLOR != "" && EXSCORE == 0 ){
      EXSCORE = 1;
      COMMENT = "comment=" EXSCORE ;
    }
    # 色設定有り  もしくは  重要語スコア有り
    # の場合、NODE情報を出力
    if ( COLOR != ""  || EXSCORE != 0 || RCNT != ""){
          print  has_table  "[peripheries=" EXSCORE  " " COLOR " " LABEL " " COMMENT "]"
    }
    icolor++;
  }' | LANG=C sort -s -k1 -u` ;
  if [ $DEBUG == "TRUE" ]; then echo "HAS_TABLE_FIN : $HAS_TABLE_FIN" ; fi
}
#
# IS_TABLEとTERMEXを重ねる
# 入力１: $TERMEX ( 変数 ) # 入力２: $IS_TABLE ( 変数 ) # 入力３: $COLOR_TABLE ( 変数 )
# 出力: $IS_TABLE_FIN ( 変数 )
#
# IS_TABLE_FIN
#"本田"[peripheries=1 color=red label="本田<BR>(0)" comment=1]
#"明大と"[peripheries=1 color=green label="明大と<BR>(0)" comment=1]
#"１０日"[peripheries=1 color=yellow label="１０日<BR>(0)" comment=1]
#"１１月"[peripheries=1 color=yellow label="１１月<BR>(0)" comment=1]
#"３０日"[peripheries=1 color=yellow label="３０日<BR>(0)" comment=1]
#"斎藤は"[peripheries=2 color=red label="斎藤は<BR>(2)" comment=2]
#"慶大に"[peripheries=3 color=green label="慶大に<BR>(3)" comment=3]
#"慶大は"[peripheries=3 color=green label="慶大は<BR>(3)" comment=3]
#"早大が"[peripheries=3 color=green label="早大が<BR>(3)" comment=3]
# * label中の<BR>は、必要に応じて改行へ置き換えて利用する
#
# IS_TABLEの各要素について、以下の条件で出力する
# ・重要後(TERMEXに合致)
# ・色設定(COLOR_TABLEに合致)
#   ＊重要語スコアが０、及び色設定がされている場合、
#     重要語スコアは１として出力する
#
function makeGraph.IS_TABLE_FIN(){
  COLOR_TMP=$(echo "$COLOR_TABLE" | tr "\n" " " );
  RTABLE=`echo "$HAS_TABLE"| LANG=C sort -s -k1 |uniq -c|sed -e "s|\"||g"|tr "\n" ":"`;
  #IS_TABLE_FIN=`echo "$IS_TABLE" | $awk '
  IS_TABLE_FIN=`echo "$IS_TABLE" | awk '
  BEGIN{
    icolor=1;
    RtableNum=split("'"$RTABLE"'",ratbl, ":");
    for ( i=1; i<=RtableNum; i++){
      split(ratbl[i],rtmp," ");
      Rcount[rtmp[2]]=rtmp[1];
    }
    split("'"$COLOR_TMP"'" , tcolor , " " );
  }
  {
    is_table=$0; 
    split( tcolor[icolor] , col , "," );
    COLOR = col[1] ;  # 色設定を取得
    # 重要後スコアを取得
    EXSCORE = col[2] ; 
    gsub ( /EXTERM:/, "", EXSCORE) ;
    # NODEから、" を除去し、LABEL情報を生成
    _label = is_table ;
    gsub( /"/ , "" , _label );
    RCNT=Rcount[_label];
    if (RCNT != ""){
      rc=sprintf("%.2f" ,RCNT);
      RCNT="R"rc; 
    }
    ex=sprintf("%.2f" ,EXSCORE);
    LABEL = "label=\"" _label "<BR>" "(T" ex RCNT ")\"";
    COMMENT = "comment=" EXSCORE ;
    # COLOR設定がNONEの場合は、設定値を削除
    if ( COLOR == "NONE" ){
      COLOR="" ;
    } 
    # 重要後スコアの小数点を切り下げ
    gsub ( /\.../, "", EXSCORE) ;
    # 色設定有りで、重要語スコアが０の場合は、
    # スコア最小値「１」を設定
    if ( COLOR != "" && EXSCORE == 0 ){
      EXSCORE = 1;
      COMMENT = "comment=" EXSCORE ;
    }
    # 色設定有り  もしくは  重要語スコア有り
    # の場合、NODE情報を出力
    if ( COLOR != ""  || EXSCORE != 0 || RCNT != ""){
          print  is_table  "[peripheries=" EXSCORE  " " COLOR " " LABEL " " COMMENT "]"
    }
    icolor++ ; 
  }' | LANG=C sort -s -k1 -u` ;
  if [ $DEBUG == "TRUE" ]; then echo "IS_TABLE_FIN : $IS_TABLE_FIN" ; fi
}
#
# $IS_TABLEと$HAS_TABLEをpasteコマンドで結合する
# ノード連携情報の最終リスト # HASがなければ出力しない
# 入力１: $HAS_TABLE ( 変数 ) # 入力２: $FILE_IS_TABLE ( ファイル ) # 出力: $IS_HAS_TABLE
#
#IS_HAS_TABLE
#"東京六大学野球秋季リーグは"->"あり"
#"３０日"->"あり"
#"神宮球場で"->"あり"
#"最終週の"->"３回戦が"
#"早大慶大"->"３回戦が"
#"３回戦が"->"あり"
#"あり"->"果たした"
#"早大が"->"果たした"
#"斎藤１年"->"果たした"
#"早稲田実の"->"活躍で"
#"活躍で"->"大勝し"
#"慶大に"->"大勝し"
#"７０で"->"大勝し"
#"大勝し"->"果たした"
#"３季連続４０度目の"->"優勝を"
#
function makeGraph.IS_HAS_TABLE(){
   FILE_COLOR="$TMP/color.txt" ;
   echo "$COLOR_TABLE" | $awk -F"," '{
     EDGE = $3 ;
     gsub(/EDGE:/ , "" , EDGE ) ;
     penwidth = EDGE + 1;
     myNoAndNextNo = $4 "," $5 ;
     printf "[label=\"%.2f\" comment=\"%s\" penwidth=%d]\n" , EDGE , myNoAndNextNo ,penwidth;
   }' > "$FILE_COLOR" 
  # IS_HAS_TABLE=`echo "$HAS_TABLE" | paste  "$FILE_IS_TABLE" - | sed -e "s/\t/->/g" | LANG=C grep -i -v "\->$"` ;
   IS_HAS_TABLE=`echo "$HAS_TABLE" | paste  "$FILE_IS_TABLE" -  | sed -e "s/\t/->/g" | paste - "$FILE_COLOR" | sed -e "s/\t/ /g"| LANG=C grep -i -v "\-> \[label"` ;
  if [ $DEBUG == "TRUE" ]; then echo "IS_HAS_TABLE : $IS_HAS_TABLE" ; fi
}
#
# $HASCOLOR_TABLEの作成
# 入力１: $IS_TABLE ( 変数 ) # 入力２: $NODEMAP ( 変数 ) # 出力１: $HASCOLOR_TABLE ( 変数 )
#
# HASCOLOR_TABLE
#  color=blue,EXTERM:1.83,EDGE:0.383102
#  color=yellow,EXTERM:0,EDGE:0.971905
#  color=blue,EXTERM:0,EDGE:2.401455
#  NONE,EXTERM:0,EDGE:1.533620
#  color=green,EXTERM:6,EDGE:1.868122
#  NONE,EXTERM:0,EDGE:0.000000
#  NONE,EXTERM:0,EDGE:1.961707
#  color=green,EXTERM:3,EDGE:2.674352
#  ＊詳細
#   1:COLOR:色情報
#   2:EXTERM:重要語スコア
#   3:EDGE:係り受けスコア
#
# cabocha出力結果に対し、 地名／人名／組織の場合はカラーコードを設定
#  B-LOCATION    (地域):"color=blue"
#  B-PERSON      (人名):"color=red"
#  B-ORGANIZATION(組織):"color=green"
#
function makeGraph.HASCOLOR_TABLE(){
  COLOR_TMP=$(echo "$COLOR_TABLE" | tr "\n" " " );
  #HASCOLOR_TABLE=`echo "$NODEMAP" | $awk -F " " '
  HASCOLOR_TABLE=`echo "$NODEMAP" | awk -F " " '
    BEGIN {
      HAS="" ;
      split("'"$COLOR_TMP"'" , tcolor , " " );
    } {
      HAS=$2 ;
      if ( tcolor[HAS+1] != "" ){
        print tcolor[HAS+1] ;
      }
    }' ` ;
  if [ $DEBUG == "TRUE" ]; then echo "HASCOLOR_TABLE : $HASCOLOR_TABLE" ; fi
}
#
# $HAS_TABLEの作成
# 入力１: $IS_TABLE ( 変数 ) # 入力２: $NODEMAP ( 変数 )
# 出力１: $HAS_TABLE ( 変数 ) # 出力２: $FILE_IS_TABLE ( ファイル )
#
#HAS_TABLE
#"決めた"
#"決めた"
#"１０日"
#"開幕の"
#"明治神宮大会への"
#"出場も"
#"決めた"
#"リーグ戦初完封"
#"リーグ戦初完封"
#"ツーシームなどの"
#"変化球が"
#"さえ"
#
function makeGraph.HAS_TABLE(){
   FILE_IS_TABLE="$TMP/is_table.tmp" ;
   echo "$IS_TABLE" > $FILE_IS_TABLE;
   HAS_TABLE=`echo "$NODEMAP" | $awk -F " " '
     BEGIN {
        HAS="" ;
     } {
       HAS=$2 ;
       COUNTER=0 ; 
       while (getline line < "'$FILE_IS_TABLE'" > 0) {
          if ( HAS == COUNTER && line != "") {
             print line ;
          } 
          COUNTER++ ;
       }
       close("'$FILE_IS_TABLE'");
     }' ` ;
  if [ $DEBUG == "TRUE" ]; then echo "HAS_TABLE : $HAS_TABLE" ; fi
}
#
# IS_TABLEに対応するCOLOR_TABLEの作成
# 入力: $NODEMAP ( 変数 ) # 出力: $COLOR_TABLE ( 変数 )
# COLOR_TABLE
#  color=blue,EXTERM:1.83,EDGE:0.383102
#  color=yellow,EXTERM:0,EDGE:0.971905
#  color=blue,EXTERM:0,EDGE:2.401455
#  NONE,EXTERM:0,EDGE:1.533620
#  color=green,EXTERM:6,EDGE:1.868122
#  NONE,EXTERM:0,EDGE:0.000000
#  NONE,EXTERM:0,EDGE:1.961707
#  color=green,EXTERM:3,EDGE:2.674352
#  ＊詳細
#   1:COLOR:色情報
#   2:EXTERM:重要語スコア
#   3:EDGE:係り受けスコア
#
# cabocha出力結果に対し、
# 地名／人名／組織／日付の場合はカラーコードを設定
#  B-LOCATION    (地域):"color=blue"
#  B-PERSON      (人名):"color=red"
#  B-ORGANIZATION(組織):"color=green"
#  B-DATE        (日付):"color=yellow"
#
function makeGraph.COLOR_TABLE(){
   COLOR_TABLE=`echo "$NODEMAP" | $awk -F " " '
      BEGIN{
         IS="" ;
         COLOR[0]="" ;
      } {
         IS=$1 ;
         #COLOR[IS]=$4;
         COLOR[IS]=$4 "," $5 "," $6 "," $1 "," $2;
      } {
      } END {
         for ( i=0; i<NR; i++){
           if ( COLOR[i] != "" ){
             print COLOR[i] ;
           }
         }
      }'` ;
  if [ $DEBUG == "TRUE" ]; then echo "COLOR_TABLE : $COLOR_TABLE" ; fi
}
#
# IS_TABLEの作成
# 入力: $NODEMAP ( 変数 ) # 出力: $IS_TABLE ( 変数 )
function makeGraph.IS_TABLE(){
   IS_TABLE=$( echo "$NODEMAP" | $awk -F " " '
      BEGIN{
         IS="" ;
         NAME[0]="" ;
      } {
         IS=$1 ;
         NAME[IS]=$3 ;
      } {
      } END {
         for ( i=0; i<NR; i++){
           if( NAME[i] != "" ){
             print "\"" NAME[i] "\"" ;
           }
         }
      }' ) ;
  if [ $DEBUG == "TRUE" ]; then echo "IS_TABLE : $IS_TABLE" ; fi
}
#
# cabochaコマンドで係り受け解析
# 入力: $CABOCHA ( 変数 ) # 出力: $NODEMAP ( 変数 )
function makeGraph.NODEMAP(){
  #重要語スコアを準備
  FILE_TERMEX="$TMP/termex.tmp" ;
  echo "$TERMEX" > "$FILE_TERMEX";
  #出力辞書データ cabochaの-f1オプションで出力
  #NODEMAP=`echo "$CABOCHA" | $awk '
  NODEMAP=$( echo "$CABOCHA" | awk '
    function ex_impr(str) {
      ex_score = 0 ;
      lARTERM=length(ARTERM) ;
      #for ( j = 0 ; j < length(ARTERM) ; j++ ) {
      for ( j = 0 ; j < lARTERM ; j++ ) {
        if (index(str, ARTERM[j]) > 0 ){
          #ex_score = ex_score + ARSCORE[j];
          ex_score += ARSCORE[j];
        }
      }
      close( "'$FILE_TERMEX'");
      return ex_score ;
    }
    BEGIN {
      NODE = "" ;
      NODE2 = "" ;
      LABEL = "" ;
      EDGE = "" ;
      x = 0 ;
      i = 0;
      while ( getline termex < "'$FILE_TERMEX'" > 0 ) {
        split(termex, TERM, ",") ;
        ARTERM[i]  = TERM[1];
        ARSCORE[i] = TERM[2];
        i++ ;
      }
      close( "'$FILE_TERMEX'");
    } {
      #* 0 6D 5/6 0.383100 行頭が*ではじまっている
      if ( $0 ~ /^\*/ ){
      #*があるたびに書き出しちゃう
        if ( NODE != "" ) {
          EXSCORE = "EXTERM:" ex_impr(LABEL);
          ##NODEMAP_LIST[x] = NODE " " LABEL ;
          if ( COLOR == "" ){
            # 色設定されていない場合
            # 明示的に「NONE」を指定
            COLOR = "NONE" ;
          }
          if ( LABEL == "" ){
            LABEL = "  " ;
          }
          ##NODEMAP_LIST[x] = NODE " " LABEL " " COLOR;
          NODEMAP_LIST[x] = NODE " " LABEL " " COLOR " " EXSCORE " " EDGE;
          x++ ;
          NODE = "" ; 
          LABEL = "" ;   
          COLOR = "" ;
        }
        #ノードをパースして出力
        gsub ( /D$/, "", $3) ;
        NODE = $2 " " $3 ;
        EDGE = "EDGE:" $5 ;
      } else if ( $0 ~ /^EOS/ )  {
        # ページ最後尾にEOS文字列があるのでこのタイミングで最終を出力
        EXSCORE = "EXTERM:" ex_impr(LABEL);
        if ( COLOR == "" ){
          COLOR = "NONE" ;
        }
        if ( LABEL == "" ){
          LABEL = "  " ;
        }
        #NODEMAP_LIST[x]  = NODE " " LABEL ;      
        #NODEMAP_LIST[x]  = NODE " " LABEL " " COLOR;      
        NODEMAP_LIST[x]  = NODE " " LABEL " " COLOR " " EXSCORE " " EDGE;
        x++ ;
      } else if ( $0 ~ /名詞/ ||  /助詞/ || /形容詞/ || /動詞/ || /記号/) {
        if ( $0 ~ /読点/ || /句点/ || /空白/ ) {
          next ; 
      }else{
          
        LABEL = LABEL "" $1 ; 
        #
        # 地域／人名／組織  の分類の場合、
        # 色設定を行う
        split($2, hinshi, ",");
        if (index(hinshi[2], "地名") > 0 ){ # 地域
          COLOR="color=blue" ;
        }else if (index(hinshi[2], "人名") > 0 ){ # 人名
          COLOR="color=red" ;
        }else if (index(hinshi[2], "組織名") > 0 ){ # 組織
          COLOR="color=green" ;
        }else if ( $3 == "B-DATE" || $3 == "I-DATE" ){ # 組織
          COLOR="color=brown" ;
        }
      }
    }
  } END {
    for ( i=0; i <= NR ; i++ ) {
      if ( NODEMAP_LIST[i] != ""){
        print NODEMAP_LIST[i] ; 
      }
    }
  } ' ) ;
  if [ $DEBUG == "TRUE" ]; then echo "NODEMAP : $NODEMAP" ; fi
}
#
# 用語と頻度の対応表（変数）からタグを抜いてcsv形式にする
# 入力: $TERM_EXTRACT_RESULT_LINE ( 変数 ) # 出力: $TERMEX ( 変数 )
function makeGraph.TERMEX(){
    TERMEX=$( echo "$TERM_EXTRACT_RESULT_LINE" | $awk ' {
       gsub ( /<\/KEY>/, "</KEY>\n", $0) ;
       gsub ( /<KEY>/,  "", $0) ;
       gsub ( /<SCORE>/, ",", $0) ;
       gsub ( /<\/SCORE><\/KEY>/, "", $0) ;
       if ( $0 != "" ) {
         print $0 ;
       }
    }')  ;
  if [ $DEBUG == "TRUE" ]; then echo "TERMEX : $TERMEX" ; fi
}
#
##########################################################
# グラフの生成
##########################################################
#
function makeGraph(){
    makeGraph.TERMEX ;
    makeGraph.NODEMAP ;
    makeGraph.IS_TABLE ;
    makeGraph.COLOR_TABLE ;
    makeGraph.HAS_TABLE ;
    makeGraph.HASCOLOR_TABLE ;
    makeGraph.IS_HAS_TABLE ;
    makeGraph.IS_TABLE_FIN ;
    makeGraph.HAS_TABLE_FIN ;
    makeGraph.JUUYOU_LINE ;
}
#
#
###############################################################
#  評価表現抽出
###############################################################
#
#<>func_Color_ExtractOpinions
#評価タイプの種類ごとにルートへ色を付ける（awk）
#入力１：IS_HAS_TABLE（変数）
#入力２：HTML_EXTRACT_OPINIONS_RESULT_LINE（変数）
#出力１：IS_HAS_TABLE（変数、入力値を書き換えて出力とする）
#
function opinionExtract.IS_HAS_TABLE(){
  HEORL=`echo "$HTML_EXTRACT_OPINIONS_RESULT_LINE" |tr "\n" "|"`;
  IS_HAS_TABLE=`echo "$IS_HAS_TABLE" | $awk -v HEORL="$HEORL" '
  {
    output = $0;
    sahen = $0;
    gsub(/\"/, "", sahen);
    gsub(/->.*$/, "", sahen);
    uhen = $0;
    gsub(/^.*->\"/, "", uhen);
    gsub(/\" \[.*$/, "", uhen);
    n = split( HEORL, arrHEORL, "|");
    for(i = 1; i <= n; i++)
      if ( index(arrHEORL[i], sahen) != 0 && index(arrHEORL[i], uhen) != 0 ){
        if ( index(arrHEORL[i], "感情") != 0 ){
          gsub(/]$/, " color=\"#d84a38\"]", output);          
        }else if ( index(arrHEORL[i], "批評") != 0 ){
          gsub(/]$/, " color=\"#35aa47\"]", output);          
        }else if ( index(arrHEORL[i], "メリット") != 0 ){
          gsub(/]$/, " color=\"#4d90fe\"]", output);          
        }else if ( index(arrHEORL[i], "採否") != 0 ){
          gsub(/]$/, " color=\"#cc00cc\"]", output);          
        }else if ( index(arrHEORL[i], "出来事") != 0 ){
          gsub(/]$/, " color=\"#faa937\"]", output);          
        }else if ( index(arrHEORL[i], "当為") != 0 ){
          gsub(/]$/, " color=\"#5bc0de\"]", output);          
        }else if ( index(arrHEORL[i], "要望") != 0 ){
          gsub(/]$/, " color=\"#5bc0de\"]", output);          
        }
      }
      print output;
    }'`;
  if [ $DEBUG == "TRUE" ]; then echo "IS_HAS_TABLE : $IS_HAS_TABLE" ; fi
}
#
# tsv2out.plをシェル（awk）化して関数化
# TSV変換されたKNP処理結果を標準出力する
# 入力：$EXOPINIONS_TMP ( 変数 ) TSV形式のKNP処理結果 ＊EUC
# 出力：$HTML_EXTRACT_OPINIONS_RESULT_LINE ( 変数 ) 出力形式へ変換した処理結果 ＊UTF8
# 
function opinionExtract.tsv2out(){
  EXOPINIONS_RESULT_LINE=$(echo "$EXOPINIONS_TMP" | $awk -F"\t" '{ print  $3 "\t" $4 "\t" $7 "\t" $9 "\t" $8 }' | nkf -wLu  | LANG=C grep -i "\[" | sed -e "s/^.*\[/\[/g");
  HTML_EXTRACT_OPINIONS_RESULT_LINE="<EX_OPINIONS><![CDATA[$EXOPINIONS_RESULT_LINE]]></EX_OPINIONS>" ; 
  if [ $DEBUG == "TRUE" ]; then echo "EXOPINIONS_RESULT_LINE : $EXOPINIONS_RESULT_LINE" ; fi
}
#
#<> func_pol_extract
# pol/extract.shを関数化
# 隠れ変数を持つ条件付き確率場を用いた評価極性分類を行う
#
# 入力：$polmdlfile
# 入力：$intsvfile(ファイル) ＊TSV変換したSVM処理結果
# 出力：TSV変換した極性分類処理結果(標準出力)
#
#  tsv2par.awk: tsv形式をpar形式に変換する
#  par2dat.awk: par形式をdat形式に変換する
#  out2tsv.awk: プログラムの出力をtsv形式に変換する
#
function func_pol_extract(){
  if [ "$#" -ne 2 ]
  then 
    echo "usage: $0 <*.mdl> <*.tsv> > <*.tsv>" 2>&1
    exit 1
  fi
  #local dir=`dirname $0`
  local dir=${EXOPPOL:-.}
  local tmp=${TMPDIR:-.}
  local exlib=${EXOPLIB:-.}
  local mdlfile=$1
  local tsvfile=$2
  local datfile=$tmp/test.$$.dat
  local outfile=$tmp/test.$$.out
  #20151027
  $dir/out2tsv.awk -f $exlib/utility.awk -v SCRIPT=$dir/out2tsv.awk $tsvfile $($dir/tsv2par.awk -f $exlib/utility.awk -v SCRIPT=$dir/tsv2par.awk $tsvfile | $dir/par2dat.awk -f $exlib/utility.awk -v SCRIPT=$dir/par2dat.awk $dictionary/dictionary.dic $dictionary/reverse.dic | $dir/lsm_classify $mdlfile) ;
#  $dir/tsv2par.awk -f $exlib/utility.awk -v SCRIPT=$dir/tsv2par.awk $tsvfile | $dir/par2dat.awk -f $exlib/utility.awk -v SCRIPT=$dir/par2dat.awk $dictionary/dictionary.dic $dictionary/reverse.dic | $dir/lsm_classify $mdlfile > $outfile 2> /dev/null
#  $dir/out2tsv.awk -f $exlib/utility.awk -v SCRIPT=$dir/out2tsv.awk $tsvfile $outfile
#
#  rm -f $outfile
}
#
#<> func_typ_extract
# typ/extract.shを関数化
# SVMにpairwise法を適用して，評価タイプの分類を行う
# 
# 入力１：$typftfile
# 入力２：$typmdlfile
# 入力３：TSV変換したCRF++の出力結果(ファイル)
# 出力  ：TSV変換したSVM処理結果(標準出力)
#
#   tsvconv.awk: tsvファイルから必要な情報だけを取り出す
#   makefv.awk : SVM用の素性ベクトルを作る
#   out2tsv.awk: SVMの出力をtsv形式に変換する
#
function func_typ_extract(){
    if [ "$#" -ne 3 ]
    then
      #echo "usage: test.sh <*.ft> <*.mdl> <*.tsv> > <*.tsv>" 1>&2
      exit 1
    fi
    #local dir=`dirname $0`
    local dir=${EXOPTYP:-.}
    local tmp=${TMPDIR:-.}
    local exlib=${EXOPLIB:-.}
    local ftfile=$1
    local mdlfile=$2
    local tsvfile=$3
    local fvfile=$tmp/test.$$.fv
    local svfile=$tmp/test.$$.sv
    local outfile=$tmp/test.$$.out
    $dir/tsvconv.awk -f $exlib/utility.awk -v SCRIPT=$dir/tsvconv.awk $tsvfile | \
      $dir/makefv.awk -f $exlib/utility.awk -v SCRIPT=$dir/makefv.awk | \
      $dir/../svmtools/svm_fv2sv $ftfile > $svfile
    $dir/../svmtools/svm_mc_classify $svfile $mdlfile $outfile > /dev/null 2>&1
    $dir/out2tsv.awk -f $exlib/utility.awk -v SCRIPT=$dir/out2tsv.awk $tsvfile $outfile
    rm -f $svfile $outfile
}
#
#<> func_svmtest
# src/svmtest.shを関数化
# 保持者と著者が同一かをSVMで判定するテスト用スクリプト
#
# 入力１：$ftfile(ファイル) ＊モデルファイル名:$1.src_ft
# 入力２：$svmmdlfile(ファイル) ＊モデルファイル名:$1.src_svmmdl
# 入力３：$tsvfile(ファイル) ＊XPR形式ファイル名
# 出力  ：tsv形式に変換したSVMの処理結果(標準出力)
#
function func_svmtest(){
    if [ "$#" -ne 3 ]; then
      #echo "usage: svmtest.sh <*.ft> <*.svmmdl> <*.tsv> > <*.tsv>" 1>&2
      exit 1
    fi
    #local dir=`dirname $0`
    local dir=${EXOPSRC:-}
    local tmp=${TMPDIR:-.}
    local exlib=${EXOPLIB:-.}
    local ftfile=$1
    local mdlfile=$2
    local tsvfile=$3
    local fvfile=$tmp/svmtest.$$.fv
    local fvfile0=$tmp/svmtest.$$.fv0
    local svfile=$tmp/svmtest.$$.sv
    local outfile=$tmp/svmtest.$$.out
    $dir/tsvconv.awk -f $exlib/utility.awk -v SCRIPT=$dir/tsvconv.awk $tsvfile|$dir/makefv.awk -f $exlib/utility.awk -v SCRIPT=$dir/makefv.awk|$dir/../svmtools/svm_fv2sv $ftfile > $svfile
    $dir/../svmtools/svm_classify $svfile $mdlfile $outfile > /dev/null 2>&1
    $dir/out2tsv.awk -f $exlib/utility.awk -v SCRIPT=$dir/out2tsv.awk $tsvfile $outfile
    rm -f $svfile $outfile
}
#
#<> func_crftest
# src/crftest.shを関数化
# 保持者をCRFで文中から抽出する訓練用スクリプト
# 入力１：$crfmdlfile(ファイル) ＊モデルファイル名:$1.src_crfmdl
# 入力２：$tmptsvfile(ファイル) ＊一時出力結果格納ファイル名
# 出力  ：tsv変換したCRF++の出力結果(標準出力)
#
function func_crftest(){
    crf_test=crf_test
    if [ "$#" -ne 2 ]
    then
      #echo "usage: crftest.sh <*.crfmdl> <*.tsv>" 1>&2
      exit 1
    fi
    #local dir=`dirname $0`
    local dir=${EXOPSRC:-}
    local tmp=${TMPDIR:-.}
    local exlib=${EXOPLIB:-.}
    local mdlfile=$1
    local tsvfile=$2
    local tagfile=$tmp/crftrain.$$.tag
    local otagfile=$tmp/crftrain.$$.otag
    #20151027
#    $dir/tsv2tag.awk -f $exlib/utility.awk -v SCRIPT=$dir/tsv2tag.awk $tsvfile|$crf_test -m $mdlfile > $otagfile
    $dir/otag2tsv.awk -f $exlib/utility.awk -v SCRIPT=$dir/otag2tsv.awk $tsvfile $($dir/tsv2tag.awk -f $exlib/utility.awk -v SCRIPT=$dir/tsv2tag.awk $tsvfile|$crf_test -m $mdlfile);
#    $dir/tsv2tag.awk -f $exlib/utility.awk -v SCRIPT=$dir/tsv2tag.awk $tsvfile|$crf_test -m $mdlfile > $otagfile
#    $dir/otag2tsv.awk -f $exlib/utility.awk -v SCRIPT=$dir/otag2tsv.awk $tsvfile $otagfile
#
#    rm -f $otagfile
}
#
#<> func_src_extract
# src/extract.shを関数化
# 評価表現が同定された後で，評価保持者を抽出する
# はじめにSVMを用いて評価保持者が著者であるかどうかを判定し，
# もし著者でないと判定された場合はCRFを用いて著者と
# 思われる文字列を抽出する
# 抽出できなかった場合は保持者は不定とする
#
# 入力１：$srcftfile (モデルファイル名:$1.src_ft)
# 入力２：$srcsvmmdlfile(モデルファイル名:$1.src_svmmdl)
# 入力３：$srccrfmdlfile(モデルファイル名:$1.src_crfmdl)
# 入力４：$intsvfile(XPR形式ファイル名)
# 出力  ：tsv変換したCRF++の出力結果(標準出力)
#
function func_src_extract(){
    if [ $# -ne 4 ]
    then
      #echo "usage: test.sh <*.ft> <*.svmmdl> <*.crfmdl> <*.tsv>" 1>&2
      exit 1
    fi
    local dir=${EXOPSRC:-}
    local tmp=${TMPDIR:-.}
    local ftfile=$1
    local svmmdlfile=$2
    local crfmdlfile=$3
    local tsvfile=$4
    local tmptsvfile=$tmp/test.$$.tsv
    func_crftest $crfmdlfile $(func_svmtest $ftfile $svmmdlfile $tsvfile );
}
#
#<> func_xpr_tsv2tag
# xpr/tsv2tag.awkを関数化
# *.tsv形式のデータをCRF++の入力フォーマットに変換する
# 評価表現がオーバーラップする場合最初に書かれた評価表現を優先
#
# 入力１：評価極性辞書(ファイル)
# 入力２：変換対称TSV(ファイル)
# 出力  ：CRF++用の入力文字列(標準出力)
#
function func_xpr_tsv2tag (){
    DIC="$1" ;
    TSV_FILE="$2" ;
    #xpr_tag=`awk -f $exlib/utility.awk -f - -v SCRIPT=$dir/tsv2tag.awk << 'EOF' "$DIC" "$TSV_FILE" 
    $awk -f $exlib/utility.awk -f - -v SCRIPT=$dir/tsv2tag.awk << 'EOF' "$DIC" "$TSV_FILE" 
        BEGIN {
          FS = "\t";
          if (ARGC < 2) {
            printf "usage: %s <dictionary> [<*.tsv>]\n", SCRIPT > "/dev/stderr";
            EXIT = 1;
            exit EXIT;
          }
          dicfile = ARGV[1];
          ARGV[1] = "";
          # 辞書の読み込み(w/ 形態素解析)+トライに格納
          ndic = dicread(dicfile, dicw, dicp, trie_flg, trie_val);
        } {
        #処理行数をカウント
          nlines++;
          sen = $5;
          xprall = $8;
          mrp = $10;
          nxpr = split(xprall, xprelem, /\\n/);
          n = ma(mrp, surf, base, cpos, fpos);
          # 極性タグ付与(trie探索)
          for (i = 1; i <= n; i++) pole[i] = "*";
          nlist = lookup(n, base, 1, n, trie_flg, trie_val, listv, listb, listl);
          for (i = 0; i < nlist; i++) {
            for (j = 0; j <= listl[i]; j++) {
              pole[listb[i] + j] = dicp[listv[i]];
            }
          }
          # BIOタグ付け
          for (i = 1; i <= n; i++) tag[i] = "O";
          for (z = 1; z <= nxpr; z++) {
            xpr = xprelem[z];
            p = position(sen, n, surf, xpr, 0);
            if (p == -1) {
                showError("xpr !in sen");
                printf " = Line:%d\n", nlines > "/dev/stderr";
                continue;
             }
            if (tag[PSTART] != "O" || tag[PEND] != "O") continue;
            tag[PSTART] = "B";
            for (i = PSTART + 1; i <= PEND; i++) tag[i] = "I";
          }
          # データ出力
          for (i = 1; i <= n; i++) {
            printf "%s\t%s\t%s\t%s\t%s\t%s\n", surf[i], base[i], cpos[i], fpos[i], pole[i], tag[i];
          }
          printf "\n";
        }
EOF
#`
#  echo "$xpr_tag" ;
  echo "" ; #元々の処理と出力を揃えるなら最後に空行を入れる
}
#
#<> func_xpr_otag2tsv
# xpr/otag2tsv.awkを関数化
# CRF++の出力をtsv形式に変換する
# ＊このファイルはEUC-JPで保存すること（ここまで原文コメント）
# $TSV_FILEと$OTAG_FILEがEUC-JPで、一部分だけこのawkで日本語置換し、他の部分はそのまま出力する
# すると１つのファイル中にEUC-JPで書かれた部分とUTF-8で書かれた部分が混在してしまい、正常に動作しない
# それを避けるために一旦どれもUTF-8で揃えてから処理し、最後の出力だけEUC-JPに変換（シェル移設コメント）
#
# 入力：TSV_FILE(ファイル)
# 入力：OTAG_DATA(変数) ＊CRF++用の入力データ
# 出力：TSV_U_FILE(ファイル) ＊入力ファイルをUTF変換
# 出力：TSV変換した処理結果(標準出力)
#
function func_xpr_otag2tsv(){
  TSV_FILE=$1 ;
  TSV_U_FILE=${TSV_FILE}.utf8
  cat "$TSV_FILE" | nkf -wLu > "$TSV_U_FILE" ;
  # 最終行マーク(===EOS===)を除去し、処理を行う
  xpr_tsv=`echo "$OTAG_DATA" | LANG=C grep -i -v "^===EOS===$" | \
           #$awk -f $exlib/utility.awk -v SCRIPT=$dir/otag2tsv.awk --source='  
           awk -f $exlib/utility.awk -v SCRIPT=$dir/otag2tsv.awk --source='  
    BEGIN {
      FS = "\t";
      OFS = "\t";
      if (ARGC < 2) {
        printf "usage: %s <*.tsv file> [<*.otag>]\n", SCRIPT > "/dev/stderr";
        EXIT = 1;
        exit EXIT;
      }
      tsvfile = ARGV[1];
      ARGV[1] = "";
      buf = "";
      cnt = 0;
      sen = "";
      extnum = 0;
    } {
      #処理行数をカウント
      nlines++;
      if (buf != "" && $7 != "I") {
        vec[cnt++] = buf;
        buf = "";
      }
      if ($0 == "") {
        extent[extnum] = "";
        for (i = 0; i < cnt; i++) extent[extnum] = extent[extnum] "\\n" vec[i];
        # 頭の改行除去。euc-jpだったら3文字分削る。utf-8だったら2文字分削る
        #extent[extnum] = substr(extent[extnum], 3);
        extent[extnum] = substr(extent[extnum], 2); 
        extsen[extnum] = sen;
        extnum++;
        cnt = 0;
        sen = "";
      } else {
        if ($7 == "B") buf = $1;
        if ($7 == "I") buf = buf $1;
        sen = sen $1;
      }
    } END {
      if (EXIT != "") exit EXIT;
      for (y = 0; ; ) {
        r = getline < tsvfile;
        if (r == 0) break;
        if (r < 0) error("file I/O error");
        if (extsen[y] != $5) {
          showError("sentence mismatch");
          printf " = Line:%d\n", nlines > "/dev/stderr";
        }
        if (extent[y] == "") {
          $6 = "";
          $7 = "";
          $8 = "";
          $9 = "";
        } else {
          tmp = extent[y];
          gsub(/\\n/, "\t", tmp);
          gsub(/[^\t]+/, "+1", tmp);
          gsub(/\t/, "\\n", tmp);
          $6 = tmp;
          tmp = extent[y];
          gsub(/\\n/, "\t", tmp);
          gsub(/[^\t]+/, "[著者]", tmp);
          gsub(/\t/, "\\n", tmp);
          $7 = tmp;
          $8 = extent[y];
          tmp = extent[y];
          gsub(/\\n/, "\t", tmp);
          gsub(/[^\t]+/, "当為", tmp);
          gsub(/\t/, "\\n", tmp);
          $9 = tmp;
        }
        y++;
        print;
      }
      if (y != extnum) error("#entities mismatch");
    } ' "$TSV_U_FILE" ` ;
  echo "$xpr_tsv"| nkf -We ; 
}
#
#<> func_xpr_extract
# ＊xpr/extract.shを関数化
#   CRFを用いて入力文から評価表現を抽出する．
#   手法や素性については，参考文献を参照．
#   参考文献
#  Tetsuji Nakagawa, Takuya Kawada, Kentaro Inui, Sadao Kurohashi: Extracting
#  Subjective and Objective Evaluative Expressions from the Web, In Proceedings
#  of the Second International Symposium on Universal Communication, pp.251-258,
#  December 2008.
#
# 入力：TSV形式ファイル（ファイル名）
# 出力：XPR形式ファイル(標準出力)
#
function func_xpr_extract(){
    crf_test=/usr/local/bin/crf_test ;
    if [ "$#" -ne 2 ]; then
      #echo "usage: test.sh <*.mdl> <*.tsv>" 1>&2
      exit 1
    fi
    #local dir=`dirname $0`
    local dir=${EXOPXPR:-.}
    local tmp=${TMPDIR:-.}
    local exlib=${EXOPLIB:-.}
    local mdlfile=$1
    local tsvfile=$2
    local tagfile=$tmp/train.$$.tag
    local otagfile=$tmp/train.$$.otag
    # awk外部ファイル内部化対応後
    OTAG_DATA=`func_xpr_tsv2tag $dictionary/dictionary.dic $tsvfile | \
               $crf_test -m $mdlfile  | \
               nkf -wLu && echo "===EOS===" `
               # 最後の空行もOTAG_DATA変数に含めるため、
               # crf_test実行後に最終行マークを付与
               # ＊最後の空行は大事
               #   func_xpr_otag2tsv では、空行を処理の基準としている
    func_xpr_otag2tsv $tsvfile
}
#
#<> func_Extract_Opinions
#  評価表現抽出文書の評価を行う
# juman/knpを利用し、文章の分析／分類を行う
#
# TSV形式のKNP結果へ以下の処理を行う
#  func_xpr_extract:評価表現を抽出する
#  func_src_extract:評価保持者を抽出する
#  func_typ_extract:評価タイプの分類を行う
#  func_pol_extract:評価極性分類を行う
#
# 入力１：$model モデルファイル（ファイル）
# 入力２：$EXOP_TSV ( 変数 ) TSV形式の処理文章
#         ＊TSV変換したKNP処理結果
# 出力  ：$EXOPINIONS_TMP ( 変数 ) TSV変換した処理結果
#
function opinionExtract.Extract_Opinions(){
  #func_extract ;
    # この関数で必要な環境変数定義
    LANG_BAK=$LANG;
    LC_ALL_BAK=$LC_ALL;
    export LANG=C
    export LC_ALL=C
    dir=`cd $(dirname $0) && pwd`
    tmp=${TMPDIR:-.}
    xprmdlfile=$model".xpr_mdl"
    srcftfile=$model".src_ft"
    srcsvmmdlfile=$model".src_svmmdl"
    srccrfmdlfile=$model".src_crfmdl"
    typftfile=$model".typ_ft"
    typmdlfile=$model".typ_mdl"
    polmdlfile=$model".pol_mdl"
    #scrftfile=$model".scr_ft"
    #scrmdlfile=$model".scr_mdl"
    intsvfile=$tmp/test.$$.intsv
    outtsvfile=$tmp/test.$$.outtsv
    #cp $tsvfile $intsvfile
    echo "$EXOP_TSV" | nkf -e > $intsvfile ;
    #外部スクリプトを同じファイル内の関数に変更
    #
    #関数呼び出し
    func_xpr_extract $xprmdlfile $intsvfile > $outtsvfile
    #cp $outtsvfile $intsvfile
    #
    #関数呼び出し
    #func_src_extract $srcftfile $srcsvmmdlfile $srccrfmdlfile $intsvfile > $outtsvfile
    cp $outtsvfile $intsvfile
    #
    #関数呼び出し
    func_typ_extract $typftfile $typmdlfile $intsvfile > $outtsvfile
    #cp $outtsvfile $intsvfile
    #
    #関数呼び出し
    #func_pol_extract $polmdlfile $intsvfile > $outtsvfile
    EXOPINIONS_TMP=`cat $outtsvfile` ;
    #FINAL
    rm -f $intsvfile $outtsvfile
    # この関数で変えた環境変数を元に戻す
    export LANG=$LANG_BAK;
    export LC_ALL=$LC_ALL_BAK ;
    if [ $DEBUG == "TRUE" ]; then echo "EXOPINIONS_TMP : $EXOPINIONS_TMP" ; fi
}
#
# <> func_tsvKakariuke
# 係り受けのデータをTSV形式に変換
#
# 入力: $KAKARIUKE_TMP( 変数 )
# 出力: $EXOP_TSV ( 変数 )
#
function opinionExtract.EXOP_TSV(){
  EXOP_TSV=$(echo "$KAKARIUKE_TMP" | $awk -F "|" ' BEGIN{
      documentID="exop_desc" ;
      lineCount=0 ;
      knpresult="";
      execsts=""; 
    }{
      ## セパレータ（｜）を分割し、それぞれの値を取得
      execsts = $1 ;
      sentence= $2 ;
      knpresult= $3 ;
      id++ ;
      sampleID = id;   
      sentenceID = id; 
      # mawkではswitch-case文不可
      if ( execsts == 1 ){
          checkTSV="0" ; ### 実装完了まで、仮値設定
                         ### しかしながら、checkTSV
                         ### は、現段階では未実装のまま
          if ( checkTSV == -1 ) {
            # エラー行数表示
            # printf STDERR " = Line:%d\n", $id; 
          }
          # 内容のコメントはシェル版参照
          printf  "%s\t%s\t%s\t%s\t%s\t\t\t\t\t%s\t\n",topic,sampleID,documentID,sentenceID,sentence,knpresult
          sampleID++;
      }else if (execsts == 0 ){
          printf "\t%s\t%s\t%s\t空白文\t\t\t\t\t空白_文:空白だ_文:形容詞_名詞:*_普通名詞\t3:0:D\t\t空白/くうはくa_文/ぶん\n",sampleID,documentID,sentenceID;
      }else if (execsts == -1 ){
      }else{
          printf "\t%s\t%s\t%s\t空白文\t\t\t\t\t空白_文:空白だ_文:形容詞_名詞:*_普通名詞\t3:0:D\t\t空白/くうはくa_文/ぶん\n",sampleID,documentID,sentenceID;
      }
    }
  '
  );
  if [ $DEBUG == "TRUE" ]; then echo "EXOP_TSV : $EXOP_TSV" ; fi
}
#
# jumanとknpでやっていたことを、cabocha(mecab)の処理とawkの整形で実装。
# 入力値は1行が長すぎると処理が重くなるので、句点単位で改行した文章。
# cabochaの結果としては、以下のようになる
#
# 入力  ：$CABOCHAEOS (複数行,変数)
# 出力  ：$TSV_KAKARIUKE (変数, 以下詳細)
# 出力1 ：execsts
#          1 : 正常
#          0 : 結果なし
#         -1 : ERROR
# 出力2 ：sentence (単一行)
#         ex)早大３連覇
# 出力3 ：knpresult
#         ex)早大_３_連覇:早大_３_連覇:名詞_名詞_名詞:組織名_数詞_サ変名詞 2_4:2_0:D_D
# ＊出力１〜３をパイプ（｜）区切りで返却する
#
function opinionExtract.KAKARIUKE_TMP(){
  KAKARIUKE_TMP=$(echo "$CABOCHAEOS"| $awk '
  BEGIN{
      count=1;
      surface="";
      parts="";
      parts_detail="";
      clauseno="";
      charno="";
      has="";
      depend="";
      sentence="0";
      wordcnt="0";
  }{
    if ( $0 ~ /^\*/ ) {
      cln = $2 ;
      hs = $3 ;
      gsub ( /D/, "", hs);
      if ( clauseno == "" ){
        clauseno = cln ;
      } else {
        clauseno = clauseno "_" cln ;
      }
      if ( has == "" ){
        has = hs ;
      } else {
        has = has "_" hs ;
      }
      wordcnt++ ;
      if ( count == 0 ) { next ; }
      if ( charno == "" ){
        charno = count ;
      } else {
        charno = charno "_" count ;
      }
    } else if ( $0 ~ /EOS/ ) {
      sentence = 1;
      words = surface ;
      gsub ( /_/, "", words );
      for ( i = 1; i <= wordcnt; i++){
        if ( i == 1 ) {
          dcnt = "D";
        }else{
          dcnt = dcnt "_D" ;
        }
      } # for i end
      gsub ( /-1/, "0", has) ;
      gsub ( /^1_/, "", charno);
      charno = charno "_" count ;
      result = sentence "|" words "|" surface ":" surface2 ":" parts ":" parts_detail "	" charno ":" has ":" dcnt ;
      results=results "\n" result;
      clauseno="";
      charno="";
      has="";
      surface="";
      surface2="";
      parts="";
      parts_detail="";
      count="1";
      wordcnt="0";
      dcnt="";
    } else {
      sf = $1;
      split($2, sf_arr, ",");
      ps = sf_arr[1];
      psd = sf_arr[2];
      sf2 = sf_arr[5] ;
      if ( surface == "" ){
        surface = sf ;
      } else {
        surface = surface "_" sf ;
      }
      if ( sf2 == "*" ) {
        sf2 = sf ;
      }
      if ( surface2 == "" ){
        surface2 = sf2 ;
      } else {
        surface2 = surface2 "_" sf2 ;
      }
      if ( parts == "" ){
        parts = ps ;
      } else {
        parts = parts "_" ps ;
      }
      if ( parts_detail == "" ){
        parts_detail = psd ;
      } else {
        parts_detail = parts_detail "_" psd ;
      }
      count++ ;
    }
  }END{
    if ( results != "" ) {print results };
  }' ) ;
  #if [ $DEBUG == "TRUE" ]; then echo "KAKARIUKE_TMP : $KAKARIUKE_TMP" ; fi
}
#
#graphVizで使用するcabocha処理は全文を一続きに扱っている。
#extractopinionでは「。」区切りで処理を分ける必要があるので
#cabochaの実行結果を編集し、「。」の後ろの行にEOSをつける
#
# 入力: $CABOCHA ( 変数 ) # 出力: $CABOCAEOS ( 変数 )
function opinionExtract.CABOCHAEOS(){
  CABOCHAEOS=`echo "$CABOCHA"| $awk '{
   if (  $0 ~ /EOS/ ){ 
    next; 
   }
   print $0;
   if (  $0 ~ /^。/ ){ 
     print "EOS";
   }
  }'`;
  if [ $DEBUG == "TRUE" ]; then echo "CABOCHAEOS : $CABOCHAEOS" ; fi
}
#
function opinionExtract(){
    opinionExtract.CABOCHAEOS;           #意見評価 cabochaの実行結果に「。」区切りでeosをつける
    opinionExtract.KAKARIUKE_TMP ;
    opinionExtract.EXOP_TSV ;
    opinionExtract.Extract_Opinions ;
    opinionExtract.tsv2out;
    opinionExtract.IS_HAS_TABLE ;
}
#
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
#
###############################################################
# 出力
###############################################################
#
#<> func_print
# XML出力
#
function print.XML(){
  SUMMARY_RESULT_LINE=$( echo "$SUMMARY_RESULT_LINE"|sed -e "s|</SUMMARY>||" -e "s|<SUMMARY_RATIO>|</SUMMARY><SUMMARY_RATIO>|" );
cat <<- EOF 
Content-Type: text/html;charset=utf-8
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<result>
<TITLE>$TITLE</TITLE>
<DESCRIPTION>$DESCRIPTION</DESCRIPTION>
$KEYS_RESULT_LINE
$NAME_RESULT_LINE
$GEO_RESULT_LINE
$ORG_RESULT_LINE
$SUMMARY_RESULT_LINE
$HTML_EXTRACT_OPINIONS_RESULT_LINE
EOF
}
#
#<> func_print_html
# HTML出力
#
function print.HTML(){
  IS_HAS_TABLE_FIN=$( echo -e "$IS_TABLE_FIN\n$HAS_TABLE_FIN" | LANG=C sort -s -k1 -u | sed "s/<BR>/\\n/g" ) ;
  DOTMAP=$( echo -e "$IS_HAS_TABLE_FIN\n$IS_HAS_TABLE" )  ;

cat <<- EOS > index.html 
<html><head><meta charset="utf-8"><body>
<script type="text/vnd.graphviz" id="cluster">
  digraph G {
    size="500, 500";
    node [fontname=mincho fontsize=14 shape=plaintext,width=.1,height=.1 ];
    subgraph cluster_summary {
      style=filled;
      color=lightgrey;
      edge [color=lightgrey];
      $JUUYOU_LINE
      label = "summary";
  }
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

  if [ $DEBUG == "TRUE" ]; then cat index.html; fi

}
#
function printOut(){
  print.XML ;
  print.HTML ;
}
#
#
###############################################################
# メイン
###############################################################
#
#デバッグモード
#DEBUG="TRUE" ;
DEBUG="FALSE" ;
#
function Main(){
  source config ;               #コンフィグファイル読み込み
  source lib/parse.sh ; 
  parse ;                       #パラメータ処理
  source lib/termExtract.sh ;
  source lib/calcImp.sh ; 
  termExtract ;                 #重要語解析
  source lib/mecabExtract.sh
  mecabExtract ;                #形態素解析(人名地名組織名の抽出）
  source lib/cabochaExtract.sh ;
  cabochaExtract ;              #構文解析
  source lib/makeGraph.sh ;
  makeGraph ;                   #グラフの生成 
  source lib/opinionExtract.sh ;
  opinionExtract ;              #評価表現の抽出
  source lib/summaryExtract.sh ;
  summaryExtract ;              #要約の抽出
  source lib/print.sh ;         #出力
  printOut ;
}
Main ;
exit ;
