package flaxen.component;

/*
 * This changes the center point of the image. It does not change the transformation point! 
 * To do that, use Origin. Supply true for asPercentage to interpret x/y as percentages of
 * width/height. For example new Offset(-0.5, -0.5, true) centers any image.
 */

class Offset
{
	public var x:Float;
	public var y:Float;
	public var asPercentage:Bool = false;

	public function new(x:Float, y:Float, asPercentage:Bool = false)
	{
		this.x = x;
		this.y = y;
		this.asPercentage = asPercentage;
	}

	inline public static function center(): Offset
	{
		return new Offset(-0.5, -0.5, true);
	}
}