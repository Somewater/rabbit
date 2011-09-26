/**
 * Created by IntelliJ IDEA.
 * User: pav
 * Date: 9/17/11
 * Time: 1:36 PM
 * To change this template use File | Settings | File Templates.
 */
package com.somewater.rabbit {
	import com.somewater.rabbit.storage.LevelDef;

	public interface IRabbitEditor {
		function start():void;

		function restartLevel(newLevel:LevelDef = null, force:Boolean = false):void

		function show():void

		function hide():void

		function showOrHide():void
	}
}
