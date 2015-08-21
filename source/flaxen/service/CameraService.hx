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

	/**
	 * Shakes the camera +/- the offset.
	 * Make sure the screen buffer size is (offsetx * 2, offsety * 2) bigger than the window.
	 *
	 * @param duration How long to shake the camera in sec; resets camera offset to 0,0 when complete
	 * @param offsetx The horizontal shakiness (0 = no horizontal shake)
	 * @param offsety The vertical shakiness (0 = no vertical shake, null=copies offsetx)
	 *  - TODO: Takes complete control of camera while shaking - add ability to move camera WHILE shaking
	 */
	public static function shake(duration:Float, offsetx:Float, ?offsety)	
	{
		Log.assert(duration > 0, "Duration must be positive");
		if(offsety == null)
			offsety = offsetx;
		offsetx = Math.abs(offsetx) * offsetx;
		offsety = Math.abs(offsety) * offsety;

		// Shake camera
		var tween = f.newTween(duration, Easing.random)
			.to(HXP.camera, "x", offsetx, -offsetx)
			.to(HXP.camera, "y", offsety, -offsety);

		// On complete, restore camera
		f.newActionQueue()
			.waitForComplete(tween)
			.setProperty(HXP.camera, "x", HXP.camera.x)
			.setProperty(HXP.camera, "y", HXP.camera.y);
	}
}