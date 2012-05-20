package ;

import hellespontus.SocketServer;

/**
 * Сокет сервер
 */

class Hellespontus 
{
	public static var host:String = 'localhost';
	public static var port:Int = 88;
	public static var server:SocketServer;
	
	/**
	 * Доступные значения конфига
	 * maxRooms
	 */
	static function main() 
	{
		// todo: прочитать конфигурационные файлы
		var debug:Bool = true;
		var config:Dynamic = {debug: debug};
		
		// запустить сервер
		server = new SocketServer(config);
		server.run(host, port);
	}
	
}