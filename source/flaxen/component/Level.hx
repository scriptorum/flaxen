package flaxen.component;

class Level
{
	// Overall stats
	public var progress:Int = 0; // the highest level you've completed
	public var starsMissed:Array<Int>; // stars short of best for each level, -1 if level not attempted
	public var gameOver:Bool = false; // true if got all fireworks on all levels (not necessarily all stars)

	// Stats for current level
	public var max:Int; // max levels
	public var current:Int; // current level 
	public var complete:Bool = false; // true when level is over
	public var validated:Bool = false; // validate level has fireworks/orbs, warn if editing enabled
	public var numRestarts:Int = 0; // used to determine level load animation speed
	public var best:Int = 0; // "best" value for level - number of rocket stars
	public var stars:Int = 0; // stars obtained this level
	public var fails:Int = 0; // fails obtained this level

	public function new(current:Int = 1, max:Int = 30)
	{
		this.current = current;
		this.max = max;
		starsMissed = new Array<Int>();
		for(i in 1...max+1)
			starsMissed[i] = -1;
	}

	public function changeLevel(level:Int)
	{
		current = level;
		complete = false;
		validated = false;
		numRestarts = 0;
		best = 0;
		stars = 0;
		fails = 0;
	}

	public function exportSave(): Dynamic
	{
		var save:Dynamic = { 
			progress:progress,
			gameOver:gameOver,
			starsMissed:starsMissed
		};
		return save;
	}

	public function importSave(save:Dynamic): Bool
	{
		try
		{
			this.progress = save.progress;
			this.current = this.progress + 1;
			this.gameOver = save.gameOver;
			this.starsMissed = save.starsMissed;
		}
		catch(unknown:Dynamic)
		{
			return false;
		}

		return true;
	}

	public function missedAnyStars(): Bool
	{
		var total = 0;
		for(i in 1...max+1)
		{
			if(starsMissed[i] == -1)
				return true;

			if(starsMissed[i] > 0)
				return true;
		}

		return false;
	}

#if cheats
	public function testGotStarted() // played some levels
	{
		gameOver = false;
		progress = 12;
		current = progress + 1;
		for(i in 1...max+1)
		{
			if(i <= 6)
				starsMissed[i] = 0;
			else if(i <= 12) 
				starsMissed[i] = i-6;
			else starsMissed[i] = -1;
		}
	}

	public function testGotToEnd() // played all levels
	{
		gameOver = true;
		progress = max;
		current = progress + 1;
		for(i in 1...current)
		{
			if(i <= 6)
				starsMissed[i] = 0;
			else if(i <= 12)
				starsMissed[i] = 0;
			else starsMissed[i] = i-12;
		}
	}

	public function testGotAllStars() // got all stars
	{
		gameOver = true;
		progress = max;
		current = progress + 1;
		for(i in 1...current)
			starsMissed[i] = 0;
	}
#end
}