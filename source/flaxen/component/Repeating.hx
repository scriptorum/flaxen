package flaxen.component;

/**
 * Causes an Image to repeat along the x and/or y axes.
 * Use `Repeating.instance` if you want full repeat for a HaxePunk Backdrop.
 * Otherwise use new `Repeating(repeatX, repeatY)` to specify horizontal-only or vertical-only tiling.
 */

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
