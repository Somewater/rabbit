 package {
      import flash.desktop.NativeApplication;
  import flash.display.NativeWindow;
  import flash.display.NativeWindowInitOptions;
  import flash.display.Sprite;
  import flash.display.StageAlign;
  import flash.display.StageScaleMode;
  import flash.events.Event;
  public class AIRActionScript extends Sprite
  {
    public function AIRActionScript()
    {
      var win:NativeWindow =
        new NativeWindow(new NativeWindowInitOptions());
      win.activate();
      win.addEventListener(Event.CLOSE, function():void {
        NativeApplication.nativeApplication.exit(0);
      });

      win.stage.addChild(this);

      stage.scaleMode = StageScaleMode.NO_SCALE;
      stage.align = StageAlign.TOP_LEFT;

      graphics.lineStyle(1, 0, 1);
      graphics.drawCircle(100, 100, 80);
    }
  }
}

