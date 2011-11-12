debug='false'
if [ -n "$1" ]; then debug='true'; fi
mxmlc -default-background-color=#FFFFFF -default-frame-rate=24 -default-size 760 590 -target-player=10.0.0 -compiler.debug=${debug} -use-network=true -benchmark=true -optimize=true -output=Arrow.swf Arrow.as

mxmlc -default-background-color=#FFFFFF -default-frame-rate=24 -default-size 760 590 -target-player=10.0.0 -compiler.debug=${debug} -use-network=true -benchmark=true -optimize=true -output=ArrowMail.swf ArrowMail.as

mxmlc -default-background-color=#FFFFFF -default-frame-rate=24 -default-size 760 590 -target-player=10.0.0 -compiler.debug=${debug} -use-network=true -benchmark=true -optimize=true -output=ArrowVK.swf ArrowVK.as
