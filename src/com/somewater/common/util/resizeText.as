package com.somewater.common.util
{
    import flash.text.*;
    
    public function resizeText(textField:TextField):TextFormat
    {

        var textFormat:* = textField.defaultTextFormat;
        var html:String = textField.htmlText;
		
		if (!html)
		{
			textField.htmlText = " ";
			html = textField.htmlText;			
		}
		
        while (textField.maxScrollH > 0 || textField.maxScrollV > 1) 
        {
            if (!textFormat.size)
            {
                textFormat.size = 14;
            }
            textFormat.size = (int(textFormat.size) - 1);
            textField.setTextFormat(textFormat);
        }
        
        var matches:Array = html.match(/(<FONT[^>]+SIZE=")[0-9]+"/g);
        html = html.replace(/(<FONT[^>]+SIZE=")[0-9]+"/g,"$1" + textFormat.size.toString() + "\"");
        textField.htmlText = html;
        return textFormat;
    }
}