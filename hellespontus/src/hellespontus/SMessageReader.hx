package hellespontus;
import haxe.io.Bytes;
import haxe.Serializer;

/**
 * ...
 * @author 
 */

class SMessageReader 
{
	/**
	 * В какоую комнату желает вступить игрок
	 */
	public static inline function wishRoomId(msg:SocketMessage):{room:Int, net:Int, uid:String}
	{
		return {room: readByte(msg, 0), net: readByte(msg, 1), uid: readBytes(msg, 2).toString()};
	}
	
	/**
	 * Информация по доступным комнатам
	 */
	public static inline function roomIndex(rooms:Array<RoomController>, maxRoom:Int):SocketMessage
	{
		var buf = Bytes.ofString(Serializer.run( 
				{active: rooms.length , max: maxRoom} 
			));
		return { commandIndex: SSCommand.SS_CMD_INDEX_RESPONSE, bytes: buf };
	}
	
	/**
	 * Данный юзер вошел в комнату
	 */
	public static inline function newUser(client:SocketClient, hello:SocketMessage):SocketMessage
	{
		var m:SocketMessage = { commandIndex: SSCommand.SS_CMD_ADDED, bytes: hello.bytes };
		return m;
	}
	
	/**
	 * Юзер, ранее находившийся в комнате, вышел из нее
	 */
	public static inline function userExit(client:SocketClient):SocketMessage
	{
		var buf = Bytes.ofString(Serializer.run(
			{user: clientToObject(client)}
		));
		var m:SocketMessage = { commandIndex: SSCommand.SS_CMD_REMOVED, bytes: buf };
		return m;
	}
	
	/**
	 * Хозяин комнаты послал команду уничтожить комнату
	 */
	public static inline function destroyAllNotify():SocketMessage
	{
		return { commandIndex: SSCommand.SS_CMD_DESTROY_ALL_NOTIFY, bytes: Bytes.alloc(0) };
	}
	
	/**
	 * Игрок был успешно добавлен в комнату, к которой он хотел подключиться
	 */
	public static inline function successAdded():SocketMessage
	{
		return { commandIndex: SSCommand.SS_CMD_CONNECTED_SUCCESS, bytes: Bytes.alloc(0)};
	}

	/**
	 * Ошибка в процессе обработки запроса
	 */
	public static inline function logicError(message:String):SocketMessage
	{
		return {commandIndex: SSCommand.SS_CMD_LOGIC_ERROR, bytes: Bytes.ofString(message)};
	}
	
	private static inline function readByte(msg:SocketMessage, pos:Int):Int
	{
		return msg.bytes.get(pos);
	}

	private static inline function readBytes(msg:SocketMessage, pos:Int, len:Int = -1):Bytes
	{
		if(len == -1)
			len = msg.bytes.length - pos;
		return msg.bytes.sub(pos, len);
	}

	private static inline function clientToObject(client:SocketClient):Dynamic
	{
		return {uid: client.userId, net: client.netId, main: client.main};
	}
	
}