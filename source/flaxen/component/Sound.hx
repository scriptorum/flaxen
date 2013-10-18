package flaxen.component;

using StringTools;

// Basic sound component
class Sound
{
	// TSK TSK you know this shit should be moved elsewhere and this should be a generic class
	public static inline var FIRE:String = "whistle.wav";
	public static inline var EATEN:String = "crackle.wav";
	public static inline var START:String = "start.wav";
	public static inline var CHARGE:String = "fuse.wav";
	public static inline var FIREWORK_BIG:String = "fireworks.wav";
	public static inline var ADD_STAR:String = "star.wav";
	public static inline var ORBDEATH:String = "orbdeath.wav";
	public static inline var POP:String = "pop.wav";
	public static inline var APPEAR:String = "appear.wav";
	public static inline var THUNDER:String = "thunder.wav";
	public static inline var BOOSTER:String = "whoosh.wav";
	public static inline var MENU_MUSIC:String = "menu.mp3";
	public static inline var PLAY_MUSIC:String = "doodaddy.mp3";
	public static inline var LEVEL_INTRO:String = "level-intro.wav";
	public static inline var LEVEL_OUTRO:String = "level-outro.wav";
	public static inline var CLICK:String = "click.wav";
	public static inline var DENIED:String = "denied.wav";
	public static inline var LEVEL_SELECT_MUSIC:String = "gameend.mp3";	

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
	public var volume:Float = 1; // 0-1
	public var pan:Float = 0; // -1 full left, +1 full right

	public function new(file:String, loop:Bool = false, offset:Float = 0)
	{
		this.isMusic = file.endsWith("mp3");
		this.file = file;
		this.loop = loop;
		this.offset = offset;
	}
}