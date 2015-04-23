package flaxen.service;

import ash.core.Entity;
import flaxen.component.CameraFocus;
import flaxen.core.Flaxen;
import flaxen.node.CameraFocusNode;
import flaxen.service.InputService;
import com.haxepunk.utils.Ease;
import com.haxepunk.Tween;
import com.haxepunk.tweens.TweenEvent;
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
		//InputService.onRightClick(rightClick);
	}

	public static function rightClick(evt:MouseEvent)
	{
		animCameraRel(InputService.mouseX - com.haxepunk.HXP.halfWidth, InputService.mouseY - com.haxepunk.HXP.halfHeight, .65);
	}

	public static function animCameraRel(x, y, duration)
	{
		animCameraTo(com.haxepunk.HXP.camera.x + x, com.haxepunk.HXP.camera.y + y, duration);
	}

	public static function animCameraTo(x, y, duration)
	{
		stopAnim();
		_camTween = com.haxepunk.HXP.tween(com.haxepunk.HXP.camera, { x:x, y:y }, duration, 
			{ ease: Ease.expoOut, complete:cameraTweenFinish });
	}

	private static function cameraTweenFinish(evt:TweenEvent)
	{
		_camTween = null;
	}

	public static function stopAnim(): Void
	{
		if(_camTween == null)
			return;

		com.haxepunk.HXP.tweener.removeTween(_camTween);

		_camTween = null;
	}

	public function changeCameraFocus(entity:Entity): Void
	{
		for(node in f.ash.getNodeList(CameraFocusNode))
			node.entity.remove(CameraFocus);

		if(entity != null)
			entity.add(CameraFocus.instance);			
	}	
}