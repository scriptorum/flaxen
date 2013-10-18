package flaxen.util;

#if (development && !flash)
import sys.io.File;
import sys.io.FileOutput;
#end

/*
 * Some general purpose Haxe functions.
 * Notably includes integer versions of some standard float Math funcs.
 * TODO Split into separate Util classes by usage or first parameter (for mixins)
 */
class Util
{
	public static function shuffle<T>(arr:Array<T>): Void
	{
        var i:Int = arr.length, j:Int, t:T;
        while (--i > 0)
        {
                t = arr[i];
                arr[i] = arr[j = rnd(0, i-1)];
                arr[j] = t;
        }
	}

	public static function anyOneOf<T>(arr:Array<T>): T
	{
		if(arr == null || arr.length == 0)
			return null;
		return arr[rnd(0, arr.length - 1)];
	}

	public static function rnd(min:Int,max:Int):Int
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

    public static function assert( cond : Bool, ?pos : haxe.PosInfos )
    {
      if(!cond)
          haxe.Log.trace("Assert in " + pos.className + "::" + pos.methodName, pos);
    }

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
    public static function split(str:String, delim:String): Array<String>
    {
    	var arr = new Array<String>();
    	if(str == null || str.length == 0)
    		return arr;
    	return str.split(delim);
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

    public static function dumpEntity(entity:ash.core.Entity, depth:Int = 1, preventRecursion = true): String
    {
    	var result = entity.name + ":{\n";
    	var sep = "";
    	for(c in entity.getAll())
    	{
    		result += sep + dump(c, depth, preventRecursion);
    		sep = ",\n";
    	}
    	return result + "}";
    }

    public static function dumpHaxePunk(scene:com.haxepunk.World): String
    {
    	var ret = "HAXEPUNK ENTITIES:\n";
    	var arr = new Array<com.haxepunk.Entity>();
    	scene.getAll(arr);
    	for(e in arr)
    	{
    		if(e.name != null && e.name != "")
    			ret += e.name + " ";
    		ret += e.x +"," + e.y + " " + e.width +"x" + e.height;
    		ret += ":\n";
    		var list = new Array();
    		if(Std.is(e.graphic, com.haxepunk.graphics.Graphiclist))
    			list = cast(e.graphic, com.haxepunk.graphics.Graphiclist).children;
    		else list.push(e.graphic);
    		for(g in list)
    			ret += " - " + Std.string(Type.typeof(g)) + " " + 
    				(Std.is(g,com.haxepunk.graphics.Text) ? cast(g,com.haxepunk.graphics.Text).text : "") + "\n";
    	}
    	return ret;
    }

    public static function dumpLog(engine:ash.core.Engine, filename:String, depth:Int = 1, preventRecursion = true): Void
    {
		#if (development && !flash)
			var fo:FileOutput = File.write(filename);
			fo.writeString("ASH ENTITIES:\n");
	    	for(entity in engine.entities)
	    	{
				var str:String = dumpEntity(entity, depth, preventRecursion);
				fo.writeString(str + "\n");
	    	}
		#end
    }

	public static function dump(o:Dynamic, depth:Int = 1, preventRecursion = true): String
	{
		var recursed = (preventRecursion == false ? null : new Array<Dynamic>());
		return internalDump(o, recursed, depth);
	}

	private static function internalDump(o:Dynamic, recursed:Array<Dynamic>, depth:Int): String
	{
		if (o == null)
			return "<NULL>";

		if(Std.is(o, Int) || Std.is(o, Float) || Std.is(o, Bool) || Std.is(o, String))
			return Std.string(o);

		if(recursed != null && Util.find(recursed, o) != -1)
		 	return "<RECURSION>";

		var clazz = Type.getClass(o);
		if(clazz == null)
			return "<" + Std.string(Type.typeof(o)) + ">";
		
		if(recursed != null)
			recursed.push(o);

		if(depth == 0)
			return "<MAXDEPTH>";

		var result = Type.getClassName(clazz) + ":{";
		var sep = "";

		for(f in Reflect.fields(o))
		{
			result += sep + f + ":" + internalDump(Reflect.field(o, f), recursed, depth - 1);
			sep = ", ";
		}
		return result + "}";
	}
}