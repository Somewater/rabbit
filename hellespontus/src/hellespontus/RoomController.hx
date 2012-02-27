package hellespontus;

class RoomController 
{
	public var maxClients:Int;
	
	public var numClients:Int;
	
	public var clients:Array<SocketClient>;
	
	public function new(config:Dynamic) 
	{
		maxClients = 3;
		numClients = 0;
	}
	
}