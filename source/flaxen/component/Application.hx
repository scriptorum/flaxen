package flaxen.component;

enum ApplicationModeType<T>
{ 
	// The app starts in this mode; if you're using application modes, you can initialize your
	// app in ModeSystem and then transition to Play, Menu or whatever mode you want.
	Default;

	// This is not an application mode and should not be transitioned to. When supplied to a 
	// Transitional object, it indicates an entity is protected and will always survive 
	// transitions. When supplied with a start/stop/update handler, indicates the handler
	// will always be called, regardless of mode. See Flaxen.setHandler.
	Always;

	// These are built-in modes, use them if you like or define your own with custom
	Init; Intro; Menu; Play; Credits; Select; Options; CutScene; GameOver; Success; Failure;

	// Define your own application modes here, such as Mode("LoadingScreen")
	Mode(value:T); 
} 

typedef ApplicationMode = ApplicationModeType<String>;

class Application
{
	public var nextMode:ApplicationMode; // queued up the next mode, will change curMode
	public var curMode:ApplicationMode; // the current mode
	public var prevMode:ApplicationMode; // the previous mode; could reference in start handler

	public function new()
	{
		changeMode(Default);
	}

	public function changeMode(mode:ApplicationMode): Void
	{		
		this.nextMode = mode;
	}

	public function modeInitialized(): Bool
	{
		return nextMode == null;
	}
}

