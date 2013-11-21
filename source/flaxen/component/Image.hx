
package flaxen.component;

import flash.geom.Rectangle;

class Image
{
	public var path:String;
	public var clip:Rectangle;
	public var flipped:Bool; // If true, flips image horizontally

	public var width:Float;  // READ-ONLY; will be set by the View subclass
	public var height:Float; // READ-ONLY; will be set by the View subclass

	public function new(path:String, clip:Rectangle = null, flipped:Bool = false)
	{
		this.path = path;
		this.clip = clip;
		this.flipped = flipped;
	}
}