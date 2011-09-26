package com.somewater.common.util
{
    import com.pepyator.Translate;
    import com.progrestar.games.planets.*;
    
    import flash.display.*;
    import flash.text.*;
    import flash.utils.*;
    
    public class Textilizer extends Object
    {
        public function Textilizer(arg1:flash.display.DisplayObject, arg2:flash.utils.Dictionary=null)
        {
            super();
            this.debug = this.debug;
            this.displayObject = arg1;
            this.strings = arg2 == null ? new flash.utils.Dictionary() : arg2;
            this.textilizeAll(arg1);
            return;
        }

        private function replace(arg1:flash.text.TextField):void
        {
            var loc4:*=null;
            var loc6:*=undefined;
            var loc7:*=undefined;
            var loc1:TextField=new flash.text.TextField();
            var loc2:TextFormat=arg1.getTextFormat();
            loc2.letterSpacing = arg1.getTextFormat().letterSpacing;
            loc1.defaultTextFormat = loc2;
            loc1.embedFonts = true;
            var loc3:*= Translate.translate(arg1.text);
            var loc8:Number=0;
            var loc9:*=this.strings;
            for (loc4 in loc9)
            {
                do 
                {
                    loc6 = loc3;
                    loc7 = "%" + loc4 + "%";
                }
                while ((loc3 = loc6.replace(loc7, this.strings[loc4])) != loc6);
            }
            loc1.name = arg1.name;
            loc1.htmlText = loc3;
            loc1.x = arg1.x;
            loc1.y = arg1.y;
            loc1.scaleX = arg1.scaleX;
            loc1.scaleY = arg1.scaleY;
            loc1.rotation = arg1.rotation;
            loc1.width = arg1.width;
            loc1.height = arg1.height;
            loc1.autoSize = arg1.autoSize;
            loc1.type = arg1.type;
            loc1.multiline = arg1.multiline;
            loc1.wordWrap = arg1.multiline;
            loc1.filters = arg1.filters;
            loc1.visible = arg1.visible;
            resizeText(loc1);
            if (com.progrestar.games.planets.Global.highQuality)
            {
                loc1.antiAliasType = flash.text.AntiAliasType.NORMAL;
                loc1.gridFitType = flash.text.GridFitType.NONE;
            }
            else 
            {
                loc1.antiAliasType = flash.text.AntiAliasType.ADVANCED;
                loc1.gridFitType = flash.text.GridFitType.NONE;
            }
            if (arg1.type != flash.text.TextFieldType.DYNAMIC)
            {
                if (arg1.type == flash.text.TextFieldType.INPUT)
                {
                    loc1.selectable = true;
                    loc1.mouseEnabled = true;
                    loc1.type = flash.text.TextFieldType.INPUT;
                }
            }
            else 
            {
                loc1.selectable = false;
                loc1.mouseEnabled = false;
                loc1.type = flash.text.TextFieldType.DYNAMIC;
            }
            var loc5:*;
            (loc5 = arg1.parent).addChild(loc1);
            loc5.swapChildren(arg1, loc1);
            loc5.removeChild(arg1);
            return;
        }

        private function textilizeAll(arg1:flash.display.DisplayObject):void
        {
            var loc1:*=null;
            var loc2:*=null;
            var loc3:Number=0;
            var loc4:*=null;
            if (arg1 as flash.text.TextField)
            {
                loc1 = flash.text.TextField(arg1);
                this.replace(loc1);
            }
            else 
            {
                if (arg1 as flash.display.DisplayObjectContainer)
                {
                    loc2 = flash.display.DisplayObjectContainer(arg1);
                    loc3 = (loc2.numChildren - 1);
                    while (loc3 >= 0) 
                    {
                        if ((loc4 = loc2.getChildAt(loc3)) != null)
                        {
                            this.textilizeAll(loc4);
                        }
                        loc3 = (loc3 - 1);
                    }
                }
            }
            return;
        }

        private var displayObject:flash.display.DisplayObject;

        private var debug:Boolean;

        private var strings:flash.utils.Dictionary;
    }
}


