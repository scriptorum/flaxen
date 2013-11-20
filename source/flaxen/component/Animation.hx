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
	
	public var loop(default,null):LoopType; // Don't change this when set

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
		this.loop = (loop == null ? LoopType.Forward : loop);
		setFrames(frames);
	}

	public function setFrames(frames:Dynamic): Animation
	{
		this.frames = Animation.parseFrames(frames);
		switch(loop)
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

	public static function parseFrames(frames:Dynamic): Array<Int>
	{
		if(Std.is(frames, Array))
				return cast frames;

		if(Std.is(frames, Int))
			return [cast(frames, Int)];

		if(!Std.is(frames, String))
			Log.error("Animation frames must be comma separated integers and hyphenated ranges");

		// Treat as comma-separated string with hyphenated inclusive ranges
		var result = new Array<Int>();
		var tokens = StringUtil.split(frames, ",");
		for(token in tokens)
		{
			// Single number
			if(token.indexOf("-") == -1)
				result.push(Std.parseInt(token));

			// Range of numbers min-max
			else
			{
				var parts = StringUtil.split(token, "-");
				var min = Std.parseInt(parts[0]);
				var max = Std.parseInt(parts[1]);
				for(i in min...max+1)
					result.push(i);			
			}
		}
		return result;
	}
}