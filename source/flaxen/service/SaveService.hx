package flaxen.service;

import openfl.net.SharedObject;

class SaveService
{
	public static function load(SO_NAME:String): Dynamic
	{
		var so:SharedObject = SharedObject.getLocal(SO_NAME);
		if(so.data.saveData != null)
			return haxe.Unserializer.run(so.data.saveData);

		return null;
	}

	public static function save(SO_NAME:String, data:Dynamic): Void
	{
		var so:SharedObject = SharedObject.getLocal(SO_NAME);
		so.setProperty("saveData", haxe.Serializer.run(data));
		so.flush();
	}

	public static function clear(SO_NAME:String): Void
	{
		var so:SharedObject = SharedObject.getLocal(SO_NAME);
		so.clear();
	}
}