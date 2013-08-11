package com.somewater.rabbit.events {
import flash.events.Event;

public class CameraMoveEvent extends Event{

	public static const UP:int = 1;
	public static const DOWN:int = 2;
	public static const LEFT:int = 4;
	public static const RIGHT:int = 8;

	public static const CAMERA_MOVE_EVENT:String = 'cameraMoveEvent';

	public var direction:int;

	public function CameraMoveEvent(direction:int) {
		super(CAMERA_MOVE_EVENT);
		this.direction = direction;
	}

	public function get isMoved():Boolean {
		return direction != 0;
	}
}
}
