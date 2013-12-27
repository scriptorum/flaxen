package flaxen.component;

import flaxen.component.StaticComponent;

// To focus on an entity, that entity must contain a Position component
class CameraFocus extends StaticComponent
{
	public static var MANUAL_FOCUS_ENTITY:String = "manualCameraFocus";
}

// To prevent manual focusing
class CameraLock extends StaticComponent
{
}