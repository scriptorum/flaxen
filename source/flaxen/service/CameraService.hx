package flaxen.service;

import ash.core.Entity;
import com.haxepunk.HXP;
import com.haxepunk.Tween;
import com.haxepunk.tweens.TweenEvent;
import com.haxepunk.utils.Ease;
import flaxen.common.Easing;
import flaxen.component.CameraFocus;
import flaxen.Flaxen;
import flaxen.node.CameraFocusNode;
import flaxen.service.InputService;
import openfl.events.MouseEvent;

/**
 * Camera service functions.
 *
 *  - TODO: Add a Camera singleton to abstract the camera's position, scale, shakiness, etc.*
 */
class CameraService
{
	public static var CAMERA_EFFECT:String = "_CameraService_effect";

	private static var _camTween:Tween;
	private static var f:Flaxen;
	private static var x:Float = 0;
	private static var y:Float = 0;

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
		CameraService.x = CameraService.y = 0.0;
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

	public static function getX(): Float return x;
	public static function getY(): Float return y;

	/**
	 * Sets the camera position.
	 * You must use this instead of accessing HXP.camera directly if you intend 
	 * to do any camera effects like the camera shake. The camera defaults to 0,0.
	 * @param x The horizontal position of the camera
	 * @param y The vertical position of the camera
	 */
	public static function move(x:Float, y:Float)
	{
		CameraService.x = x;
		CameraService.y = y;

		if(!f.hasEntity(CAMERA_EFFECT))
			HXP.setCamera(x, y);
	}

	/**
	 * Sets the camera position.
	 * You must use this instead of accessing HXP.camera directly if you intend 
	 * to do any camera effects like the camera shake.
	 * @param x How far to shift the camera horizontally (positive is right)
	 * @param y How far to shift the camera vertically (positive is down)
	 */
	public static function moveRel(xOff:Float, yOff:Float)
	{
		move(CameraService.x + xOff, CameraService.y + yOff);
	}

	/**
	 * Shakes the camera +/- the offset.
	 * Make sure the screen buffer size is (offsetx * 2, offsety * 2) bigger than the window.
	 *
	 * NOTE: If you're going to move the camera while it is shaking, you must use `move`
	 * and `moveRel` to set the camera's position, rather than setting HXP.camera directly.
	 *
	 * @param duration How long to shake the camera in seconds
	 * @param offsetx The horizontal shakiness (0 = no horizontal shake)
	 * @param offsety The vertical shakiness (0 = no vertical shake, null=copies offsetx)
	 */
	public static function shake(duration:Float, offsetx:Float, ?offsety)	
	{
		// Verify values within domain
		Log.assert(duration > 0, "Duration must be positive");

		// Set defaults
		if(offsety == null)
			offsety = offsetx;

		// Disallow overlapping camera effects
		if(f == null || f.hasEntity(CAMERA_EFFECT))
			return; 

		// If using HXP.camera directly, ensure our camera x/y matches HXP's
		CameraService.x = HXP.camera.x;
		CameraService.y = HXP.camera.y;
 
		// Shake camera
		var tween = f.newTween(duration, Easing.random)
			.call(function(f:Float) { HXP.camera.x = CameraService.x + f * offsetx * 2 - offsetx; })
			.call(function(f:Float) { HXP.camera.y = CameraService.y + f * offsety * 2 - offsety; });

		// On complete, restore camera
		f.newActionQueue(true, CAMERA_EFFECT)
			.waitForComplete(tween)
			.call(function() HXP.setCamera(CameraService.x, CameraService.y));
	}
}