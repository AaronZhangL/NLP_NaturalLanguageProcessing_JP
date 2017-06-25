#!/bin/bash

echo "title=早大３連覇　斎藤が１５奪三振、初完封　東京六大学野球&body=東京六大学野球秋季リーグは３０日、神宮球場で最終週の早大—慶大３回戦があり、早大が斎藤（１年、早稲田実）の活躍で慶大に７—０で大勝し、３季連続４０度目の優勝を果たした。勝ち点４で明大と並んだが、勝率で上回った。早大は１１月１０日開幕の明治神宮大会への出場も決めた。 　斎藤はスライダーやツーシームなどの変化球がさえ、リーグ戦初完封。被安打４で１５奪三振の力投で今季４勝目を挙げた。打線は１回、松本（３年、千葉経大付）の適時打と本田（４年、智弁和歌山）の３点二塁打で４点を先取し、その後も加点した。慶大は３連投のエース加藤幹（４年、川和）が力尽きた。&perMax=30&summaxLength=&printHTML=no&sports=no" > in ;

echo "#!/bin/bash" > run.sh ;
    cat README \
        config \
				lib/makeGoitaikei.sh \
        lib/parse.sh \
        lib/termExtract.sh \
        lib/calcImp.sh \
        lib/mecabExtract.sh \
        lib/cabochaExtract.sh \
        lib/makeGraph.sh \
        lib/opinionExtract.sh \
        lib/summaryExtract.sh \
        lib/getCategory.sh \
        lib/print.sh \
        lib/main.sh >> run.sh ;

chmod 755 run.sh ;
./run.sh < in ;

exit ;
