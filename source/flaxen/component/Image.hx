/*
	- Is clipWidth/Height really necessary? 
	- In fact should I even store width/height?
*/
package flaxen.component;

import openfl.geom.Rectangle;

class Image
{
	public var path:String;
	public var clip:Rectangle;
	public var flipped:Bool; // If true, flips image horizontally

	// READ-ONLY. These will be set by the View class to hold the full image dimensions.
	public var width:Float;  
	public var height:Float; 

	// READ-ONLY. These will be set by the View class to hold the clipped dimensions
	// of the image. If an ImageGrid is applied, this will be the tile dimensions.
	// If a clip is applied, this will be the clip dimensions. Otherwise this will
	// be the the same as width/height.
	public var clipWidth:Float;
	public var clipHeight:Float;

	public function new(path:String, clip:Rectangle = null, flipped:Bool = false)
	{
		this.path = path;
		this.clip = clip;
		this.flipped = flipped;
	}
}