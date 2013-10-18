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
}