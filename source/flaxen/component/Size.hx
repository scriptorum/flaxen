
package flaxen.component;

import com.haxepunk.HXP;

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

	public static function screen(): Size
	{
		return new Size(HXP.width, HXP.height);
	}
}