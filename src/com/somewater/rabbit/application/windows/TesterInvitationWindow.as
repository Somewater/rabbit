package com.somewater.rabbit.application.windows {
	import com.somewater.display.Window;
	import com.somewater.text.EmbededTextField;

	import flash.display.Bitmap;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;

	public class TesterInvitationWindow extends Window{

		[Embed(source="TesterInvitation.jpg")]
		private var imageCl:Class;

		private const BTN_LABEL:String = 'МЕНЯ ЗАИНТЕРЕСОВАЛО ЭТО ПРЕДЛОЖЕНИЕ';

		public function TesterInvitationWindow() {
			super('',null, onClick, [BTN_LABEL])

			var image:Bitmap = new imageCl();
			image.x = 20;
			image.y = 30;
			addChild(image);

			var tf:EmbededTextField = new EmbededTextField(null, 0x42591E, 16, false, true, true);
			tf.mouseEnabled = true;
			tf.width = 300;
			tf.height = 200;
			tf.x = image.x + image.width + 20;
			tf.y = image.y;
			tf.htmlText = '<font size="20">Уважаемые игроки!</font>\nНам нужны люди для тестирования новых уровней игры. ' +
					'\nХотите поиграть первыми, желаете попасть в список тестировщиков игры? ' +
					'Тогда это предложение для Вас!\n' +
					'Кого заинтересовало предложение, пишите комментарии в группе. ' +
					'Самые активные 10 тестировщиков попадут в раздел "Авторы" игры!\n' +
					'\n                 <u><font size="18" color="#0000FF"><a href="event:invite">Группа игры</a></font><u>';
			tf.addEventListener(TextEvent.LINK, onLink)
			addChild(tf)

			setSize(700,390);
			open();
		}

		private function onLink(event:Event):void {
			navigateToGroup();
		}

		private function onClick(label:String):Boolean {
			if(label == BTN_LABEL)
			{
				navigateToGroup();
				return false;
			}
			return true;
		}

		private function navigateToGroup():void
		{
			navigateToURL(new URLRequest('http://vkontakte.ru/wall-33566408_48'), '_blank')
		}
	}
}
