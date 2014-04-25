/**
	An alternative to the Scale component. Scales the image to the fixed dimensions specified.
*/
package flaxen.component;

class Size
{
	public var width:Float;
	public var height:Float;

	public function new(width:Float, height:Float)
	{
		this.width = width;
		this.height = height;
	}

	public function clone(): Size
	{
		return new Size(width, height);
	}

	// Scales up or down
	public function scale(by:Float): Size
	{
		width *= by;
		height *= by;
		return this;
	}

	public static function screen(): Size
	{
		return new Size(com.haxepunk.HXP.width, com.haxepunk.HXP.height);
	}
}