package flaxen.component;

import flaxen.common.Completable;
import flaxen.util.DynUtil;
import flaxen.common.LoopType;

/**
 * When an animation stops, defines final frame behavior. When loop is LoopType.None, the animation 
 * stops after one sequence. Otherwise you have set stop manually. Pausing the animation will not 
 * cause this behavior to activate. Sets complete flag.
 */
enum AnimationStopType
{ 
	Clear;	// The animation disappears (default)
	Last;	// The animation freezes on the last frame
	First;	// The animation freezes on the first frame
	Pause;  // the animation remains on its current frame as if paused (but it's stopped/complete)
}

/**
 * Animation component.
 * 
 * - TODO: Consider looping ala Tween, esp for RANDOM
 * - TODO: Support multiple animation sequences in a single Spritemap
 * - TODO: Maybe the Loop adjustments in setFrames should be moved to AnimationView?
 * - TODO: Add support for stopAfterLoops
 */ 
class Animation implements Completable
{
	/** Array of frame indices; see `update()` and `setFrames` */
	public var frames:Dynamic;

	public var speed:Float;

	/** Looping behavior; see `update()` and `setFrames` */
	public var loop(default,null):LoopType; // Don't change this directly, but through setFrames

	// public var stopAfterLoops:Int = 0; // Only if loop is not None; if 0 assumed infinite
	// public var loopCount(default, null):Int = 0;

	/** These can be set at any time */
	public var stop:Bool = false; // stop animation ASAP (sets complete)
	public var restart:Bool = false; // restart animation from beginning ASAP, unsets complete flag
	public var paused:Bool = false; // pause or resume animation

	/** On complete, removes whole entity; set at initializaiton */
	public var destroyEntity:Bool = false;

	/** On complete, removes component; set at initializaiton */
	public var destroyComponent:Bool = false;

	/** When stopped, shows this frame; set at initializaiton or before restart */
	public var stopType:AnimationStopType;

	/** List of frame integers with loop reverse/both baked in; set by update(); READ-ONLY */
	public var frameArr:Array<Int>;

	/** Set by update(); READ-ONLY */
	public var changed:Bool = true;

	/** True when animation has completed playing (not if looping); READ-ONLY */
	public var complete:Bool = false; 

	/** The current frame of the animation; READ-ONLY */
	public var frame:Int = 0;

	/** This is not currently implemented */
	public var random:Bool = false;

	/**
	 * Frames can be an array of integers, a single integer, or a string
	 * containing comma-separated values: integers and/or hyphenated ranges
	 */
	public function new(frames:Dynamic, ?speed:Float, ?loop:LoopType, ?stopType:AnimationStopType)
	{
		this.frames = frames;
		this.speed = (speed == null ? com.haxepunk.HXP.assignedFrameRate : speed);
		this.loop = (loop == null ? LoopType.Forward : loop);
		this.stopType = (stopType == null ? Clear : stopType);
		update();
	}

	/**
	 * Must be called after changing loop or frames.
	 */
	public function update(): Animation
	{
		frameArr = DynUtil.parseRange(frames);
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

	/**
	 * Convenience method for changing frames or looping
	 */
	public function setFrames(frames:Dynamic, ?loop:LoopType)
	{
		this.frames = frames;
		if(loop != null)
			this.loop = loop;
		update();
	}

	public function setLoopType(loop:LoopType, ?stopType:AnimationStopType)
	{
		this.loop = loop;
		this.stopType = (stopType == null ? Clear : stopType);
		update();
	}
}