package flaxen.util;

class MathUtil
{
	public static function rnd(min:Int, max:Int): Int
	{
		return Math.floor(Math.random() * (max - min + 1)) + min;
	}	

    public static function roundTo(value:Float, precision:Int): Float
    {
        var factor = Math.pow(10, precision);
        return Math.round(value*factor) / factor;
    }

	public static function sign(v:Float): Int
	{
		if(v < 0.0)
			return -1;
		if(v > 0.0)
			return 1;
		return 0;
	}

	public static function isign(i:Int): Int
	{		
		if(i == 0)
			return 0;
		return i < 0 ? -1 : 1;
	}

	public static function imin(a:Int, b:Int): Int
	{
		return (a < b ? a : b);
	}

	public static function imax(a:Int, b:Int): Int
	{
		return (a > b ? a : b);
	}

	public static function iabs(num:Int): Int
	{
		return (num < 0 ? -num : num);
	}

    public static function idiff(a:Int, b:Int): Int
    {
        return (a > b ? a - b : b - a);
    }

    public static function diff(a:Float, b:Float): Float
    {
        return (a > b ? a - b : b - a);
    }

    // Returns true if both numbers match withing tolerance decimal placentityService.
    public static function matches(a:Float, b:Float, tolerance:Int = 0): Bool
    {
        return (roundTo(a, tolerance) == roundTo(b, tolerance));
    }
}