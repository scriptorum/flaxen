package flaxen.service;

import openfl.Assets;

#if (development && !flash)
import sys.io.File;
import sys.io.FileOutput;
using DateTools;
#end

class LevelService
{
	public static var FILE:String = "levels.xml";
	public static var ASSETS_PATH:String = "data/" + FILE;
#if (development && !flash)
	public static var SAVE_FOLDER:String = "/Users/elund/Development/reRocket/assets/data/";
	public static var SYSTEM_PATH:String = SAVE_FOLDER + FILE;
#end

	public static var xml:Xml;

	public static function init()
	{
		loadFromAssets();
	}

	public static function loadFromAssets(): Void
	{
		var str:String = Assets.getText(ASSETS_PATH);
		xml = Xml.parse(str).firstElement();
	}

#if (development && !flash)
	public static function loadFromFile(): Void
	{
		var str:String = File.getContent(SYSTEM_PATH);
		xml = Xml.parse(str).firstElement();
	}

	public static function saveToFile(): Void
	{
		backup();
		var str:String = xml.toString();
		var fo:FileOutput = File.write(SYSTEM_PATH);
		fo.writeString(str);
		fo.close();
	}

	public static function backup(): Void
	{
		var dateString = Date.now().format("%Y%m%d%H%M%S");
		var backupPath = SYSTEM_PATH + "." + dateString + ".bak";
		// trace("Backing up " + SYSTEM_PATH + " to " + backupPath);
		File.copy(SYSTEM_PATH, backupPath);
	}
#end

	public static function readLevel(level:Int, throwIfMissing:Bool = true): Xml
	{
		var i=0;
		for(levelXml in xml.elementsNamed("level"))
			if(++i == level)
				return levelXml;

		if(throwIfMissing)
			throw("LevelService.readLevel cannot read level " + level);
		var levelXml =  Xml.createElement("level");
		levelXml.set("id", Std.string(level));
		return levelXml;
	}
}