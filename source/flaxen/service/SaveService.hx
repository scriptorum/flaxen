package flaxen.service;

import flash.net.SharedObject;

class SaveService
{
	private static var SO_NAME:String = "reRocket";

	public static function load(): Dynamic
	{
		var so:SharedObject = SharedObject.getLocal(SO_NAME);
		if(so.data.saveData != null)
			return haxe.Unserializer.run(so.data.saveData);

		return null;
	}

	public static function save(data:Dynamic): Void
	{
		var so:SharedObject = SharedObject.getLocal(SO_NAME);
		so.setProperty("saveData", haxe.Serializer.run(data));
		so.flush();
	}

	public static function clear(): Void
	{
		var so:SharedObject = SharedObject.getLocal(SO_NAME);
		so.clear();
	}
}