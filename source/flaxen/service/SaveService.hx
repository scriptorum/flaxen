package flaxen.service;

import openfl.net.SharedObject;

class SaveService
{
	public static function load(name:String): Dynamic
	{
		var so:SharedObject = SharedObject.getLocal(name);
		if(so.data.saveData != null)
			return haxe.Unserializer.run(so.data.saveData);

		return null;
	}

	public static function save(name:String, data:Dynamic): Void
	{
		var so:SharedObject = SharedObject.getLocal(name);
		so.setProperty("saveData", haxe.Serializer.run(data));
		so.flush();
	}

	public static function clear(name:String): Void
	{
		var so:SharedObject = SharedObject.getLocal(name);
		so.clear();
	}
}