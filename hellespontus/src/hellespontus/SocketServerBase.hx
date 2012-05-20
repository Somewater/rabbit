package hellespontus;

import cpp.Lib;
import cpp.vm.Lock;
import cpp.vm.Thread;
import cpp.net.Host;
import haxe.Stack;
import sys.net.Socket;
import haxe.io.Bytes;
import haxe.io.Eof;
import hellespontus.SocketClient;
import hellespontus.RoomController;

private typedef ThreadDef = {
	var id:Int;
	var thread:Thread;
	var sockets:Array<Socket>;
}

private typedef SocketDef<Client> = {
	var socket:Socket;
	var client:Client;
	var buffer:Bytes;
	var bufbytes:Int;
	var threadId:Int;
}

class SocketServerBase<Client, Controller> 
{
	static public inline var ENDLINE_CODE:Int = "\n".charCodeAt(0);
	
	public static var host:String = 'localhost';
	public static var port:Int = 88;
	
	private var acceptQueue:Array<Socket>;// очередь подконнектившихся
	private var activeQueue:Array<Socket>;// очередь, с коротой производится работа
	private var disconnectQueue:Array<Socket>;// очередь на удаление
	
	private var worker:Thread;
	private var timer:Thread;
	private var threadById:Array<ThreadDef>;
	private var socket:Socket;
	
	public var config:Dynamic;

	public function new(?config:Dynamic = null)
	{
		// инициализация полей
		this.acceptQueue = new Array<Socket>();
		this.activeQueue = new Array<Socket>();
		this.disconnectQueue = new Array<Socket>();
		this.threadById = new Array<ThreadDef>();
		
		this.config = { 
					updateTime: 1 ,
					numThread: 10,
					maxSockPerThread: 10,
					readInterval: 0.1,
					defaultBufsize: 128,
					maxBufferSize: (1 << 16)
				};

		if (config)
			for (s in Reflect.fields(config))
				Reflect.setField(this.config, s, Reflect.getProperty(config, s));
	}

	public function run( host, port ):Void {
		socket = new Socket();
		socket.bind(new Host(host),port);
		socket.listen(10);
		
		worker = cpp.vm.Thread.create(runWorker);
		timer = cpp.vm.Thread.create(runTimer);

		for( i in 0...(config.numThread) ) {
			var t:ThreadDef = {
				id : i,
				thread : null,
				sockets : new Array<Socket>()
			};
			threadById[t.id] = t;
			t.thread = Thread.create(callback(runThread,t));
		}

		log("Socket server started at " + host + ":" + port);
		while( true ) {
			try {
				acceptQueue.push(socket.accept());
			} catch( e : Dynamic ) {
				logError("run " + e);
			}
		}

		socket.close();
	}

	function runWorker():Void {
		log("Worker started...");
		while( true ) {
			var f = Thread.readMessage(true);
			try {
				f();
			} catch( e : Dynamic ) {
				logError("runWorker " + e);
			}
		}
	}
	
	function runTimer() {
		var l:Lock = new Lock();
		log("Ticker started...");
		while( true ) {
			l.wait(config.updateTime);
			work(tick);
		}
	}
	
	function runThread(t:ThreadDef) {
		var s:Socket;
		while( true ) {
			try {
				var read:Array<Socket> = Socket.select(t.sockets, null, null, config.readInterval).read;
				for (s in read)
				{
					var socketDef:SocketDef<Client> = s.custom;
					if (socketDef == null)
					{
						socketDef = { 	client: createClient(s),
										socket: s ,
										buffer: Bytes.alloc(config.defaultBufsize),
										bufbytes: 0,
										threadId: t.id
									};
						s.custom = socketDef;
					}
					
					try {
						readData(socketDef);
						processData(socketDef);
					} catch( e : Dynamic ) {
						if( !Std.is(e, Eof) )
							logError("runThread..read " + e);
						closeConnection(socketDef.socket);
					}	
				}
			} catch( e : Dynamic ) {
				logError("runThread..select " + e);
			}
		}
	}
	
	function readData( cl : SocketDef<Client> ) {
		var buflen = cl.buffer.length;
		// eventually double the buffer size
		if( cl.bufbytes == buflen ) {
			var nsize = buflen * 2;
			if( nsize > config.maxBufferSize ) {
				if( buflen == config.maxBufferSize )
					throw "Max buffer size reached";
				nsize = config.maxBufferSize;
			}
			var buf2 = Bytes.alloc(nsize);
			buf2.blit(0,cl.buffer,0,buflen);
			buflen = nsize;
			cl.buffer = buf2;
		}
		// read the available data
		var nbytes = cl.socket.input.readBytes(cl.buffer,cl.bufbytes,buflen - cl.bufbytes);
		cl.bufbytes += nbytes;
	}

	function processData( cl : SocketDef<Client> ) {
		var pos = 0;
		while( cl.bufbytes > 0 ) {
			var nbytes = processClientData(cl.client,cl.buffer,pos,cl.bufbytes);
			if( nbytes == 0 )
				break;
			pos += nbytes;
			cl.bufbytes -= nbytes;
		}
		if( pos > 0 )
			cl.buffer.blit(0,cl.buffer,pos,cl.bufbytes);
	}

	private function logError(msg:Dynamic):Void {
		log("[ERROR] " + msg);
	}
	
	public function log(msg:Dynamic):Void {
		Lib.println(msg.toString());
	}
	
	public function work(cb:Void -> Void):Void {
		worker.sendMessage(cb);
	}
	
	public function tick():Void {
		var s:Socket;
		while((s = acceptQueue.shift()) != null)
		{
			var threadId:Int = Std.random(threadById.length);
			threadById[threadId].sockets.push(s);
		}
	}
	
	public function closeConnection( s : Socket ) : Bool {
		var cl : SocketDef<Client> = s.custom;
		if( cl == null)
			return false;
		try{ s.close(); }catch( e : Dynamic ) { };
		removeClient(cl.client);
		threadById[cl.threadId].sockets.remove(s);
		return true;
	}
	
	public function clientWrite( s : Socket, buf : Bytes, ?pos : Int = 0, ?len : Int  = -1) {
		try {
			if (len == -1)
				len = buf.length;
			
			while( len > 0 ) {
				var nbytes = s.output.writeBytes(buf,pos,len);
				pos += nbytes;
				len -= nbytes;
			}
		} catch( e : Dynamic ) {
			closeConnection(s);
		}
	}
		
	// Custom API
	
	public function createClient(s:Socket):Client { 
		throw "SocketServerBase::createClient is not implemented"; 
		return null; 
	}

	public function removeClient(client:Client):Void
	{
		log("[CLIENT REMOVING NOT IMPLEMENTED]");
	}
	
	public function processClientData( client : Client, buf : Bytes, pos : Int, len : Int ):Int {
		throw "SocketServerBase::processClientData is not implemented";
		return 0;
	}
}