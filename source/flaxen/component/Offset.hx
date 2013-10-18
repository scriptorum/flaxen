package flaxen.component;

/*
 * This changes the center point of the image. It does not change the transformation point! 
 * To do that, use Origin.
 */

class Offset
{
	public var x:Float;
	public var y:Float;

	public function new(x:Float, y:Float)
	{
		this.x = x;
		this.y = y;
	}
}