package flaxen.util;

class MathUtil
{
	/**
	 * Returns a random integer between a and b, inclusive. B must be higher than a.
	 * If b is null, returns a random integer between 0 and a.
	 */
	inline public static function rndInt(a:Int, ?b:Int): Int
	{ 
		if(b == null)
			return rndInt(0, a);

		return (Math.floor(Math.random() * (b - a + 1) + a));
	}

	/**
	 * Returns a random float between a and b. B must be higher than a.
	 * If b is null, returns a random float between 0 and a.
	 */
	inline public static function rnd(a:Float, ?b:Float): Float
	{
		if(b == null)
			return rnd(0.0, a);

		return (Math.random() * (b - a) + a);
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

	public static function min<T:Float,Int>(a:T, b:T): T
	{
		return (a < b ? a : b);
	}

	public static function max<T:Float,Int>(a:T, b:T): T
	{
		return (a > b ? a : b);
	}

	public static function abs<T:Float,Int>(num:T): T
	{
		return (num < 0 ? -num : num);
	}

    public static function diff<T:Float,Int>(a:T, b:T): T
    {
        return (a > b ? a - b : b - a);
    }

    public static function isEven(a:Int): Bool
    {
    	return (Math.floor(a/2)*2) == a;
    }

	/**
	 * Returns true if both floats match within tolerance decimal places.
	 */
    public static function matches(a:Float, b:Float, tolerance:Int = 0): Bool
    {
        return (roundTo(a, tolerance) == roundTo(b, tolerance));
    }
}