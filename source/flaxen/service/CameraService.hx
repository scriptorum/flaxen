package flaxen.service;

import ash.core.Entity;
import com.haxepunk.HXP;
import com.haxepunk.Tween;
import com.haxepunk.tweens.TweenEvent;
import com.haxepunk.utils.Ease;
import flaxen.Flaxen;
import flaxen.component.CameraFocus;
import flaxen.node.CameraFocusNode;
import openfl.events.MouseEvent;

/**
 * Camera service functions.
 *
 *  - TODO: Add a Camera singleton to abstract the camera's position, scale, shakiness, etc.*
 */
class CameraService
{
	private static var _camTween:Tween;
	private static var f:Flaxen;

	public static function init(f:Flaxen)
	{
		CameraService.f = f;
		//InputService.onRightClick(animCameraToClick);
	}

	public static function animCameraToClick(evt:MouseEvent)
	{
		animCameraRel(InputService.mouseX - HXP.halfWidth, InputService.mouseY - HXP.halfHeight, .65);
	}

	public static function animCameraRel(x, y, duration)
	{
		animCameraTo(HXP.camera.x + x, HXP.camera.y + y, duration);
	}

	public static function animCameraTo(x, y, duration)
	{
		stopAnim();
		_camTween = HXP.tween(HXP.camera, { x:x, y:y }, duration, 
			{ ease: Ease.expoOut, complete:cameraTweenFinish });
	}

	public static function reset(): Void
	{
		HXP.resetCamera();
	}

	private static function cameraTweenFinish(evt:TweenEvent)
	{
		_camTween = null;
	}

	public static function stopAnim(): Void
	{
		if(_camTween == null)
			return;

		HXP.tweener.removeTween(_camTween);

		_camTween = null;
	}

	public static function changeCameraFocus(entity:Entity): Void
	{
		for(node in f.ash.getNodeList(CameraFocusNode))
			node.entity.remove(CameraFocus);

		if(entity != null)
			entity.add(CameraFocus.instance);			
	}

	inline public static function getX(): Float return HXP.camera.x;
	inline public static function getY(): Float return HXP.camera.y;

	/**
	 * Convenience method. Sets the absolute camera position.
	 * @param x The horizontal position of the camera
	 * @param y The vertical position of the camera
	 */
	public static function move(x:Float, y:Float)
	{
		HXP.setCamera(x, y);
	}

	/**
	 * Convenience method. Sets the relative camera position.
	 * @param x How far to shift the camera horizontally (positive is right)
	 * @param y How far to shift the camera vertically (positive is down)
	 */
	public static function moveRel(xOff:Float, yOff:Float)
	{
		move(CameraService.getX() + xOff, CameraService.getY() + yOff);
	}

	/**
	 * Shakes the screen +/- the magnitude.
	 *
	 * @param duration How long to shake the camera in seconds
	 * @param magnitue The amount of shakiness
	 */
	public static function shake(magnitude:Int, duration:Float)
	{
		HXP.screen.shake(magnitude, duration);
	}
}