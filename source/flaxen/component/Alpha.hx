package flaxen.component;

class Alpha
{
	public var value:Float;
	
	public function new(value:Float)
	{
		this.value = value;
	}

	public static function clear()
	{
		return new Alpha(0.0);
	}

	public static function opaque()
	{
		return new Alpha(1.0);
	}

	public static function half()
	{
		return new Alpha(1.0);
	}
}