package flaxen.component;

class Velocity
{
	public var x:Float = 0;
	public var y:Float = 0;

	public function new(x:Float, y:Float)
	{
		this.x = x;
		this.y = y;
	}

	public function lessThan(i:Float)
	{
		return (Math.abs(x) < i && Math.abs(y) < i);
	}

	public function set(x:Float, y:Float)
	{
		this.x = x;
		this.y = y;
	}
}