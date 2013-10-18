package flaxen.component;

class Layer
{
	public static var BACK:Int = 200;
	public static var LEVEL_TITLE:Int = 190;
	public static var LEVEL_TEXT:Int = 190;
	public static var FIREWORK_FX:Int = 185;
	public static var FIREWORK:Int = 180;
	public static var FIREWORK_TEXT:Int = 170;
	public static var BOOSTER:Int = 165;
	public static var BARREL:Int = 160;
	public static var TUBE:Int = 150;
	public static var THUMB_BACK:Int = 150;
	public static var BARREL_TEXT:Int = 140;
	public static var ROCKET:Int = 130;
	public static var THUMB_FRONT:Int = 120;
	public static var FUSE_FX:Int = 120;
	public static var SMOKE_FX:Int = 120;
	public static var CLOUD:Int = 110;
	public static var MID_HUD:Int = 110;
	public static var THUMB_STAR:Int = 100;
	public static var TEXT_POP:Int = 90;
	public static var SIGN:Int = 80;
	public static var STAR:Int = 70;
	public static var THUMB_STAR_TEXT:Int = 70;
	public static var TUTE_POP:Int = 60;
	public static var TUTE_TEXT:Int = 50;
	public static var HUD:Int = 40;
	public static var EDITOR_OBJECT:Int = 30;

	public var layer:Int;

	public function new(layer:Int)
	{
		this.layer = layer;
	}
}