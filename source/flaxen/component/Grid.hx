package flaxen.component;

import flaxen.common.Array2D;
import flaxen.util.StringUtil;

// The default grid is a 2D array containing integers
class Grid extends Array2D<Int>
{
	public var changed:Bool = true;
	public var eraseBeforeUpdate:Bool = false;

	override public function new(width:Int, height:Int, initValue:Dynamic = 0)
	{
		super(width, height, initValue);
	}

	// MOVE TO Array2D?
	public function load(str:String, delimiter:String = ",", eol = ";", x:Int = 0, y:Int = 0): Grid
	{
		var _x = x;
		var _y = y;
		for(line in StringUtil.split(str, eol))
		{
			for(n in StringUtil.split(line, delimiter))
			{
				if(n != "")
					set(_x++, _y, Std.parseInt(n));
			}
			_y++;
			_x = x;
		}
		return this;
	}
}