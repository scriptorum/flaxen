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
}