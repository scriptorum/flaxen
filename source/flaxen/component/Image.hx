
package flaxen.component;

import flash.geom.Rectangle;

class Image
{
	public var path:String;
	public var clip:Rectangle;

	// These read-only values are set by ImageView
	public var width:Float;
	public var height:Float; 

	public function new(path:String, clip:Rectangle = null)
	{
		this.path = path;
		this.clip = clip;	
	}
}