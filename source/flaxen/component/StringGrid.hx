package flaxen.component;

import flaxen.common.Array2D;

/**
 * String version of the integer-based Grid component
 */
class StringGrid extends Array2D<String>
{
	public var changed:Bool = true;

	override public function new(width:Int, height:Int, initValue:Dynamic = null)
	{
		super(width, height, initValue);
	}
}