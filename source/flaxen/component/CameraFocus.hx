package flaxen.component;

import flaxen.component.StaticComponent;

/** 
 * To focus on an entity, that entity must contain a Position component.
 * See CameraService.
 */
class CameraFocus extends StaticComponent
{
	public static var MANUAL_FOCUS_ENTITY:String = "manualCameraFocus";
}

/**
 * To temporarily prevent manual focusing, you can lock the camera.
 * THIS IS NOT CURRENTLY IN USE
 */
class CameraLock extends StaticComponent
{
}