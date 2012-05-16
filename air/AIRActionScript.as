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

      stage.scaleMode = StageScaleMode.NO_SCALE;
      stage.align = StageAlign.TOP_LEFT;

      graphics.lineStyle(1, 0, 1);
      graphics.drawCircle(100, 100, 80);
    }
  }
}

