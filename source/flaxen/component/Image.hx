package flaxen.component;

import flash.geom.Rectangle;

class Image
{
	public var path:String;
	public var clip:Rectangle;
	public var width:Float; // dimensions not set until ImageView created
	public var height:Float; 

	public function new(path:String, clip:Rectangle = null)
	{
		this.path = path;
		this.clip = clip;	
	}
}