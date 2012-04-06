		/**
		 * Эмбед русских ассетов прелоадера в класс, лежащий в дефолтном пакете
		 */

		[Embed(source="./assets/swc/preloader.swf", symbol="preloader.Preloader")]
		private var PRELOADER_CLASS:Class;

		[Embed(source="./assets/swc/preloader.swf", symbol="preloader.LogoRabbit")]
		private var LOGO_CLASS:Class;

		override protected function get PreloaderClass():Class
		{
			return PRELOADER_CLASS;
		}

		override protected function get LogoClass():Class
		{
			return LOGO_CLASS;
		}