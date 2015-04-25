package flaxen.component;

import flaxen.common.Completable;

using StringTools;

/**
 * Basic sound component
 */
class Sound implements Completable
{
	/* When the sound is complete, what action should we take? */
	public var onComplete:OnComplete;

	/** Loop sound continuously; if true, you must stop sound manually */
	public var loop:Bool = false; 

	/** Restart sound from beginning ASAP; sets complete to false */
	public var restart:Bool = false; 

	/** Stop sound ASAP; sets complete to true */
	public var stop:Bool = false; 

	/** True when sound has completed playing */
	public var complete:Bool = false; 

	/** Path to sound file; READ-ONLY */
	public var file:String; 

	/** True if this is an MP3; READ-ONLY */
	public var isMusic:Bool; 

	/** The time from the start of the sound to skip over when playing; READ-ONLY? */
	public var offset:Float; 

	/** If cannot play sound, tries again the number of times indicated */
	public var failsAllowed:Int = 0; 


	/**
	 * May be modified real-time, will be picked up by AudioSystem
	 */
	public var volume:Float; // 0-1

	/**
	 * May be modified real-time, will be picked up by AudioSystem
	 */
	public var pan:Float; // -1 full left, +1 full right

	public function new(file:String, loop:Bool = false, volume:Float = 1, pan:Float = 0, offset:Float = 0)
	{
		this.isMusic = file.endsWith("mp3");
		this.file = file;
		this.loop = loop;
		this.volume = volume;
		this.pan = pan;
		this.offset = offset;
		this.onComplete = None;
	}
}