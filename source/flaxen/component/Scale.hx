package flaxen.component;

class Scale
{
	public var x:Float = 1.0;
	public var y:Float = 1.0;

	public function new(x:Float, y:Float)
	{
		this.x = x;
		this.y = y;
	}

	public function clone(): Scale
	{
		return new Scale(x, y);
	}
}