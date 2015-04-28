package flaxen.component;

import ash.core.Engine;
import flaxen.common.Completable;
import flaxen.common.Easing;
import flaxen.common.LoopType;
import flaxen.Log;

/**
 * General interpolation class. This example moves myEntity to the upper left corner
 * over the course of two seconds, after which the Tween component removes itself from 
 * myEntity. Tweens require the TweeningSystem to be active.
 *
 * 	var pos = myEntity.get(Position);
 * 	var tween = new Tween(pos, { x:0, y:0 }, 2);
 * 	tween.destroyComponent = true;
 * 	myEntity.add(t);
 *
 *  - TODO: Add ability to fast-forward Tween to particular time-step. AND/OR
 * 	  Add ability to specify start values instead of using current values in source.
 * 	  MultiVarTween. Consider reusing HaxePunk's tweeners.
 *  - TODO: Add chaining methods for adjusting easing, loop, autostart, name and onComplete.
 */
class Tween implements Completable
{
	public static var created:Int = 0;

	public var complete:Bool = false;
	public var running:Bool = false;
	public var source:Dynamic;
	public var target:Dynamic;
	public var ranges:Array<Float>;
	public var starts:Array<Float>;
	public var props:Array<String>;
	public var easing:EasingFunction;
	public var elapsed:Float = 0;
	public var loop:LoopType; // Can set after creating tween
	public var optional:Float = 1.70158;
	public var duration:Float;
	public var onComplete:OnComplete;
	public var fields:Array<String>;
	public var name:String; // optional object name for logging
	public var stopAfterLoops:Int = 0; // Only if loop is not None; if 0 assumed infinite
	public var loopCount(default, null):Int = 0;

	public function new(source:Dynamic, target:Dynamic, duration:Float, ?easing:EasingFunction, 
		?loop:LoopType, ?onComplete:OnComplete, autoStart:Bool = true, ?name:String)
	{
		this.source = source;
		this.target = target;
		this.duration = duration;
		Log.assert(duration > 0);
		this.easing = (easing == null ? Easing.linearTween : easing);
		this.loop = (loop == null ? LoopType.None : loop);
		this.onComplete = (onComplete == null ? None : onComplete);
		this.name = "__tween"  + Std.string(++created);
		
		if(autoStart)
			start();
	}

	/**
	 * If not autostarted, must call this to run tween
	 */
	public function start()
	{
		this.running = true;
		this.elapsed = 0;

		if(Reflect.isObject(target))
			fields = Reflect.fields(target);
		else Log.error("Unsupported properties object");
		if(fields.length == 0)
			Log.error("No fields found for tween target; ensure it is an anonymous object.");

		ranges = new Array<Float>();
		starts = new Array<Float>();
		props = new Array<String>();
		for(field in fields)
		{
			var sVal:Float = Reflect.getProperty(source, field);
			var tVal:Float = Reflect.getProperty(target, field);
			if(Math.isNaN(tVal))
				Log.error("Property " + field + " is not a number (" + tVal + ")");
			if(Math.isNaN(sVal))
				Log.error("Start object lacks numeric field " + field + " (" + sVal + ")");
			props.push(field);
			starts.push(sVal);
			ranges.push(tVal - sVal);
			// trace("Storing field " + field + " from " + sVal + " to " + tVal  + " (" + (tVal - sVal) + ")");
		}
	}

	public function restart(): Void
	{
		this.elapsed = 0;
	}

	public function update(time:Float): Void
	{
 		if(complete || !running)
 			return;

 		elapsed = Math.min(elapsed + time, duration);
 		
		for(i in 0...props.length)
		{
			var pos = (loop == LoopType.BothBackward || loop == LoopType.Backward ? 
				duration - elapsed : elapsed);
			var value = easing(pos, starts[i], ranges[i], duration, optional);
			Reflect.setProperty(source, props[i], value);
		}

 		if(elapsed >= duration)
 		{
			if(loop == LoopType.None || (stopAfterLoops > 0 && ++loopCount >= stopAfterLoops))
			{				
 				complete = true;
 				return;
			}

			if(loop == LoopType.Both)
				loop = LoopType.BothBackward;
			else if(loop == LoopType.BothBackward)
				loop = LoopType.Both;

			restart();
 		}
	}	
}
