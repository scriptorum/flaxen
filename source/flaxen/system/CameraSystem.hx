
package flaxen.system;

import ash.core.Engine;
import ash.core.System;
import ash.core.Node;

import com.haxepunk.HXP;

import flaxen.component.CameraFocus;
import flaxen.component.Position;
import flaxen.component.Application;
import flaxen.service.CameraService;
import flaxen.service.EntityService;
import flaxen.node.CameraFocusNode;
import flaxen.util.Util;

class CameraSystem extends System
{
	public var engine:Engine;
	public var factory:EntityService;

	private var targetX:Float = 0;
	private var targetY:Float = 0;
	private var i:Int = 0;

	public function new(engine:Engine, factory:EntityService)
	{
		super();
		this.engine = engine;
		this.factory = factory;
	}

	override public function update(_)
	{
		var x:Float = 0;
		var y:Float = 0;

		// If mode is changing, immediately reset camera to 0,0
		var app = factory.getApplication();
		if(app.init)
		{
			HXP.camera.x = targetX = HXP.camera.y = targetY = 0;
			CameraService.stopAnim();
			return;
		}

		// var manualFocus:Bool = false;
	 	for(node in engine.getNodeList(CameraFocusNode))
	 	{
	 		// if(node.entity.name == CameraFocus.MANUAL_FOCUS_ENTITY)
	 		// 	manualFocus = true;

	 		x = node.position.x - HXP.halfWidth;
	 		y = node.position.y - HXP.halfHeight;
	 		break;	 		
	 	}

		if(Util.diff(x, targetX) >= 0.5 || Util.diff(y, targetY) >= 0.5)
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