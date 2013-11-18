package flaxen.component;

import flash.geom.Rectangle;
import flaxen.component.Tile;
import flaxen.component.Subdivision;

class Tile
{
	public var value:Int;

	public function new(value:Int)
	{
		this.value = value;
	}

	// Plot X
	public function x(subdivision:Subdivision): Int
	{
		return value % subdivision.width;
	}

	// Plot Y
	public function y(subdivision:Subdivision): Int
	{
		return Math.floor(value / subdivision.width);
	}

	public function rect(subdivision:Subdivision): Rectangle
	{
		return new Rectangle(x(subdivision) * subdivision.plot.width, 
			y(subdivision) * subdivision.plot.height, 
			subdivision.plot.width, subdivision.plot.height);
	}
}