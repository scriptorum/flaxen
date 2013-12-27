/*
	TODO
		- Move to common?
		- Rename to Sys/System?
*/
package flaxen.core;

import haxe.CallStack;

class Log
{
	inline public static function write(msg:String)
	{
		log(msg);
	}

	// TODO Support configuration of log file to write to instead of/in addition to console.
	// TODO Report actual position of INLINE log, instead of position of this function. :( 
	//	    Possible? Look into Context and macros.
	inline public static function log(msg:String)
	{
		trace(msg);
	}

	inline public static function warn(msg:String)
	{
		#if debug
			trace(msg);
		#end
	}

	inline public static function die(?msg:String) // alias for error
	{
		return error(msg);
	}

	public static function error(msg:String = "Unspecified error")
	{
		throw(msg);
	}

	inline public static function assert(condition:Bool, ?msg:String = "Assert failed")
	{
		if(condition != true)
			error(msg);
	}

	inline public static function assertNonNull(object:Dynamic, ?msg:String = "Null assertion failed")
	{
		assert(object != null, msg);
	}

	// Debug assert - asserts only checked in debug mode
	inline public static function debugAssert(condition:Bool, ?msg:String)
	{		
		#if debug
			assert(condition, msg);
		#end
	}

	public static function quit()
	{
		#if (cpp || neko)
			flash.Lib.exit();
		#end
	}
}