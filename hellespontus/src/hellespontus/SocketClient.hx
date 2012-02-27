package hellespontus;
import neko.net.Socket;

/**
 * ...
 * @author 
 */

typedef SocketClient =
{
	var socket:Socket;
	
	var room:RoomController;
	
	var main:Bool;
}