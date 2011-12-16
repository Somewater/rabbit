package com.somewater.rabbit.application.windows {
import com.somewater.display.Window;
import com.somewater.rabbit.social.StartNextLevelCommand;
import com.somewater.storage.Lang;

import flash.display.DisplayObject;

import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	/**
 * Окно показывает процесс постинга
 */
public class MessagePostClose extends Window
{
	private var data:*;
	private var callback:Function;
	private var timer:Timer;
	private var callbackFromCOmmand:Boolean = false;

	/**
	 *
	 * @param data
	 * @param commandClass комнада, принимающая аргументы new command(data:*, onComplete:Function, onError:Function)
	 * @param callback колбэк на нажатие кнопки в окне (уже после того как юзер запостил и увидел поздравление в данном коне,
	 * 					либо отказался постить и увидел предупреждение в окне)
	 */
	public function MessagePostClose(data:*, commandClass:Class, callback:Function = null):void
	{
		this.data = data;
		this.callback = callback;
		super(Lang.t('LEVEL_POSTING_IN_PROCESS'), null, onButtonClick);

		closeButton.visible = false;
		if(buttons && buttons[0] is DisplayObject) buttons[0].visible = false;
		var self:MessagePostClose = this;

		open();

		timer = new Timer(30000, 1);
		timer.addEventListener(TimerEvent.TIMER, onTimer);
		timer.start();

		new commandClass(data, onCompleteCommand, onErrorCommand).execute();
	}

	private function onCompleteCommand(...args):void
	{
		if(callbackFromCOmmand) return;
		// complete
		closeButton.visible = true;
		if(buttons && buttons[0] is DisplayObject) buttons[0].visible = true;
		text = Lang.t('LEVEL_POSTING_SUCCESS');
		callbackFromCOmmand = true
	}

	private function onErrorCommand(...args):void
	{
		if(callbackFromCOmmand) return;
		// error
		closeButton.visible = true;
		if(buttons && buttons[0] is DisplayObject) buttons[0].visible = true;
		text = Lang.t('ERROR_POSTING');
		callbackFromCOmmand = true
	}

	private function onTimer(event:TimerEvent):void {
		if(callbackFromCOmmand) return;
		onErrorCommand();
	}


	override public function close():void {
		data = null;
		callback = null;
		if(timer)
		{
			timer.removeEventListener(TimerEvent.TIMER, onTimer);
			timer.stop();
			timer = null;
		}
		super.close();
	}

	override protected function onCloseBtnClick(e:MouseEvent):void {
		if(closeButton.visible)
		{
			onCallback();
			super.onCloseBtnClick(e);
		}
	}

	private function onButtonClick(label:* = null):Boolean {
		if(closeButton.visible)
		{
			onCallback();
			return true;
		}
		else
			return false;
	}

	private function onCallback():void
	{
		if(callback)
			callback(data);
	}
}
}
