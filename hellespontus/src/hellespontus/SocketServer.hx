package hellespontus;

import haxe.io.Bytes;
import haxe.Serializer;
import sys.net.Socket;
import hellespontus.SSCommand;
#if neko
import neko.Lib;
#elseif cpp
import cpp.Lib;
#else
	#error
#end

class SocketServer extends SocketServerBase<SocketClient, RoomController> 
{
	
	private var debug:Bool;
	
	private var rooms:Array<RoomController>;
	
	public function new(?config:Dynamic = null) 
	{
		this.debug = if (config) config.debug else true;
		
		var defaultConfig:Dynamic = {
										maxRooms: 10
									};
		if (config)
			for (s in Reflect.fields(defaultConfig))
				Reflect.setField(config, s, Reflect.getProperty(defaultConfig, s));
		
		super(config);
		
		rooms = new Array<RoomController>();
	}
	
	override function createClient(s:Socket):SocketClient
	{
		var sc:SocketClient = { 
								socket: s, 
								room: null,
								main: false,
								userId: null,
								netId: -1
							  }
		if (debug)
			Lib.println("Client connected: " + sc);
		return sc;
	}
	
	override function removeClient(client:SocketClient)
	{
		if(debug)
			Lib.println("Client disconnected: " + client);
		if(client.room != null)
		{
			var message:SocketMessage = SMessageReader.userExit(client);
			client.room.clients.remove(client);
			for (c2 in client.room.clients)
				clientMessage(c2, message);
			client.room = null;
		}
		client.socket = null;
	}
	
	override public function processClientData( client : SocketClient, buf : Bytes, pos : Int, len : Int ):Int {
		var endLineEnding:Bool = buf.get(pos + len - 1) == hellespontus.SocketServerBase.ENDLINE_CODE;
		var cmd:SocketMessage = { commandIndex:0, bytes: Bytes.alloc(len - (if(endLineEnding) 2 else 1)  )};
		cmd.commandIndex = buf.get(pos);
		cmd.bytes.blit(0, buf, pos + 1, len - (if (endLineEnding) 2 else 1));

		if(debug && cmd.commandIndex == 0x64)//'d' - debug
		{
			var array:Array<String> = cmd.bytes.toString().split('.');
			cmd.commandIndex = Std.parseInt(array.shift());
			cmd.bytes = Bytes.alloc(array.length);
			var i:Int = 0;
			for (a in array)
				cmd.bytes.set(i++, Std.parseInt(a));
		}
		
		try{
			processClientMessage(client, cmd);
		}catch (logicErr:LogicError)
		{
			logError('[LOGIC ERROR] ' + logicErr.message + '\n' + client);
			clientMessage(client, SMessageReader.logicError(logicErr.message));
		}
		return len;
	}
	
	public function processClientMessage( client : SocketClient, msg : SocketMessage ) {
		var commandIndex:Int = msg.commandIndex;
		var buf:Bytes;
		var room:RoomController;
		var c2:SocketClient;
		var message:SocketMessage;
		switch(commandIndex)
		{
			case SSCommand.SS_CMD_INDEX:
				// get rooms index
				clientMessage(client, SMessageReader.roomIndex(rooms, this.config.maxRoom));
			case SSCommand.SS_CMD_CONNECT:
				// add to room
				if (client.room != null)
					throw new LogicError('Already connected to the room');

				if(msg.bytes.length < 3)
					throw new LogicError('User message too short');

				var wishRoom = SMessageReader.wishRoomId(msg);

				if (wishRoom.room < 0 || wishRoom.room >= config.maxRooms)
					throw new LogicError('Wrong room id ' + wishRoom);
				if(wishRoom.net < 0 || wishRoom.uid == null || Std.string(wishRoom.uid).length == 0)
					throw new LogicError('Wrong user id');
				client.netId = wishRoom.net;
				client.userId = wishRoom.uid;

				room = rooms[wishRoom.room];
				if (room == null)
					rooms[wishRoom.room] = room = new RoomController(this.config);
				else if (room.clients.length >= room.maxClients)
					throw new LogicError('Room is full');

				client.main = room.clients.length == 0;
				client.room = room;
				room.clients.push(client);

				// сообщить игроку об успешном коннекте и остальным членам комнаты о новом игроке
				clientMessage(client, SMessageReader.successAdded());
				if (!client.main)
				{
					message = SMessageReader.newUser(client, msg);
					for (c2 in room.clients)
						if (c2 != client)
							clientMessage(c2, message);
				}
			case SSCommand.SS_CMD_BROADCAST:
				// send by all (in room)
				if (client.room != null && client.main)
				{
					for (c2 in client.room.clients)
						if (c2 != client)
							clientMessage(client, msg);
				}
				else
					throw new LogicError('Only main user can send broadcast');
			case SSCommand.SS_CMD_DISPATCH:
				// send by room owner
				if (client.room != null && client.main == false)
				{
					clientMessage(client.room.clients[0], msg);
				}
				else
					throw new LogicError('Only not main room users can dispatch');
			case SSCommand.SS_CMD_SUICIDE:
				// disconnect from room
				if (client.room != null && !client.main)
				{
					closeConnection(client.socket);
				}
				else
					throw new LogicError('Only not main user can exit');
			/*case SSCommand.SS_CMD_ADDED:
				// new user in room
			case SSCommand.SS_CMD_REMOVED:
				// user left room*/
			case SSCommand.SS_CMD_DESTROY_ALL:
				// room destroyed
				if (client.room != null && client.main)
				{
					message = SMessageReader.destroyAllNotify();
					for (c2 in client.room.clients)
						if (c2 != client)
							clientMessage(client.room.clients[0], message);
				}
				else
					throw new LogicError('Only main user can destroy room');
			default:
				// ping-pong
				var hex:String = msg.bytes.toHex();
				Lib.println("Client say: " + hex);				
				clientMessage(client, {commandIndex: 0, bytes: Bytes.ofString(hex + "\n")}); 
		}
	}
	
	public function clientMessage(client:SocketClient, msg:SocketMessage):Void
	{
		var buf:Bytes = Bytes.alloc(msg.bytes.length + 1);
		buf.set(0, msg.commandIndex);
		buf.blit(1, msg.bytes, 0, msg.bytes.length);
		if(debug)
			buf = Bytes.ofString(buf.toString() + "===" + buf.toHex() + "\n");
		this.clientWrite(client.socket, buf);
	}
	
	
	////////////////////////////////////////////////
	//											  //
	//		C O M M A N D     H A N D L E R S     //
	//											  //
	////////////////////////////////////////////////
	
}

class LogicError
{
	public var message:String;
	
	public function new(msg:String)
	{
		message = msg;
	}
}
