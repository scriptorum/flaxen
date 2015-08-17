package flaxen.component;

import openfl.geom.Rectangle;

/*
 * Represents the 2D position of the entity.
 *
 * Most entities that have renderable components (Image, for example) require
 * a Position before they will display.
 * 
 * - TODO: The convenience methods all rely on the stage height/width, but what if the stage resizes? Consider
 * 		adding an asPercentage parameter, as it exists in Offset. Then either require the RenderingSystem
 * 		to calculate the actual position at render time, or add a method that does the math in here.
 *		That has some disadvantages.
 */
class Position
{
	public var x:Float;
	public var y:Float;

	public function new(x:Float, y:Float)
	{
		this.x = x;
		this.y = y;
	}

	public function subtract(x:Float, y:Float): Position
	{
		return add(-x, -y);
	}

	public function add(x:Float, y:Float): Position
	{
		this.x += x;
		this.y += y;
		return this;
	}

	public function copy(pos:Position): Position
	{
		this.x = pos.x;
		this.y = pos.y;
		return this;
	}

	public function clone(): Position
	{
		return new Position(x, y);
	}

	public function matches(o:Position): Bool
	{
		if(o == null)
			return false;
		return (o.x == x && o.y == y);
	}

	public static function safeClone(o:Position): Position
	{
		return (o == null ? null : o.clone());
	}

	public static function match(o1:Position, o2:Position): Bool
	{
		if(o1 == o2)
			return true;
		if(o1 == null)
			return false;
		return (o1.matches(o2));
	}

	public function isInside(rect:Rectangle): Bool
	{
		return rect.contains(this.x, this.y);
	}

	/**
	 * Returns an angle between this point and another point, degrees, 0 north
	 */
	public function getAngleTo(pos:Position): Float
	{
	  	var theta = Math.atan2(pos.y - y, pos.x - x);
	    theta += Math.PI / 2.0;
	    var angle = theta * 180 / Math.PI;
	    return (angle < 0 ? angle + 360 : angle);
	}

	public function getDistanceTo(pos:Position): Float
	{
		var dx = pos.x - x;
		var dy = pos.y - y;
		return Math.sqrt(dx * dx + dy * dy);
	}

	public function set(x:Float, y:Float)
	{
		this.x = x;
		this.y = y;
	}

	public function toString(): String
	{
		return x + "," + y;
	}

	/**
	 * 	// Some convenience methods
	 * 
	 */
	public static inline function zero(): Position
	{
		return topLeft();
	}

	public static inline function topLeft(): Position
	{
		return new Position(0, 0);
	}

	public static inline function top(): Position
	{
		return new Position(com.haxepunk.HXP.halfWidth, 0);
	}

	public static inline function topRight(): Position
	{
		return new Position(com.haxepunk.HXP.width, 0);
	}

	public static inline function left(): Position
	{
		return new Position(0, com.haxepunk.HXP.halfHeight);
	}

	public static inline function center(): Position
	{
		return new Position(com.haxepunk.HXP.halfWidth, com.haxepunk.HXP.halfHeight);
	}

	public static inline function right(): Position
	{
		return new Position(com.haxepunk.HXP.height, com.haxepunk.HXP.halfHeight);
	}

	public static inline function bottomLeft(): Position
	{
		return new Position(0, com.haxepunk.HXP.height);
	}

	public static inline function bottom(): Position
	{
		return new Position(com.haxepunk.HXP.halfWidth, com.haxepunk.HXP.height);
	}

	public static inline function bottomRight(): Position
	{
		return new Position(com.haxepunk.HXP.width, com.haxepunk.HXP.height);
	}
}