package com.somewater.common.util
{
	import com.somewater.common.factory.McFactory;
	
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	
	public class BuildEarth
	{
		private static var elemWidth:Number=70.7;
		
		public function BuildEarth():void
		{
			
		}
		public static function getEarth(xml:XML,assetName:String):MovieClip
		{
			var mapArray:Array = [];
			for (var i in xml.children()){
				mapArray[i] = new Array;
				for (var j in xml.children()[i].children()){
					mapArray[i][j]=xml.children()[i].children()[j];
				}
			}  
			return getEarthAtArray(mapArray,assetName);
		}
		/*
		old version good work vis recangle not romb
		public static function getEarthAtArray(array:Array,assetName:String):MovieClip
		{
			var map:MovieClip = new MovieClip();
			var mapArray:Array = array;
			
			 for (var i in mapArray){
				for (var j in mapArray[i]){
					if (mapArray[i][j]==1){
						var str:String='t';
						//check left
						if (j==0){
							str+='0';
						} else {
							if (mapArray[i][j-1]!=1)
								str+='0';
							else
								str+='1';
						}
						//check left-top
						if (j==0 || i==0){
							str+='0';
						} else {
							if (mapArray[i-1][j-1]!=1)
								str+='0';
							else
								str+='1';
						}
						//check top
						if (i==0){
							str+='0';
						}else {
							if (mapArray[i-1][j]!=1)
								str+='0';
							else
								str+='1';
						}
						//check top-right
						if (j==mapArray[i].length-1 || i==0){
							str+='0';
						}else {
							if (mapArray[i-1][j+1]!=1)
								str+='0';
							else
								str+='1';
						}
						//check right
						if (j==mapArray[i].length-1){
							str+='0';
						} else {
							if (mapArray[i][j+1]!=1)
								str+='0';
							else
								str+='1';
						}
						//check right-buttom
						if (j==mapArray[i].length-1 || i==mapArray.length-1){
							str+='0';
						} else {
							if (mapArray[i+1][j+1]!=1)
								str+='0';
							else
								str+='1';
						}
						//check buttom
						if (i==mapArray.length-1){
							str+='0';
						}else {	
							if (mapArray[i+1][j]!=1)
								str+='0';
							else
								str+='1';	
						}
						//check buttom-left
						if (i==mapArray.length-1 || j==0){
							str+='0';
						}else {	
							if (mapArray[i+1][j-1]!=1)
								str+='0';
							else
								str+='1';	
						}
						
						var mc:MovieClip=McFactory.createMc('tile',assetName);
						
						
						map.addChild(mc);
						mc.x=elemWidth*j;
						mc.y=elemWidth*i;
						
					}
				}
			}
			
			return map;
		}
		*/
		public static function getEarthAtArray(array:Array,assetName:String):MovieClip
		{
			var map:MovieClip = new MovieClip();
			var mapArray:Array = array;
			
			 for (var i in mapArray){
				for (var j in mapArray[i]){
					if (mapArray[i][j]==1){
						var str:String='t';
						//check left
						if (j==0){
							str+='0';
						} else {
							if (mapArray[i][j-1]!=1)
								str+='0';
							else
								str+='1';
						}
						//check left-top
						if (j==0 || i==0){
							str+='0';
						} else {
							if (mapArray[i-1][j-1]!=1)
								str+='0';
							else
								str+='1';
						}
						//check top
						if (i==0){
							str+='0';
						}else {
							if (mapArray[i-1][j]!=1)
								str+='0';
							else
								str+='1';
						}
						//check top-right
						if (j==mapArray[i].length-1 || i==0){
							str+='0';
						}else {
							if (mapArray[i-1][j+1]!=1)
								str+='0';
							else
								str+='1';
						}
						//check right
						if (j==mapArray[i].length-1){
							str+='0';
						} else {
							if (mapArray[i][j+1]!=1)
								str+='0';
							else
								str+='1';
						}
						//check right-buttom
						if (j==mapArray[i].length-1 || i==mapArray.length-1){
							str+='0';
						} else {
							if (mapArray[i+1][j+1]!=1)
								str+='0';
							else
								str+='1';
						}
						//check buttom
						if (i==mapArray.length-1){
							str+='0';
						}else {	
							if (mapArray[i+1][j]!=1)
								str+='0';
							else
								str+='1';	
						}
						//check buttom-left
						if (i==mapArray.length-1 || j==0){
							str+='0';
						}else {	
							if (mapArray[i+1][j-1]!=1)
								str+='0';
							else
								str+='1';	
						}
						
						//var bd:Bitmap=new Bitmap(McFactory.createBitmapData('tiletile',assetName,50,25.5));
						//map=AddToMap(i,j,'tile',assetName);
						//map.addChild(bd);
						//bd.x=bd.width/2*j+bd.width/2*(15-i)-bd.width/2;
						//bd.y=bd.height/2*j+i*bd.height/2;
						/*1111
						var mc=McFactory.createMc(str,assetName);
						mc.rotation=45;
						var mc1:MovieClip = new MovieClip();
						mc1.addChild(mc);
						mc.width=50;
						mc.height=50;
						mc.x=25;
						mc.y=0;
						var mc2:MovieClip = new MovieClip();
						mc1.height/=2;
						mc2.addChild(mc1);
						mc1.cacheAsBitmap=true;
						map.addChild(mc2);
						mc2.width=50;
						mc2.height=25;
						mc2.x=mc2.width/2*j+mc2.width/2*(15-i)-mc2.width/2;
						mc2.y=mc2.height/2*j+i*mc2.height/2;
						1111*/
						map=AddToMap(map,i,j,'tileOne',assetName);
						//trace(mc2.width+' '+mc2.height);
					}else{
						//var bd:Bitmap=new Bitmap(McFactory.createBitmapData('tiletile',assetName,50,25.5));
						map=AddToMap(map,i,j,'tiletile',assetName);
						//map.addChild(bd);
						//bd.x=bd.width/2*j+bd.width/2*(15-i)-bd.width/2;
						//bd.y=bd.height/2*j+i*bd.height/2;
						//trace(bd.x);
						
					}
				}
			}
			
			return map;
		}
		public static function AddToMap(mc:MovieClip,i:Number,j:Number,str:String,assetName:String):MovieClip{
			var bd:Bitmap=new Bitmap(McFactory.createBitmapData(str,assetName,50,25.5));
			mc.addChild(bd);
			bd.x=bd.width/2*j+bd.width/2*(15-i)-bd.width/2;
			bd.y=bd.height/2*j+i*bd.height/2;
			return mc;
		}
		public static function AddMcToMap(mc:MovieClip,i:Number,j:Number,str:String,assetName:String):MovieClip{
			var bd:MovieClip=new MovieClip()
			bd=McFactory.createMc(str,assetName);
			mc.addChild(bd);
			bd.x=bd.width/2*j+bd.width/2*(15-i)-bd.width/2;
			bd.y=bd.height/2*j+i*bd.height/2;
			return mc;
		}
		
	}
}