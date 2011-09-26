/*
fl.outputPanel.clear();
var lib = fl.getDocumentDOM().library;
lib.expandFolder(true,true,'Hint');
for (var o in lib.items) {
	var tar = fl.getDocumentDOM().library.items[o];
	if (tar.linkageExportForAS==true){
		//fl.trace(tar.name + " "  + tar.linkageClassName);
		if(tar.linkageClassName.indexOf("progrestar") != -1){
			fl.trace("com.prolite."+String(tar.linkageClassName).substr(15));
			tar.linkageClassName = "com.prolite."+String(tar.linkageClassName).substr(15);
		}else{
			fl.trace("####	" + tar.linkageClassName + "	###");
		}
		//tar.name = '';
		//tar.linkageClassName = '';
	}
}
*/

fl.outputPanel.clear();
var lib = fl.getDocumentDOM().library;
lib.expandFolder(true,true,'trash');
for (var o in lib.items) {
	var tar = fl.getDocumentDOM().library.items[o];
	tar.name = tar.name + "-"
}