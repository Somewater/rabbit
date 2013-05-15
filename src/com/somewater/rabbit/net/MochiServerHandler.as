package com.somewater.rabbit.net {
public class MochiServerHandler extends LocalServerHandlerBase{
	public function MochiServerHandler(config:Object) {
		super(config);
		METHOD_TO_HANDLER = {
			'stat':stat
			,'init':initHandler
			,'levels/complete':levelComplete
			,'rewards/move':moveReward
			,'tutorial/inc':incrementTutorial
			,'offer/add':addOffer
			,'money/buy':buyMoney
			,'items/purchase':purchaseItems
			,'items/use':useItem
			,'customize/purchase':purchaseCustomizeItems
			,'top':top
		};
	}
	
	private function stat(data:Object):Object {
		return {success: true}
	}
	private function initHandler(data:Object):Object {
		return {success: true}
	}
	private function levelComplete(data:Object):Object {
		return {success: true}
	}
	private function moveReward(data:Object):Object {
		return {success: true}
	}
	private function incrementTutorial(data:Object):Object {
		return {success: true}
	}
	private function addOffer(data:Object):Object {
		return {success: true}
	}
	private function buyMoney(data:Object):Object {
		return {success: true}
	}
	private function purchaseItems(data:Object):Object {
		return {success: true}
	}
	private function useItem(data:Object):Object {
		return {success: true}
	}
	private function purchaseCustomizeItems(data:Object):Object {
		return {success: true}
	}
	private function top(data:Object):Object {
		return {success: true}
	}
}
}
