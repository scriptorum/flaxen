package flaxen.component;

import ash.core.Engine;
import flaxen.common.Completable;
import flaxen.common.Easing;
import flaxen.common.LoopType;
import flaxen.Log;

/**
 * Alters one or more values between two points over a series of time. 
 *
 * General interpolation class. Supports easing, looping, and onComplete 
 * operations. This example moves myEntity to the upper left corner
 * over the course of two seconds, after which the Tween component removes 
 * itself from myEntity.
 *
 * ```
 * 	var pos = myEntity.get(Position);
 * 	var tween = new Tween(2)
 * 		.addTarget(pos, "x", 0)
 * 		.addTarget(pos, "y", 0)
 *		.setOnComplete(DestroyComponent);
 * 	myEntity.add(t);
 * ```
 *
 * For a tween to be processed, you must use TweenSystem (added by default), 
 * the Tween instance must be added to an entity (done automatically with 
 * `Flaxen.newTween`), the entity must be added to Ash (ditto), and either 
 * autoStart must be true on creation (the default) or running set to true 
 * after creation. 
 *
 *  - TODO: Add some static methods for creating Tweens with common settings, say Tween.createAndDestroy, or with a typedef create(props:TweenOptions)
 *  - TODO: Add multitween static method to tween more than one property of the same object, in a single call
 */
class Tween implements Completable
{
	/** This is set to true when the tween completes the tween */
	public var complete:Bool = false;

	/** What to do after the tween completes */
	public var onComplete:OnComplete;

	/** The tween is only being updated when running is true; you can set
		this false to pause automatic tweening; you can pass false for autoStart to 
		delay execution; see `scrub` */
	public var running:Bool = false;

	/** The name is primarily intended for the holding entity's name, which can be
		helpful in some cases; `Flaxen.newTween` sets this automatically;
		can be null if not defined */
	public var name:String;

	/** The duration of the tween in seconds */
	public var duration:Float;

	/** The loop type of the tween; the tween only loops if this is not None */
	public var loop:LoopType;

	/** The default easing function for all tween targets without a specified easing; set before adding targets */
	public var easing:EasingFunction;

	/** The amount of elapsed time; this can be updated to advance or scrub the tween */
	public var elapsed:Float = 0;

	/** Sets the maximum number of loops; only applicable if `loop` is not None; a value of 0 is ignored (endless looping) */
	public var maxLoops:Int = 0;

	/** The number of times the tween has looped */
	public var loopCount(default, null):Int = 0;

	/** All of the tween targets */
	private var targets:Array<TweenTarget>;

	/**
	 * Constructs a new Tween
	 *
	 * For a tween to be processed, it must have targets added to it (see 
	 * `addTarget`) and be added to an Ash Entity.
	 *
	 * @param	duration	The duration of the tween in seconds
	 * @param	easing		A easing function, which will be applied to all targets that don't specify an easing; defaults to `Easing.linear`
	 * @param	loop		The loop type of the tween; `None` does not loop, all other `LoopType`s do
	 * @param	onComplete	What to do after the tween completes
	 * @param	autoStart	If true (default) kicks off the tween automatically; if false, you must kick it off by setting `running`
	 * @param	name		The duration of the tween in seconds
	 */
	public function new(duration:Float, ?easing:EasingFunction, ?loop:LoopType, 
		?onComplete:OnComplete, autoStart:Bool = true, ?name:String)
	{
		targets = new Array<TweenTarget>();

		this.duration = duration;
		Log.assert(duration > 0);
		this.easing = (easing == null ? Easing.linear : easing);
		setLoop(loop);
		setOnComplete(onComplete);
		setName(name);
		this.running = autoStart;
	}

	/**
	 * Internal method for adding a `TweenTarget` to the tween
	 * Each TweenTarget is an individual object property that can be tweened.
	 * For a shorter convenience method, see `to`.
	 *
	 *  - TODO: Add basic pathing support by allowing Array for target
	 *
	 * @param	obj		The object with the property that is to be tweened, or a function Float->Void that will be called with the tween value
	 * @param	prop	The name of the property within the object (ignored if obj is a function)
	 * @param	target	The target value to tween to
	 * @param	initial	The initial value to tween from; if not supplied, defaults to the current value of the property
	 * @param	easing	The easing function to use for this tween; if not supplied, defaults to the current value of `Tween.easing` 
	 * @returns	This `Tween`
	 */
	public function addTarget(obj:Dynamic, prop:String, target:Float, ?initial:Null<Float>, ?easing:EasingFunction): Tween
	{
		var isFunc:Bool = Reflect.isFunction(obj);

		if(Math.isNaN(cast target))
			Log.error('Property $prop is not a number ($target)');
		if(initial == null)
		{
			if(isFunc)
				Log.error("Cannot add target callback without null initial value");
			initial = Reflect.getProperty(obj, prop);
		}
		if(easing == null)
			easing = this.easing;

		var change = target - initial; // precalculate one subtraction, such a good optimizer I yam I yam
		var o = { obj:obj, prop:prop, change:change, initial:initial, easing:easing, callback:isFunc };
		targets.push(o);

		return this;
	}

	/**
	 * Convenience method for `addTarget` function callback behavior.
	 * Note this alters the order of the start/end values, since `start` is required for callbacks.
	 */
	public function call(func:Float->Void, start:Float = 0.0, end:Float = 1.0, ?easing:EasingFunction): Tween
	{
		return addTarget(func, null, start, end, easing);
	}

	/**
	 * Convenience method for `addTarget` object/property behavior.
	 */
	inline public function to(obj:Dynamic, prop:String, target:Float, ?initial:Null<Float>, ?easing:EasingFunction): Tween
	{
		return addTarget(obj, prop, target, initial, easing);
	}

	/**
	 * Call to restart the tween from the beginning.
	 */
	public function restart(): Tween
	{
		this.elapsed = 0;
		this.complete = false;
		return this;
	}

	/**
	 * Immediately sets `onComplete`.
	 *
	 * @param	OnComplete	What to do after the tween completes; defaults to `OnComplete.None`
	 * @returns This Tween
	 */
	public function setOnComplete(?onComplete:OnComplete): Tween
	{
		this.onComplete = (onComplete == null ? OnComplete.None : onComplete);
		return this;
	}

	/**
	 * Sets the `name` of this tween.
	 *
	 * The name is primarily intended for the holding entity's name, which can be
	 * used to look up the entity in Ash. See `name` for more.
	 *
	 * @param	name	The name of the tween (may be null)
	 * @returns This Tween
	 */
	public function setName(name:String): Tween
	{
		this.name = name;
		return this;
	}

	/**
	 * Sets the `loop` type of this tween.
	 *
	 * @param	loop	The `LoopType` of this tween; defaults to `LoopType.None`
	 * @returns This Tween
	 */
	public function setLoop(?loop:LoopType): Tween
	{
		this.loop = (loop == null ? LoopType.None : loop);
		return this;
	}

	/**
	 * Sets the elapsed time.
	 *
	 * This is generally managed automatically. You might call this before the tween
	 * begins to "fast-forward" the tween to a particular point. For example, 1.5 seconds
	 * into a 3.0 second tween would start the tween at the midpoint.
	 *
	 * Another possibility is to "scrub" over values of the tween. See scrub()
	 *
	 * @param	val	The elapsed time, must be positive
	 * @returns This Tween
	 */
	public function setElapsed(val:Float): Tween
	{
 		elapsed = Math.min(val, duration);
 		if(elapsed < 0)
 			elapsed = 0;
 		return this;
	}

	/**
	 * UNTESTED. Enables manual tweening aka scrubbing.
	 *
	 * Immediately scrubs all targets to a specific tween time. The
	 * val should be between 0 and the tween duration, or 0-1 if you 
	 * set asPercentage to true. This method sets `running` to false 
	 * (see `pause`) which turns off automatic tweening for this 
	 * instance. When you want to stop scrubbing and resume automatic
	 * tweening, set it back to true or call `resume`.
	 * 
	 */
	public function scrub(val:Float, asPercentage:Bool = false): Tween
	{
		// Turn off automatic tweening
		running = false;

		// Support 0-1 value for scrub, regardless of duration
		if(asPercentage)
			val = val * duration;

		// Change elapsed time to desired time
		setElapsed(val);

		// Update the tweening properties of all the targets
		applyTweens();

		return this;
	}


	/**
	 * Pauses the tween.
	 *
	 * This prevents all automatic tweening, and enables scrubbing. See `scrub`. Call `resume` to continue.
	 *
	 * @returns This tween
	 */
	public function pause(): Tween
	{
		this.running = false;
		return this;
	}

	/**
	 * Resumes a paused tween. 
	 *
	 * This resumes from the last pause point.
	 * If it was paused due to scrubbing (see `scrub`) this resumes from the last scrub point.
	 *
	 * @returns This tween
	 */
	public function resume(): Tween
	{
		this.running = true;
		return this;
	}	

	/**
	 * Sets the maximum number of loops a looping tween will have before it completes.
	 * If `loop` is None, this setting has no effect. Supply 0 to disable this feature
	 * (endless looping).
	 *
	 * @param	count	The maximum number of loops; may not be negative; 0 means no limit
	 * @returns This tween
	 */	
	public function setMaxLoops(count:Int): Tween
	{
		this.maxLoops = count;
		return this;
	}

	/**
	 * Updates automatic tweening for all targets in this instance.
	 *
	 * Internal method, called by the `TweenSystem`.
	 *
	 * @param	time	The elapsed time in seconds
	 */
	public function update(time:Float): Void
	{
		if(!running || complete)
			return;

		// Determine time elapsed
		setElapsed(elapsed + time);

		// Tween all the targets
		applyTweens();

		// We've completed one tween -- should we loop?
 		if(elapsed >= duration)
 		{
 			// No looping used, or a loop count has been reached
			if(loop == LoopType.None || (++loopCount >= maxLoops && maxLoops > 0))
			{				
 				complete = true;
 				return;
			}

			// If it's a "Both" loop, reverse the loop type
			if(loop == LoopType.Both)
				loop = LoopType.BothBackward;
			else if(loop == LoopType.BothBackward)
				loop = LoopType.Both;

			// Loop now
			restart();
 		}
	}	

	/**
	 * Updates the tween targets with the correct value for their properties
	 */
	private function applyTweens()
	{
 		// Tween each target
		for(target in targets)
		{
			// Determine effective time elapsed; support backward loops
			var seconds:Float = (loop == LoopType.BothBackward || loop == LoopType.Backward ? 
				duration - elapsed : elapsed);

			// Convert seconds elapsed into a t value from 0...1 where 1 is the duration
			var t:Float = seconds / duration;

			// Support easing
			t = target.easing(t);

			// Now tween value
			var value:Float = target.initial + target.change * t;

			// Set tween value
			if(target.callback)
				target.obj(value); // callback
			else Reflect.setProperty(target.obj, target.prop, value); // object/prop tween
		}
	}
}

/**
 * An internal structure for holding tween target data.
 */
@:dox(hide) private typedef TweenTarget = 
{
	/** The object with the property that is to be tweened */
	var obj:Dynamic;

	/** The name of the property within the object */
	var prop:String;

	/** The variable (tweened) amount of change to add to the initial */	
	var change:Dynamic;

	/** The initial value to tween from; if not supplied, defaults to the current value of the property */	
	@:optional var initial:Dynamic;

	/** The easing function to use for this tween; if not supplied, defaults to `Tween.easing` */
	@:optional var easing:EasingFunction;

	/** True if obj is a Function Float->Void */
	var callback:Bool;
}