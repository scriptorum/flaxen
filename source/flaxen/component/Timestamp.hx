package flaxen.component;

/**
 * A component that holds a timestamp value, in milliseconds.
 */
class Timestamp
{
	public var stamp:Int;

	function new(stamp:Int)
	{
		this.stamp = stamp;	
	}

	public static function now(): Int
	{
		return openfl.Lib.getTimer();
	}

	public static function create(): Timestamp
	{
		return new Timestamp(now());
	}
}