package hellespontus;

import haxe.io.Bytes;
import neko.Lib;
import neko.net.Socket;
import neko.net.ThreadServer;

class SocketServer extends ThreadServer<SocketClient, SocketMessage> 
{
	public static inline var SS_CMD_INDEX:Int = 10;// ответить, какие доступны комнаты
	
	public static inline var SS_CMD_CONNECT:Int = 20;// присоединиться к комнате
	
	public static inline var SS_CMD_BROADCAST:Int = 30;// широковещательное сообщение для комнаты
	
	public static inline var SS_CMD_DISPATCH:Int = 31;// сообщение для хозяина комнаты
	
	public static inline var SS_CMD_SUICIDE:Int = 40;// сообщение для хозяина комнаты
	
	public static inline var SS_CMD_ADDED:Int = 50;// разъединиться с комнатой
	
	public static inline var SS_CMD_REMOVED:Int = 51;// разъединиться с комнатой
	
	private var debug:Bool;
	
	public function new(debug:Bool) 
	{
		this.debug = debug;
		
		super();
	}
	
	override function clientConnected(s:Socket):SocketClient
	{
		var sc:SocketClient = { 
								socket: s, 
								room: null,
								main: false
							  }
		Lib.println("Client connected: " + sc);
		return sc;
	}
	
	override function clientDisconnected(sc:SocketClient)
	{
		Lib.println("Client disconnected: " + sc);
	}
	
	override function readClientMessage(c:SocketClient, buf:Bytes, pos:Int, len:Int)
	{
		if( len <= messageHeaderSize ) return null;

		var msg:SocketMessage = { 	
									commandIndex: buf.get(pos), 
									bytes: buf.sub(pos + 1, len - 1) 
								};
		return {msg: msg, bytes: len};
	}
	
	override public function clientMessage( sc : SocketClient, msg : SocketMessage ) {
		var commandIndex:Int = msg.commandIndex;
		switch(commandIndex)
		{
			case SS_CMD_INDEX:
				// get room index
			case SS_CMD_CONNECT:
				// add to room
				if (sc.room == null)
				{
					
				}
				else
					disconnect(sc);
			case SS_CMD_BROADCAST:
				// send by all (in room)
				if (sc.room != null && sc.main)
				{
					
				}
				else
					disconnect(sc);
			case SS_CMD_DISPATCH:
				// send by room owner
				if (sc.room != null && sc.main == false)
				{
					
				}
				else
					disconnect(sc);
			case SS_CMD_SUICIDE:
				// disconnect from room
				disconnect(sc);
			default:
				// ping-pong
				var hex:String = msg.bytes.toHex();
				Lib.println("Client say: " + hex);				
				sc.socket.output.write(Bytes.ofString(hex + "\n"));
		}
	}
	
	/**
	 * Форсированно порвать соединение с клиентом
	 */
	public function disconnect(client:SocketClient):Void
	{
		doClientDisconnected(client.socket, client);
	}
	
}
