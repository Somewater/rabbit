package ;

import hellespontus.SocketServer;
import neko.Lib;

/**
 * ...
 * @author 
 */

class Hellespontus 
{
	public static var host:String = 'localhost';
	public static var port:Int = 88;
	public static var server:SocketServer;
	
	static function main() 
	{
		// todo: прочитать конфигурационные файлы
		var debug:Bool = true;
		
		// запустить сервер
		server = new SocketServer(debug);
		server.run(host, port);
	}
	
}