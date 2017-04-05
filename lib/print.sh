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
$NPCATEGORY_RESULT_LINE
$SUMMARY_RESULT_LINE
$HTML_EXTRACT_OPINIONS_RESULT_LINE
EOF
}
#
function print.SVG(){
  IS_HAS_TABLE_FIN=$( echo -e "$IS_TABLE_FIN\n$HAS_TABLE_FIN" | LANG=C sort -s -k1 -u | sed "s/<BR>/\\n/g" ) ;
  DOTMAP=$( echo -e "$IS_HAS_TABLE_FIN\n$IS_HAS_TABLE" )  ;
cat <<- EOS > graph.dot
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
EOS

	dot -Tsvg -o graph.svg graph.dot ;	
  if [ $DEBUG == "TRUE" ]; then cat graph.dot; fi
}
#
#<> func_print_html
# HTML出力
#
function print.HTML(){
  IS_HAS_TABLE_FIN=$( echo -e "$IS_TABLE_FIN\n$HAS_TABLE_FIN" | LANG=C sort -s -k1 -u | sed "s/<BR>/\\n/g" ) ;
  DOTMAP=$( echo -e "$IS_HAS_TABLE_FIN\n$IS_HAS_TABLE" )  ;

cat <<- EOS > graph.html 
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
  print.SVG ;
}
#
