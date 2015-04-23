package flaxen.util;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
using haxe.macro.ExprTools; // e1.toString
#end

/**
 *   Some useful Haxe 3 macros.
 */
class Macro
{
    /** Throws a compilation error */
    macro public static function error(msg:String = "Unknown error"):Dynamic
    {
        return Context.error(msg, Context.currentPos());
    }

    /** Swaps the value of two variables, in place */
    macro public static function swap(e1:Expr, e2:Expr):Expr
    {
        var s:String = "{ var c = " + e1.toString() + "; " 
            + e1.toString() + " = " + e2.toString() + "; " 
            + e2.toString() + " = c; }";
        return Context.parse(s, Context.currentPos());
    }

	/**
	 * Populates a class with a constructor and a single instance assigned to a field
	 * Example of use:
     * ```
	 * @:build(flaxen.util.Macro.buildSingleton()) class MyEntity 
	 * {
	 *     public var anotherField:Int = 55;
	 *     public function anotherFunc() {}
	 * }
	 * trace(MyEntity.instance.anotherField); // 55
     * ```
	 * If you want to define your own constructor in the class, pass false for the second param.
     * Otherwise, you can initialize the class through functions or direct variable manipulation.
	 */
    #if macro
    public static function buildSingleton(fieldName:String = "instance", 
        includeConstructor:Bool = true): Array<Field>
    {
        var pos = Context.currentPos();
        var fields = Context.getBuildFields();
        var clazz:String = Context.getLocalClass().get().name;

        // private function new() { }
        if(includeConstructor)
            fields.push({ name:"new", doc:null, pos:pos, access:[APrivate], meta:[],
                kind:FFun({ args:[], params:[], ret:null, expr:{ pos:pos, expr:EBlock([]) } }) });

        // public static function instance:CLASSNAME = new CLASSNAME();
        fields.push({ name:${fieldName}, doc:null, pos:pos, access:[AStatic, APublic], meta:[],
            kind:FVar(TPath({ name:clazz, pack:[], params:[] }),
            { expr:ENew({ params:[], pack:[], name:clazz }, []), pos:pos }) });

        return fields;
    }
    #end
}