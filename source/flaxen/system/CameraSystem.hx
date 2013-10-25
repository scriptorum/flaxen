
package flaxen.system;

import com.haxepunk.HXP;
import flaxen.core.FlaxenSystem;
import flaxen.component.CameraFocus;
import flaxen.component.Position;
import flaxen.component.Application;
import flaxen.service.CameraService;
import flaxen.node.CameraFocusNode;
import flaxen.util.MathUtil;

class CameraSystem extends FlaxenSystem
{
	private var targetX:Float = 0;
	private var targetY:Float = 0;
	private var i:Int = 0;

	override public function update(_)
	{
		var x:Float = 0;
		var y:Float = 0;

		// If mode is changing, immediately reset camera to 0,0
		var app = flaxen.getApp();
		if(app.modeInitialized())
		{
			HXP.camera.x = targetX = HXP.camera.y = targetY = 0;
			CameraService.stopAnim();
			return;
		}

		// var manualFocus:Bool = false;
	 	for(node in ash.getNodeList(CameraFocusNode))
	 	{
	 		// if(node.entity.name == CameraFocus.MANUAL_FOCUS_ENTITY)
	 		// 	manualFocus = true;

	 		x = node.position.x - HXP.halfWidth;
	 		y = node.position.y - HXP.halfHeight;
	 		break;	 		
	 	}

		if(MathUtil.diff(x, targetX) >= 0.5 || MathUtil.diff(y, targetY) >= 0.5)
		{
			targetX = x;
			targetY = y;
			CameraService.animCameraTo(targetX, targetY, 0.8);
		}	 	

		// if(HXP.camera.x != targetX || HXP.camera.y != targetY)
		// {
		// }
	}
}