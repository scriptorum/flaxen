/*
	TODO
	  - Consider looping ala Tween, esp for RANDOM
	  - Support multiple animation sequences in a single Spritemap
	  - Maybe the Loop adjustments in setFrames should be moved to AnimationView?
*/
package flaxen.component;

import flaxen.util.DynamicUtil;
import flaxen.common.LoopType;
import com.haxepunk.HXP;

class Animation
{
	// Call update() after changing these values
	public var frames:Dynamic;
	public var speed:Float;
	public var loop(default,null):LoopType; // Don't change this directly, but through setFrames

	// These can be set at any time
	public var stop:Bool = false; // stop animation ASAP (sets complete)
	public var restart:Bool = false; // restart animation from beginning ASAP

	// Set once at initialization only
	public var destroyEntity:Bool = false; // on complete/stop, removes whole entity
	public var destroyComponent:Bool = false; // on complete/stop, removes Animation component from entity

	// Do not change these directly
	public var frameArr:Array<Int>; // List of frame integers with loop reverse/both baked in; set by update()
	public var changed:Bool = true; // Set by update()
	public var complete:Bool = false; // true when animation has completed playing (not if looping)

	// This is not currently implemented
	public var random:Bool = false; // true if you want the frames always selected at random

	// Frames can be an array of integers, a single integer, or a string
	// containing comma-separated values: integers and/or hyphenated ranges
	public function new(frames:Dynamic, ?speed:Float, ?loop:LoopType)
	{
		this.frames = frames;
		this.speed = (speed == null ? HXP.assignedFrameRate : speed);
		this.loop = (loop == null ? LoopType.Forward : loop);
		update();
	}

	// Must be called after changing loop or frames.
	public function update(): Animation
	{
		frameArr = DynamicUtil.parseRange(frames);
		switch(loop)
		{
			case Backward:
			frameArr.reverse();

			case Both:
			var f = frameArr.copy();
			f.reverse();
			frameArr = frameArr.concat(f);

			case BothBackward:
			var f = frameArr.copy();
			frameArr.reverse();
			frameArr = frameArr.concat(f);

			case None:
			case Forward:
			// Done
		}

		changed = true;
		return this;
	}

	// Convenience method for changing frames or looping
	public function setFrames(frames:Dynamic, ?loop:LoopType)
	{
		this.frames = frames;
		if(loop != null)
			this.loop = loop;
		update();
	}
}