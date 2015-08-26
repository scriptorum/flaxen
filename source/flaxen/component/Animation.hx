package flaxen.component;

import flaxen.common.Completable;
import flaxen.common.LoopType;
import flaxen.common.OnCompleteAnimation;
import flaxen.util.ArrayUtil;
import flaxen.util.DynUtil;

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

	/** Stop animation ASAP; sets complete; can be set at any time */
	public var stop:Bool = false;

	/** Restart animation ASAP; unsets complete; can be set at any time */
	public var restart:Bool = false;

	/** Pause or unpause animation; can be set at any time */
	public var paused:Bool = false;

	/** On complete, what should we do? */
	public var onComplete:OnCompleteAnimation;

	/** List of frame integers with loop reverse/both baked in; set by update(); READ-ONLY */
	public var frameArr:Array<Int>;

	/** Set by update(); READ-ONLY */
	public var changed:Bool = true;

	/** True when animation has completed playing (not if looping); READ-ONLY */
	public var complete:Bool = false; 

	/** The current frame of the animation; READ-ONLY */
	public var frame:Int = 0;

	/** Randomizes the frame order every loop */
	public var random:Bool = false;

	/**
	 * Frames can be an array of integers, a single integer, or a string
	 * containing comma-separated values: integers and/or hyphenated ranges
	 */
	public function new(frames:Dynamic, ?speed:Float, ?loop:LoopType, ?onComplete:OnCompleteAnimation)
	{
		this.frames = frames;
		this.speed = (speed == null ? com.haxepunk.HXP.assignedFrameRate : speed);
		this.loop = (loop == null ? LoopType.Forward : loop);
		this.onComplete = (onComplete == null ? Clear : onComplete);
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
	 * Convenience method for changing frames and optionally also sets looping.
	 * Frames can be an array of integers, a single integer, or a string
	 * containing comma-separated values: integers and/or hyphenated ranges
	 */
	public function setFrames(frames:Dynamic, ?loop:LoopType)
	{
		this.frames = frames;
		if(loop != null)
			this.loop = loop;
		update();
	}

	/**
	 * Updates the loop type, and optionally the complete action.
	 */
	public function setLoopType(loop:LoopType, ?onComplete:OnCompleteAnimation)
	{
		this.loop = loop;
		if(onComplete != null)
			this.onComplete = onComplete;
		update();
	}

	/**
	 * Shuffles the playback order of the frames.
	 * This is called automatically (every loop) if random is set.
	 */
	public function shuffle()
	{
		ArrayUtil.shuffle(this.frameArr);
	}
}
