package com.somewater.rabbit.editor.console {
	import com.somewater.rabbit.application.RewardManager;
	import com.somewater.rabbit.social.PostingFactory;
	import com.somewater.rabbit.storage.Config;
	import com.somewater.rabbit.storage.LevelDef;
	import com.somewater.rabbit.storage.RewardDef;

	import flash.display.DisplayObject;

	import flash.display.Sprite;

	public class ImageGeneratorCommand {

		private var password:String;
		private var size:int;
		private var folder:String;

		private var windows:*;
		private var queue:Array = [];
		private var queueIndex:int = 0;

		/**
		 * Аргументы
		 * -p password
		 * -s size (pixels)
		 * -f folder ["images"]
		 *
		 */
		public function ImageGeneratorCommand(args:Object) {
			this.password = args['p'] || '';
			this.size = args['s'] || 100;
			this.folder = args['f'] || 'images';

			windows = Config.application.message('100%');
			windows.title = 'Posting process...';
			windows.buttons = [];
			windows.closeButton.visible = false;

			var index:int = 0;

//			for each(var lvl:LevelDef in Config.application.levels)
//			{
//				queue.push(new QueueElement(lvl, index++));
//			}

			for(var i:int = 1;i<=Math.max(Config.application.levels.length, 30); i++)
			{
				queue.push(new QueueElement(new LevelDef(<xml number={i}></xml>), index++));
			}

			for each(var reward:RewardDef in RewardManager.instance.getRewards())
			{
				queue.push(new QueueElement(reward, index++));
			}

			onImageComplete();
		}

		private function onImageComplete(serverResponse:String = null):void
		{
			if(queue[queueIndex])
			{
				// process next
				var q:QueueElement = queue[queueIndex++];
				if(q.level)
				{
					// level photo
					process(PostingFactory.createLevelPosting(q.level), 'level', q.level.number.toString())
				}
				else if(q.reward)
				{
					// reward photo
					process(PostingFactory.createRewardPosting(q.reward), 'reward', q.reward.id.toString())
				}
				else
				{
					throw new Error('Undefined QueueElement');
				}

				windows.text = queueIndex + ' / ' + queue.length;
			}
			else
			{
				windows.closeButton.visible = true;
				windows.text = "Completed " + queue.length + " images"
			}
		}

		private function process(dor:DisplayObject, type:String, id:String):void
		{
			Imaginarium.uploadImage(Imaginarium.createBitmap(dor, size, size),
					Config.loader.serverHandler.base_path + 'images/manage',
					onImageComplete,
					{'type':type, 'id':id, 'folder': folder, 'password':password});
		}
	}
}

import com.somewater.rabbit.storage.LevelDef;
import com.somewater.rabbit.storage.RewardDef;

class QueueElement
{
	public var data:*;// LevelDef  || RewardDef
	public var index:int;

	public function QueueElement(data:*, index:int)
	{
		this.data = data;
		this.index = index;
	}

	public function get level():LevelDef
	{
		return data as LevelDef;
	}

	public function get reward():RewardDef
	{
		return data as RewardDef;
	}
}
