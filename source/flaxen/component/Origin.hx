package flaxen.component;

/*
 * This changes the rotation point of the image. It does not change the center point! 
 * To do that, use Offset. Supply true for asPercentage to interpret x/y as percentages of
 * width/height. For example new Origin(-0.5, -0.5, true) rotates any image around its center.
 */

class Origin
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

	inline public static function center(): Origin
	{
		return new Origin(-0.5, -0.5, true);
	}
}