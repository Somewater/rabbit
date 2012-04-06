package com.somewater.rabbit.loader {
	public class EnPreloader extends Preloader{
		public function EnPreloader() {
		}

		[Embed(source="../../../../assets/swc/preloader.en.swf", symbol="preloader.Preloader")]
		private var PRELOADER_CLASS:Class;

		override protected function get PreloaderAssetClass():Class {
			return PRELOADER_CLASS;
		}
	}
}
