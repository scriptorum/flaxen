package flaxen.util;

#if native
import sys.io.File;
import sys.io.FileOutput;
#end

import flaxen.util.ArrayUtil;
import haxe.rtti.Meta;

/**
 * This and Log should really be merged, and some things from Log should move to SystemUtil or something.
 */ 
class LogUtil
{
    public static function dumpLog(flaxen:flaxen.Flaxen, filename:String, depth:Int = 1, preventRecursion = true): Void
    {
        #if native
            var fo:FileOutput = File.write(filename);
            fo.writeString(dumpEntities(flaxen, depth, preventRecursion));
            fo.close();
        #else
           haxe.Log.trace("dumpLog not supported for this target");
        #end
    }

    public static function dumpEntities(flaxen:flaxen.Flaxen, depth:Int = 1, preventRecursion = true): String
    {
        var result:String = flaxen.countEntities() + " ASH ENTITIES:\n";
        for(entity in flaxen.ash.entities)
            result += dumpEntity(entity, depth, preventRecursion) + "\n";
        return result;
    }

    public static function assert(cond: Bool, ?pos:haxe.PosInfos)
    {
        if(!cond)
           haxe.Log.trace("Assert in " + pos.className + "::" + pos.methodName, pos);
    }

    public static function dumpEntity(entity:ash.core.Entity, depth:Int = 1, preventRecursion = true): String
    {
    	var result = entity.name + ":{\n";
    	var sep = "  ";
    	for(c in entity.getAll())
    	{
    		result += sep + dump(c, depth, preventRecursion, "    ");
    		sep = ",\n  ";
    	}
    	return result + "}";
    }

    public static function dumpHaxePunk(?scene:com.haxepunk.Scene): String
    {
        if(scene == null)
            scene = com.haxepunk.HXP.scene;
            
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

	public static function dump(o:Dynamic, depth:Int = 1, preventRecursion = true, indent:String = ""): String
	{
		var recursed = (preventRecursion == false ? null : new Array<Dynamic>());
		return internalDump(o, recursed, depth, indent);
	}

	/**
	 * The <RECURSION> check isn't quite that - it will say RECURSION if it's not recursed,
	 * but there are multiple copies within the same object. TODO: Change to <DUPE>?
	 * This doesn't seem to be working in Flash targets.
	 */
	private static function internalDump(o:Dynamic, recursed:Array<Dynamic>, depth:Int, indent:String = ""): String
	{
		if (o == null)
			return "<NULL>";

        if(Reflect.isFunction(o))
            return null; // Not instance data, skip

		if(Std.is(o, Int) || Std.is(o, Float) || Std.is(o, Bool) || Std.is(o, String) 
                || Reflect.isEnumValue(o))
			return Std.string(o);

		if(recursed != null && ArrayUtil.find(recursed, o) != -1)
		 	return "<RECURSION>";

		var clazz = Type.getClass(o);
		if(clazz == null)
			return "<" + Std.string(Type.typeof(o)) + ">";
		
		if(recursed != null)
			recursed.push(o);

		if(depth == 0)
			return "<MAXDEPTH>";

		var result = Type.getClassName(clazz) + ":{";
        var meta = Meta.getFields(clazz);
		var sep = "\n" + indent;
		for(f in Type.getInstanceFields(clazz))
		{
            var dump:String = null;
            var fieldMeta:Dynamic = Reflect.field(meta, f);

            if(fieldMeta != null && Reflect.hasField(fieldMeta, "nodump")) // @nodump on field
                dump = "[" + Reflect.field(o, f)+ "]";  // @nodump? Just report object type
			else dump = internalDump(Reflect.field(o, f), recursed, depth - 1, indent + "  ");

            if(dump != null)
            {
                result += sep + '$f:$dump';
                sep = ",\n" + indent;
            }
		}
		return result + "}";
	}
}