package com.somewater.rabbit.net {
import com.adobe.serialization.json.JSON;
import com.somewater.rabbit.IRabbitLoader;
import com.somewater.storage.ILocalDb;
import com.somewater.storage.LocalDb;

import mochi.as3.MochiUserData;

public class MochiServerHandler extends LocalServerHandler{

	private var loader:IRabbitLoader;

	public function MochiServerHandler(config:Object, loader:IRabbitLoader) {
		trace("CONFIG: " + JSON.encode(config))
		super(config);
		this.loader = loader;
		METHOD_TO_HANDLER['top'] = top;
	}

	override protected function createLocalDb(name:String):ILocalDb {
		MochiUserData
		return super.createLocalDb(name);
	}

	override protected function stat(data:Object):Object{
		// TODO
		return {success: true}
	}
	protected function top(data:Object):Object {
		// TODO
		return {success: true}
	}
}
}
