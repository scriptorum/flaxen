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

    // Same as String.split but empty strings result in an empty array
    // Properly handles null weirdness on Flash
    public static function split(str:String, delim:String): Array<String>
    {
    	var arr = new Array<String>();
    	if(str == null || str.length == 0)
    		return arr;
    	return str.split(delim);
    }
}