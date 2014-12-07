package flaxen.service;

import com.haxepunk.utils.Key;
import com.haxepunk.utils.Input;
import openfl.events.MouseEvent;

class InputService
{
	public static inline var debug:String = "debug";

	public static function init()
	{
		Input.mouseReleased = false;
		Input.mousePressed = false;
		Input.lastKey = 0;
	}

	public static function onRightClick(cb:Dynamic->Void)
	{
		// RIGHT MOUSE NOT AVAILABLE FOR FLASH??? NOT EVEN 11.2??? C'MON.
		#if !flash
			com.haxepunk.HXP.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, cb);
		#end
	}

	public static function onRightClickRemove(cb:Dynamic->Void)
	{
		#if !flash
			com.haxepunk.HXP.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, cb);
		#end
	}

	// Convenience methods
	public static var mouseX(get, null):Int;
	private static function get_mouseX():Int { return Input.mouseX; }
	public static var mouseY(get, null):Int;
	private static function get_mouseY():Int { return Input.mouseY; }
	public static var clicked(get, null):Bool;
	private static function get_clicked():Bool { return Input.mouseReleased; }

	public static function check(input:InputType):Bool { return Input.check(input); }
	public static function pressed(input:InputType):Bool { return Input.pressed(input); }
	public static function released(input:InputType):Bool { return Input.released(input); }
	public static function lastKey(): Int { return Input.lastKey; }

	public static function clearLastKey(): Void { Input.lastKey = 0; }
}