
package flaxen.component;

import flash.geom.Rectangle;

class Image
{
	public var path:String;
	public var clip:Rectangle;
	public var flipped:Bool; // If true, flips image horizontally

	// READ-ONLY. These will be set by the View class to hold the clipped dimensions
	// of the image. If an ImageGrid is applied, this will be the tile dimensions.
	// If a clip is applied, this will be the clip dimensions. Otherwise this will
	// be the image's overall dimensions.
	public var width:Float;  
	public var height:Float; 

	public function new(path:String, clip:Rectangle = null, flipped:Bool = false)
	{
		this.path = path;
		this.clip = clip;
		this.flipped = flipped;
	}
}