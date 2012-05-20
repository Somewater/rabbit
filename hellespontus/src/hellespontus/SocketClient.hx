package hellespontus;
import sys.net.Socket;

/**
 * ...
 * @author 
 */

typedef SocketClient =
{
	var socket:Socket;
	
	var room:RoomController;
	
	var main:Bool;

	var userId:String;

	var netId:Int;
}