package flaxen.component;

class Repeating
{
	public static var instance = new Repeating(); // static instance for repeating both dimensions
	
	public var repeatX:Bool;
	public var repeatY:Bool;

	public function new(repeatX:Bool = true, repeatY:Bool = true)
	{
		this.repeatX = repeatX;
		this.repeatY = repeatY;
	}
}
