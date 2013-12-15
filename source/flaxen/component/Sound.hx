package flaxen.component;

using StringTools;

// Basic sound component
class Sound
{
	public var destroyEntity:Bool = false; // on complete/stop, removes whole entity
	public var destroyComponent:Bool = false; // on complete/stop, removes Sound component from entity
	public var loop:Bool = false; // loop sound continuously
	public var restart:Bool = false; // restart sound from beginning ASAP
	public var stop:Bool = false; // stop sound ASAP
	public var complete:Bool = false; // true when sound has completed playing
	public var file:String; // as supplied to constructor
	public var isMusic:Bool; // set automatically by constructor
	public var offset:Float; // as supplied to constructor
	public var failsAllowed:Int = 0; // if cannot play sound, tries again N times if this is positive

	// May be modified real-time, will be picked up by AudioSystem
	public var volume:Float; // 0-1
	public var pan:Float; // -1 full left, +1 full right

	public function new(file:String, loop:Bool = false, volume:Float = 1, pan:Float = 0, offset:Float = 0)
	{
		this.isMusic = file.endsWith("mp3");
		this.file = file;
		this.loop = loop;
		this.volume = volume;
		this.pan = pan;
		this.offset = offset;
	}
}