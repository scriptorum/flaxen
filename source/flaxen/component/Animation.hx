/*
	TODO
	  - Consider looping ala Tween, esp for RANDOM
	  - Support multiple animation sequences in a single Spritemap
	  - Maybe the Loop adjustments in setFrames should be moved to AnimationView?
*/
package flaxen.component;

import flaxen.util.StringUtil;
import flaxen.core.Log;
import flaxen.common.LoopType;

class Animation
{
	public var frames:Array<Int>;
	public var speed:Float;
	public var changed:Bool = true; // Mark as true when changing one of the above values
	
	public var loop(default,null):LoopType; // Don't change this directly, but through setFrames

	public var destroyEntity:Bool = false; // on complete/stop, removes whole entity
	public var destroyComponent:Bool = false; // on complete/stop, removes Animation component from entity
	public var complete:Bool = false; // true when animation has completed playing (not if looping)
	public var stop:Bool = false; // stop animation ASAP (sets complete)
	public var restart:Bool = false; // restart animation from beginning ASAP

	// This is not currently implemented
	public var random:Bool = false; // true if you want frames selected at random

	// Frames can be an array of integers, a single integer, or a string
	// containing comma-separated values: integers and/or hyphenated ranges
	public function new(frames:Dynamic, speed:Float = 30.0, ?loop:LoopType)
	{
		this.speed = speed;
		setFrames(frames, loop);
	}

	public function setFrames(frames:Dynamic, ?loop:LoopType): Animation
	{
		this.loop = (loop == null ? LoopType.Forward : loop);
		this.frames = StringUtil.parseRange(frames);
		switch(this.loop)
		{
			case Backward:
			this.frames.reverse();

			case Both:
			var f = this.frames.copy();
			f.reverse();
			this.frames = this.frames.concat(f);

			case BothBackward:
			var f = this.frames.copy();
			this.frames.reverse();
			this.frames = this.frames.concat(f);

			case None:
			case Forward:
			// Done
		}

		changed = true;
		return this;
	}
}