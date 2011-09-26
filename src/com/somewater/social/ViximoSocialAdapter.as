package com.somewater.social
{
	import com.progrestar.common.util.JSON;
	
	import flash.external.ExternalInterface;

	public class ViximoSocialAdapter extends Hi5SocialAdapter
	{
		public function ViximoSocialAdapter()
		{
			super();
			networkName = 'T_NETWORK_VIXIMO';
			PERMISSIONS = 2;
			PAYMENT_EXTERNAL_BILLING = true;
			PAYMENT_SERVER_CHECK = false;
		}
		
		override public function showPaymentBox(socialMoney:Number, onSuccess:Function=null, title:String=null, message:String=null, code:String=null, params:Object=null):Boolean
		{
			if(ExternalInterface.available) {				
				flashCallbacks["onPaymentSuccess"] = null;
				flashCallbacks["onPaymentSuccess"] = function(params) : void {
					onSuccess(params);
				}
				ExternalInterface.call('payment', code);
				return true;
			} 
			return false;	
		}
		
		override public function showInviteBox(uid:String=null, type:String=null, onComplete:Function=null, onError:Function=null):Boolean {
			if(ExternalInterface.available) {
				ExternalInterface.call('invite');
				return true;
			} else {
				return false;
			}
		}
		
		override public function wallPost(recipient:SocialUser=null, title:String=null, message:String=null, image:*=null, 
										  imageUrl:String=null, postData:String=null, onComplete:Function=null, onError:Function=null, additionParams:Object=null):Boolean{
			
			trace("images " + images[imageUrl], imageUrl);
			if(images[imageUrl]) {
				imageUrl = images[imageUrl];
				if(additionParams && additionParams.imagePostfix) {
					var ind : int = imageUrl.lastIndexOf('.');
					if(ind != -1) {
						imageUrl = imageUrl.substr(0,ind)+additionParams.imagePostfix+imageUrl.substr(ind);
					}
					delete additionParams.imagePostfix;
				}
			}
			else
				trace("No image in images dictionary for " + imageUrl);
			
			
			if(recipient == null)
				recipient = user;
			
			if(true || super.wallPost(recipient)){// hook постить можно всегда (при условии выставления настройки)
				if(!PERMISSION_WALL_FOR(recipient)){
					// hook, позволяющий продолжить постинг после успешного выставления настроек
					onWallStreamPermission(arguments);
					return true;
				}
				
				// запостить
				var href:String = application_path;
				if(href.indexOf('?')!=-1) {
					href += '&';
				} else {
					href += '?';
				}
				var href:String = "pstar_loc=" + postData + "&oid=" + user.id + "&vid=" + recipient.id;	
				
				if(!additionParams)	additionParams = {};
				if(!additionParams["linkText"] && additionParams["playTo"])
					additionParams["linkText"] = additionParams["playTo"];
				if(!additionParams["linkText"] && additionParams["name"])
					additionParams["linkText"] = additionParams["name"];
				if(!additionParams["linkText"])
					additionParams["linkText"] = "Play the game";
				
				var data:Object = {};
								
				data["attachment"] = {
					"description":'',// message,  // дуюлирует "caption", но пишется около него
					"caption": 'Digger',
					"media" : {
						"type": "image",
						"src": imageUrl,
						pstar_loc: postData,oid:user.id,vid:recipient.id
					}
				};
				if(recipient.itsMe) {
					data.type = 'activity';
				} else {
					
					data.type = 'update';
					data.target = [{id:162/*recipient.id*/,name:escape(recipient.firstName+' '+recipient.lastName)}];
					//data.target = [{ id: 21, name: "Susan" }, { id: 79, name: "Joe" } ];
				}
				
				data.message = message;
				
				data["action_links"] = [{"text":additionParams["linkText"], pstar_loc: postData,oid:user.id,vid:recipient.id}];
				
				if(ExternalInterface.available) {
				/*	var s:String = '{type: "update",target: [{ "id": "21", "name": "Susan" }, { id: "79", name: "Joe" } ],message: "Something happened in the game, and this is the subject!",' +
						'attachment: {caption: "Short caption under image symbolizing {{123|Bob}}\'s activity.",' +
						'description: "This is a short, 2-3 sentence description of {{123|Bob}}\'s recent game activity, and how it affects {{21|Susan}} and {{79|Joe}}. As you see, it ' +
						'is displayed here, in the right-hand column. Use this area for telling the reader ({{123|Bob}}\'s friends) what just happened, where it will' +
						' likely be displayed on {{123|Bob}}\'s activity feed or wall.",media: {type: "image",src: "http://xyz.com/images/notifications/example1.png",var1: "value1",' +
						'var2: "value2"}},action_links: [{text: "Take this action!",var1: "value1",var2: "value2"},{text: "Take this other action!",var3: "value3",var4: "value4"}],' +
						'complete: function() {}}';*/					
					ExternalInterface.call('wallPost',data);
				} else {
					return false;
				}
				
				flashCallbacks["wallPost"] = null;
				flashCallbacks["wallPost"] = function(complete:Object):void{
					ExternalInterface.available && ExternalInterface.call("showAlert", "Message sent");
					onComplete && onComplete();
													
				};
				return true;
			}
			return false;
		}
		override protected function preRefresh():void{
			super.preRefresh();
			ExternalInterface.addCallback("flashCallback", flashCallback);
		}
	}
}