package com.somewater.arrow
{
	import com.somewater.social.MailSocialAdapter
	
	public class ArrowMail extends Arrow
	{
		override protected function createSocial():void
		{
			social = new MailSocialAdapter();
		}
		
		/*override public function init(params:Object):void
		{
			params['key'] = '529d006c41825455c4addca3a69046a6';
			super.init(params);
		}*/
	}
}
