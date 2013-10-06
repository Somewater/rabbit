package {
import com.somewater.rabbit.loader.EvaRabbitLoader;

import ru.evast.integration.IntegrationProxy;

import ru.evast.integration.core.SocialNetworkTypes;
import ru.evast.integration.inner.OK.OKInnerAdapter;

[SWF(width="810", height="650", backgroundColor="#FFFFFF", frameRate="30")]
public class OKRabbitLoader extends EvaRabbitLoader{

	include 'com/somewater/rabbit/include/RuPreloaderAsset.as';

	public function OKRabbitLoader() {
	}

	override protected function netInitialize():void
	{
		IntegrationProxy._socialNetworkType = SocialNetworkTypes.ODNOKLASSNIKI;
		apiAdapter = IntegrationProxy._adapter = new OKInnerAdapter();
		apiAdapter.init(flashVars, DESKTOP_MODE);
		super.netInitialize();
	}

	override protected function createSpecificPaths():void
	{
		basePath = 'http://dev.rabbit.atlantor.ru/';
		var static_server_path:String = 'http://krolgame.static1.evast.ru/OK/';
		swfs = {
			"Game":{priority:-1,preload:true,url:static_server_path + "r0/RabbitGame.swf"}
			,"Application":{priority:-1000, preload:true,url:static_server_path + "r0/RabbitApplication.swf"}
			,"Lang":{priority:100, preload:true, url:static_server_path + "r0/lang_pack.swf"}
			,"XmlPack":{preload:true, url:static_server_path + "r0/xml_pack.swf"}

			,"Interface":{preload:true, url:static_server_path + "r0/assets/interface.swf"}
			,"LevelMap":{preload:true, url:static_server_path + "r0/assets/level_map.swf"}
			,"Assets":{preload:true, url:static_server_path + "r0/assets/rabbit_asset.swf"}
			,"Rewards":{preload:true, url:static_server_path + "r0/assets/rabbit_reward.swf"}
			,"Images":{preload:true, url:static_server_path + "r0/assets/rabbit_images.swf"}
			,"MusicMenu":{url:static_server_path + "r0/assets/music_menu.swf"}
			,"MusicGame":{url:static_server_path + "r0/assets/music_game.swf"}
			,"Sound":{preload:true, url:static_server_path + "r0/assets/rabbit_sound.swf"}
			,"Font":{priority:100, preload:true, url:static_server_path + "r0/assets/fonts_" + this.locale + ".swf"}
		}

		//swfs["Editor"] = {priority:1, preload:true, url:static_server_path + "r0/RabbitEditor.swf"};

		var i:int = 0;
		var static_posting_path:String = static_server_path + 'r0/posting/';
		for (i = 0; i <= 31;i++)
			filePaths['level_pass_posting_' + i] = static_posting_path + 'levels/level_' + i + '.jpg';
		for (i = 0; i <= 79;i++)
			filePaths['reward_posting_' + i] = static_posting_path + 'rewards/reward_' + i + '.jpg';
		filePaths['friends_invite_posting'] =static_posting_path +  'friends_invite_posting.jpg';

		// не используются, если был загружен xml_pack
		filePaths["Levels"] = basePath.replace(/\/$/, '') + filePaths["Levels"];
		filePaths["Config"] = basePath.replace(/\/$/, '') + filePaths["Config"];
		filePaths["Managers"] = static_server_path + "r0/Managers.xml";
		filePaths["Description"] = static_server_path + "r0/Description.xml";
		filePaths["Rewards"] = static_server_path + "r0/Rewards.xml";
	}

	override public function get net():int { return 4; }


	override public function get asyncPayment():Boolean {
		return true;
	}
}
}
