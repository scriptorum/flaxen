package flaxen.component;

import flaxen.util.Array2D;
import flaxen.util.Util;

class Grid extends Array2D<Int>
{
	public var changed:Bool = true;
	public var eraseBeforeUpdate:Bool = false;

	override public function new(width:Int, height:Int, initValue:Dynamic = 0)
	{
		super(width, height, initValue);
	}

	public function load(str:String, delimiter:String = ",", eol = ";", x:Int = 0, y:Int = 0): Void
	{
		var _x = x;
		var _y = y;
		for(line in Util.split(str, eol))
		{
			for(n in Util.split(line, delimiter))
			{
				if(n != "")
					set(_x++, _y, Std.parseInt(n));
			}
			_y++;
			_x = x;
		}
	}
}