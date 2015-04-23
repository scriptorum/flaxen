package flaxen.util;

class StringUtil
{
    public static function isNumeric(str:String): Bool
    {
    	if(str == null)
    		return false;

    	return (~/^\d+$/).match(str);
    }

    public static function isAlpha(str:String): Bool
    {
    	if(str == null)
    		return false;
    		
    	return (~/^[A-Za-z]$/).match(str);
    }

    public static function isAlphaNumeric(str:String): Bool
    {
    	return isNumeric(str) || isAlpha(str);
    }

	/**
	 * Same as String.split but empty strings result in an empty array
	 * Properly handles null weirdness on Flash
	 */
    public static function split(str:String, delim:String): Array<String>
    {
    	var arr = new Array<String>();
    	if(str == null || str.length == 0)
    		return arr;
    	return str.split(delim);
    }

    public static function toInitCase(str:String): String
    {
        return str.substr(0, 1).toUpperCase() + str.substr(1);
    }

    public static function formatCommas(num:Int): String
    {
        if(num < 1000)
            return Std.string(num);

        var tail = Std.string(num % 1000);
        if(tail.length < 3)
            tail = repeat("0", 3 - tail.length) + tail;
        return formatCommas(Std.int(num / 1000)) + "," + tail;
    }

    public static function repeat(toRepeat:String, count:Int): String
    {
        var str:String = "";
        for(i in 0...count)
            str += toRepeat;
        return str;
    }
}