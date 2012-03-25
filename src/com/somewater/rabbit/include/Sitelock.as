		import com.somewater.rabbit.storage.Config;

		import flash.display.DisplayObject;

		import flash.display.DisplayObjectContainer;
		import flash.display.Sprite;
		import flash.utils.getQualifiedClassName;

		/////////////////////////////////////////////////////////////////////////
		//                                                                     //
		//	ПРОТЕСТИРОВАТЬ, что loaderInfo.url соответствует указанному сайту  //
		//                                                                     //
		/////////////////////////////////////////////////////////////////////////

		Config.prototype['__url'] = (Config.loader as DisplayObjectContainer).loaderInfo ? (Config.loader as DisplayObjectContainer).loaderInfo.url : null;
		if(this is DisplayObject && DisplayObject(this).stage && DisplayObject(this).stage.loaderInfo)
			Config.prototype['__url'] = DisplayObject(this).stage.loaderInfo.url;
		Config.prototype['__url'] = Config.prototype['__url'].match(/https?\:\/\/([\w\.\-\d]*\.)?(\w[\w\-\d]+\.\w{2,6})/)
		if(Config.prototype['__url'])
			Config.prototype['__url'] = Config.prototype['__url'][2];
		else
			Config.prototype['__url'] = 'localhost';

		// тестируем, что Config.loader.serverHandler.encrypt работает корректно
		if(String(Config.loader.serverHandler.encrypt(getQualifiedClassName(Sprite))).substr(0,8)
				!= int(Math.sin(0.19987330259)*10000000000).toString(16))
		{
			// совершить страшное
			include 'SiteLockRaiseError.as';
		}

		if(CONFIG::sitelock == getQualifiedClassName(Sprite))
		{
			// nothing
		}
		else if(CONFIG::sitelock != Config.loader.serverHandler.encrypt(Config.prototype['__url']))
		{
			// совершить страшное
			include 'SiteLockRaiseError.as';
		}