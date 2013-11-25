package flaxen.component;

import flash.geom.Rectangle;
import flaxen.component.Tile;
import flaxen.component.ImageGrid;

class Tile
{
	public var value:Int;

	public function new(value:Int)
	{
		this.value = value;
	}

	// Plot X
	public function x(subdivision:ImageGrid): Int
	{
		return value % subdivision.tilesAcross;
	}

	// Plot Y
	public function y(subdivision:ImageGrid): Int
	{
		#if debug
		if(subdivision.tilesAcross <= 0)
			throw "ImageGrid.tilesAcross not initialized";
		#end

		return Math.floor(value / subdivision.tilesAcross);
	}

	public function rect(subdivision:ImageGrid): Rectangle
	{
		return new Rectangle(x(subdivision) * subdivision.tileWidth, 
			y(subdivision) * subdivision.tileHeight, subdivision.tileWidth, subdivision.tileHeight);
	}
}