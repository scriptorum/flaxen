package flaxen.common;

import flaxen.core.Log;

// 2D integer point
class Point
{
	public var x:Int;
	public var y:Int;
	
	public function new(x:Int, y:Int)
	{
		set(x, y);
	}

	public function set(x:Int, y:Int): Point
	{
		this.x = x;
		this.y = y;
		return this;
	}

	public function add(x:Int, y:Int): Point
	{
		this.x += x;
		this.y += y;
		return this;
	}

	// Makes an array of Point2D objects from a flat array of x + y values
	public static function makeArray(array:Array<Int>): Array<Point>
	{
		var result = new Array<Point>();
		while(array.length > 0)
		{
			var v1 = array.shift();
			var v2 = array.shift();
			if(v2 == null)
				Log.error("Unbalanced set of x/y pairs passed to makeArray");
			result.push(new Point(v1, v2));
		}

		return result;
	}
}