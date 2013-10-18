package flaxen.component;

class CameraFocus
{
	public static var MANUAL_FOCUS_ENTITY:String = "manualCameraFocus";
	public static var instance:CameraFocus = new CameraFocus();
	
	public function new()
	{
	}
}

// To prevent manual focusing
class CameraLock
{
	public static var instance:CameraLock = new CameraLock();
	
	public function new()
	{
	}
}