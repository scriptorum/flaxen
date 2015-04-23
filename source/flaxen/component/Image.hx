package flaxen.component;

import openfl.geom.Rectangle;

/**
 * Represents a path (URL) to an image file and optional cropping rectangle (clip).
 *
 * Width and Height will be set by Flaxen **after** it is processed by the rendering system.
 *
 * Same thing for clipWidth/Height. If an ImageGrid is applied, these will represent
 * the tile dimensions. Otherwise, it will be equal to the clip.width/height.
 * 
 * - QUESTION: Is clipWidth/Height really necessary? 
 * - QUESTION: In fact should I even store width/height?
 */
class Image
{
	public var path:String;
	public var clip:Rectangle;
	public var flipped:Bool; // If true, flips image horizontally

	/** Full image width. READ-ONLY. */
	public var width:Float;  

	/** Full image height. READ-ONLY. */
	public var height:Float; 

	/** Effective (clipped/tiled) image width. READ-ONLY. */
	public var clipWidth:Float;

	/** Effective (clipped/tiled) image height. READ-ONLY. */
	public var clipHeight:Float;

	public function new(path:String, clip:Rectangle = null, flipped:Bool = false)
	{
		this.path = path;
		this.clip = clip;
		this.flipped = flipped;
	}
}