
package flaxen.component;

import flaxen.component.Size;

class Subdivision
{
	public var width:Int; // tiles across
	public var height:Int; // tiles down
	public var plot:Size; // tile size

	public function new(width:Int, height:Int, plot:Size)
	{
		this.width = width;
		this.height = height;
		this.plot = plot;
	}

	public static function create(width:Int, height:Int, 
		plotWidth:Int, plotHeight:Int): Subdivision
	{
		return new Subdivision(width, height, new Size(plotWidth, plotHeight));
	}
}