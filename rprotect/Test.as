package
{
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Loader;
import flash.display.Sprite;
import com.somewater.net.SWFDecoderWrapper
import flash.utils.setTimeout;

import flash.events.Event;
import flash.events.MouseEvent;

import flash.net.URLRequest;
import flash.system.ApplicationDomain;

public class Test extends Sprite
{

    private var USE_AD:Boolean = true;
    private var iterator:int = 0;

    public function Test()
    {
        super();

        this.graphics.beginFill(0);
        this.graphics.drawCircle(10,10,5);
        
        SWFDecoderWrapper.async = stage;
        SWFDecoderWrapper.asyncBytesPerTick = 10;

        stage.addEventListener(MouseEvent.CLICK, function(e:Event):void{
            trace("Mouse clicked");
            setTimeout(function():void{
            	loadData();	
            }, 1);
            setTimeout(function():void{
            	loadDataSelfly();	
            }, 1000);
            setTimeout(function():void{
            	USE_AD = false;
            	loadData();	
            }, 3000);
            setTimeout(function():void{
             	USE_AD = false;
            	loadDataSelfly();	
            }, 4000);
        })
    }

    public function loadDataSelfly():void
    {
        var loader:Loader = new Loader()
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(ev:Event):void{
            var data:DisplayObject = loader.contentLoaderInfo.content;
            SWFDecoderWrapper.load(data, function(obj:*):void{
                trace("Encoding complete callback: " + obj);
                if(USE_AD)
                    receiveAd(obj)
                else
                    receiveData(obj);
            }, function(event:Event = null):void{
                trace("Encoding error callback: " + event);
            });
        })
        loader.load(new URLRequest('Data.swf'))
    }

    public function loadData():void
    {
        SWFDecoderWrapper.load('Data.swf', function(obj:*):void{
            trace();
            if(USE_AD)
                receiveAd(obj)
            else
                receiveData(obj);
        }, function(event:Event = null):void{
            trace("Encoding error callback: " + event);
        });
    }

    public function receiveData(data:DisplayObject):void
    {
        trace("Encoding complete callback: " + data);
        addChild(data);
        data.x += iterator * 10;
        data.y += iterator * 10;
        trace('Data loaded in Test: ' + Object(data).foo());
        trace('Current ApplicationDomain has Data: ' + ApplicationDomain.currentDomain.hasDefinition('Data'))
        iterator++;
    }

    public function receiveAd(ad:ApplicationDomain):void
    {
        trace("Encoding complete callback: " + ad);
        var data_cl:Class = ad.getDefinition('Data') as Class;
        var data:* = new data_cl();
        data.x += iterator * 10;
        data.y += iterator * 10;
        addChild(data);
        trace('Data loaded in Test: ' + Object(data).foo());
        trace('Current ApplicationDomain has Data: ' + ApplicationDomain.currentDomain.hasDefinition('Data'))
        iterator++;
    }
}
}
