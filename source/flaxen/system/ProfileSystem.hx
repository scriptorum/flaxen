package flaxen.system;

import com.haxepunk.utils.Key;
import flaxen.Flaxen;
import flaxen.Log;
import flaxen.FlaxenSystem;
import flaxen.service.InputService;

/**
 * Do not add this system directly, it is included automatically when using -Dprofiler.
 * The profile system gives you a look at how much time each system is using. Hit P
 * to dump to the log the current profile results. You can change the dump key by 
 * setting ProfileSystem.triggerKey at your application boostrap.
 * 
 * - TODO: Remove dependence on other Systems
 * - TODO: Add overall frame rate logging.
 * - TODO: Add percentage of app time not tracked by ProfileSystems 
 */
 class ProfileSystem extends FlaxenSystem
{
	public static var triggerKey:Int = Key.P;

	private var stats:ProfileStats;
	private var profile:Profile;
	private var opener:Bool;

	public function new(flaxen:Flaxen, name:String, opener:Bool)
	{
		super(flaxen);

		this.stats = flaxen.resolveEntity(Flaxen.profilerName).get(ProfileStats);
		this.profile = stats.getOrCreate(name);
		this.opener = opener;
	}

	override public function update(_)
	{	
		if(opener)
			profile.open();
		else profile.close();


		// Press trigger key to dump profiler stats, add SHIFT modifier to instead reset (clear) stats
		if(InputService.lastKey() == triggerKey)
		{
			if(InputService.check(Key.SHIFT))
			{
				Log.log("Resetting profiler stats");
				stats.reset();
			}
			else stats.dump();
			InputService.clearLastKey();
		}
	}
}

class ProfileStats
{
	private var stats:Map<String,Profile>;

	public function new()
	{
		stats = new Map<String, Profile>();
	}

	public function create(name:String): Profile
	{
		var profile = new Profile(name);
		stats.set(name, profile);

		if(stats.get(name) == null)
			Log.error("Creation didn't stick!");

		return profile;
	}

	public function get(name:String): Profile
	{
		return stats.get(name);
	}

	public function getOrCreate(name:String): Profile
	{
		var profile = get(name);
		if(profile == null)
			profile = create(name);
		return profile;
	}

	public function reset(): Void
	{
		for(profile in stats)
		{
			profile.startTime = -1;
			profile.totalTime = 0;
			profile.totalCalls = 0;
		}		
	}

	public function dump()
	{
		var totalTime:Int = 0;
		for(profile in stats)
			totalTime += profile.totalTime;
		
		Log.log("PROFILE:");
		for(name in stats.keys())
			logProfile(name, totalTime);
	}

	public function logProfile(name:String, totalTime:Int)
	{
		var profile = stats.get(name);
		Log.log(name + ": " + 
			format(profile.totalTime / 1000) + 
			" sec overall (" + format(profile.totalTime / totalTime * 100)  +  "%), " + profile.totalCalls + 
			" calls, " + 
			format(profile.totalTime / profile.totalCalls) + 
			"ms/call, " +
			format(profile.totalCalls / profile.totalTime * 1000) +
			" calls/sec");
	}

	public function format(time:Float): String
	{
		return cast com.haxepunk.HXP.round(time, 2);
	}
}

class Profile
{
	public var startTime:Int = -1;
	public var totalTime:Int = 0;	
	public var totalCalls:Int = 0;
	public var name:String;

	public function new(name:String)
	{
		this.name = name;
	}

	public function open(): Profile
	{
		startTime = openfl.Lib.getTimer();
		return this;
	}

	public function close(): Profile
	{
		// Damn you for trying to close a closed profile; you think you're funny wise guy? 
		if(startTime == -1)
			return this;

		var endTime = openfl.Lib.getTimer();
		totalTime += (endTime - startTime);
		totalCalls++;
		startTime = -1;
		return this;
	}
}