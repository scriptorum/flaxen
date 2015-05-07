package flaxen.component;

import openfl.geom.Rectangle;

/**
 * Represents a path (URL) to an image file and optional cropping rectangle (clip).
 *
 * Regarding clipWidth/clipHeight:
 * This is set by RenderingSystem after image is processed and is READ-ONLY.
 * If an ImageGrid is shared by the entity, this represents the tile dimensions. 
 * If a clip rectangle is supplied, this represents the clipped dimensions.
 * Otherwise, this is the same as width.
 * 
 * - QUESTION: Is clipWidth/Height really necessary? 
 * - QUESTION: In fact should I even store width/height?
 */
class Image
{
	/** The path to the image asset */
	public var path:String;

	/** The optional clipping rectangle */
	public var clip:Rectangle;

	/** If true, flips image horizontally */
	public var flipped:Bool; 

	/** Full image width. Set by RenderingSystem after image is loaded. READ-ONLY. */
	public var width:Float;  

	/** Full image height. Set by RenderingSystem after image is loaded. READ-ONLY. */
	public var height:Float; 

	/** Effective (clipped/tiled) image width. See class API. */
	public var clipWidth:Float;

	/** Effective (clipped/tiled) image height. See class API. */
	public var clipHeight:Float;

	/**
	 * Constructs a new Image component
	 * 
	 *	@param	path	The path to the image asset, as set by the project xml file
	 *	@param	clip	An optional clipping rectangle; only the image portion inside the rectangle will show
	 *	@param	flipped	If true, the image will be flipped horizontally
	 */
	public function new(path:String, clip:Rectangle = null, flipped:Bool = false)
	{
		this.path = path;
		this.clip = clip;
		this.flipped = flipped;
	}
}