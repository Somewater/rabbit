package com.somewater.display.blitting {
/**
 * Описывает характеристику стейта
 */
public class MovieState
{
	public var name:String;
	public var startFrame:int;
	public var endFrame:int;
	public var directionLength:Array;// по номеру дирекшна возвращает длину ее анимации или 0 (если неизестна)
}
}
