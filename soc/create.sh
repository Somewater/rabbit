#!/bin/bash
compc -source-path "/home/pav/lab/soc" \
-include-classes "RProtector" \
-optimize \
-compiler.debug=false \
-target-player=10.0 \
-output "/home/pav/lab/soc/Social.swc"
#--keep-as3-metadata+=TypeHint,EditorData,Embed,ResourceType \
