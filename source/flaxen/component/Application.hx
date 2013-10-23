package flaxen.component;

enum ApplicationModeType<T>
{ 
	// The app starts in this mode; if you're using application modes, initialize this mode
	// in ModeSystem and then transition to Play, Menu or whatever mode you want.
	Init; 	

	// This is not an application mode and should not be transitioned to.
	// When supplied to a Transitional object, it indicates an entity is 
	// protected and will always survive transitions
	Always;

	// These are built-in modes, use them if you like or define your own with custom
	Menu; Play; Credits; Select; Options; Cutscene; Gameover;

	// Define your own application modes here, such as Mode("LoadingScreen")
	Mode(value:T); 
} 

typedef ApplicationMode = ApplicationModeType<String>;

class Application
{
	public var nextMode:ApplicationMode;
	public var currentMode:ApplicationMode;

	public function new()
	{
		changeMode(Init);		
	}

	public function changeMode(mode:ApplicationMode): Void
	{
		this.nextMode = mode;
	}

	public function modeInitialized(): Bool
	{
		return nextMode == currentMode;
	}
}

