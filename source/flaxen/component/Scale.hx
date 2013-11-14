
package flaxen.component;

class Scale
{
	public var x:Float;
	public var y:Float;

	public function new(x:Float = 1.0, y:Float = 1.0)
	{
		this.x = x;
		this.y = y;
	}

	public function clone(): Scale
	{
		return new Scale(x, y);
	}

	inline public static function full(): Scale
	{
		return new Scale();
	}

	inline public static function half(): Scale
	{
		return new Scale(0.5, 0.5);
	}

	inline public static function double(): Scale
	{
		return new Scale(2.0, 2.0);
	}
}