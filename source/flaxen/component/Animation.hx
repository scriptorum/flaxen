package flaxen.component;

import flaxen.component.Image;
import flaxen.component.Subdivision;

class Animation
{
	public var frames:Array<Int>;
	public var speed:Float;
	public var looping:Bool;
	public var image:Image;
	public var subdivision:Subdivision;

	public function new(image:Image, subdivision:Subdivision, frames:Array<Int>, speed:Float, looping:Bool)
	{
		this.frames = frames;
		this.speed = speed;
		this.looping = looping;
		this.image = image;	
		this.subdivision = subdivision;	
	}
}
