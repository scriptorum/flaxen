/**
    TODO
        - Add rev (reverse in place) and getRev (return reversed output)
        - Add merge (concat in place) and getMerge (return concatenated output)
*/
package flaxen.util;

class ArrayUtil
{
	public static function shuffle<T>(arr:Array<T>): Void
	{
        var i:Int = arr.length, j:Int, t:T;
        while (--i > 0)
        {
                t = arr[i];
                arr[i] = arr[j = MathUtil.rnd(0, arr.length - 1)];
                arr[j] = t;
        }
	}

	public static function anyOneOf<T>(arr:Array<T>): T
	{
		if(arr == null || arr.length == 0)
			return null;
		return arr[MathUtil.rnd(0, arr.length - 1)];
	}

    // Like Array.filter but returns an array of indeces to the array (keys), rather than the array valuentityService.
    // Also, the comparison func receives an array index, not an array value.
    public static function indexFilter<T>(arr:Array<T>, func:Int->Bool): Array<Int>
    {
    	var result = new Array<Int>();
    	for(i in 0...arr.length)
    	{
    		if(func(i))
    			result.push(i);
    	}
    	return result;
    }

    public static function find<T>(arr:Array<T>, obj:T): Int
    {
    	for(i in 0...arr.length)
    		if(arr[i] == obj)
    			return i;
    	return -1;
    }

    public static function contains<T>(arr:Array<T>, obj:T): Bool
    {
    	return (find(arr, obj) != -1);
    }
}