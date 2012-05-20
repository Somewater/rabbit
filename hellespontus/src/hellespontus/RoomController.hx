package hellespontus;

class RoomController 
{
	public var maxClients:Int;
	
	public var clients:Array<SocketClient>;
	
	public function new(config:Dynamic) 
	{
		maxClients = config.maxClients;
		if(maxClients <= 0)
			maxClients = 3;

		clients = new Array<SocketClient>();
	}
	
}