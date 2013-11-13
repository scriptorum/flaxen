package flaxen.core;

class Log
{
	public static inline function log(msg:String)
	{
		trace(msg);
	}

	public static inline function warn(msg:String)
	{
		#if debug
			trace(msg);
		#end
	}

	public static inline function error(msg:String)
	{
		throw msg;
	}
}