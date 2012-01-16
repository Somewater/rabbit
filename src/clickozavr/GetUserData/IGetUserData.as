package clickozavr.GetUserData
{
	import flash.events.IEventDispatcher;

	public interface IGetUserData extends IEventDispatcher
	{
		function getUserData(apiData:Object):void;	// Получить данные пользователя из соцсети
		function get networkId():String;			// Id сети
	}
}