package flaxen.util;

import flaxen.core.Log;

class DynUtil
{
    // Primary, this method parses a range string into an array of integers. 
    // For example: 2,4-7,9 returns [2,4,5,6,7,9].
    // However, if an array is passed, this will return that array as is.
    // And if an Int is passed, this will return [theInt].
    public static function parseRange(range:Dynamic): Array<Int>
    {
        if(Std.is(range, Array))
                return cast range;

        if(Std.is(range, Int))
            return [cast(range, Int)];

        if(!Std.is(range, String))
            Log.error("Range string must be comma separated values: integers and hyphenated ranges");

        // Treat as comma-separated string with hyphenated inclusive ranges
        var result = new Array<Int>();
        var tokens = StringUtil.split(range, ",");
        for(token in tokens)
        {
            // Single number
            if(token.indexOf("-") == -1)
                result.push(Std.parseInt(token));

            // Range of numbers min-max
            else
            {
                var parts = StringUtil.split(token, "-");
                var min = Std.parseInt(parts[0]);
                var max = Std.parseInt(parts[1]);
                for(i in min...max+1)
                    result.push(i);         
            }
        }
        return result;
    }  

    inline public static function nonNull(value:Dynamic, nullValue:Dynamic): Dynamic
    {
        return (value == null ? nullValue: value);
    }
}