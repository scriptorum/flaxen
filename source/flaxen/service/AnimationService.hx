package flaxen.service;

import flaxen.util.Util;

class AnimationService
{
	public static function parseFrames(frames:Dynamic): Array<Int>
	{
		if(Std.is(frames, Array))
				return cast frames;

		if(Std.is(frames, Int))
			return [cast(frames, Int)];

		// Treat as comma-separated string with hyphenated inclusive ranges
		var result = new Array<Int>();
		var tokens = Util.split(frames, ",");
		for(token in tokens)
		{
			// Single number
			if(token.indexOf("-") == -1)
				result.push(Std.parseInt(token));

			// Range of numbers min-max
			else
			{
				var parts = Util.split(token, "-");
				var min = Std.parseInt(parts[0]);
				var max = Std.parseInt(parts[1]);
				for(i in min...max+1)
					result.push(i);			
			}
		}
		return result;
	}
}
