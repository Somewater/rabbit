import flash.desktop.NativeApplication;
import flash.ui.Keyboard;
import flash.events.KeyboardEvent;

private function initializeManagersAIR():void
{
	Config.stage.addEventListener(KeyboardEvent.KEY_UP, fl_OptionsMenuHandler, false, 0, true);
	NativeApplication.nativeApplication.addEventListener(Event.DEACTIVATE, handleDeactivate, false, 0, true);
}

function fl_OptionsMenuHandler(e:KeyboardEvent):void {
	if(e.keyCode == 0x01000016)//Keyboard.BACK)
	{
		if(Config.gameModuleActive)
		{
			Config.game.pause();
			Config.callLater(function():void{
				Config.game.finishLevel(LevelInstanceDef.DUMMY_FATAL_LEVEL);
				Config.application.startPage("main_menu");
			});
			e.preventDefault();
			e.stopImmediatePropagation();
		}
		else if(!((Config.application as RabbitApplication).currentPage is MainMenuPage))
		{
			Config.application.startPage("main_menu");
			e.preventDefault();
			e.stopImmediatePropagation();
		}
		else
			NativeApplication.nativeApplication.exit(0);
	}
}

function handleDeactivate(event:Event):void {
	NativeApplication.nativeApplication.exit(0);
}
