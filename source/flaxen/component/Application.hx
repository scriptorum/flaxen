package flaxen.component;


// TODO Put in explanation of how to define and use custom application mode
// TODO Implement Next transition
enum ApplicationModeType<T>
{ 
	Init; 	// initial mode; initialize as needed, then transition to Play, Menu or whatever mode you want	
	Always; // not a real mode; used to indicate an entity should always survive transition
	Next; 	// not a real mode; used to indicate an entity should survive next transition
	Custom(value:T); // define your own application modes here

	// These are built-in modes, use them if you like or define your own
	menu; Play; Credits; Select; Options; Cutscene; Gameover;
} 
typedef ApplicationMode = ApplicationModeType<String>;

class Application
{
	public var mode:ApplicationMode;
	public var initialized:Bool = false;

	public function new()
	{
		changeMode(Init);		
	}

	public function changeMode(mode:ApplicationMode): Void
	{
		this.mode = mode;
		this.initialized = false;
	}
}

// When transitioning from one application mode to another, all entities are destroyed, unless they are 
// protected: Transitional entities are protected if their transitional mode is Always or matches the 
// mode being transitioned to. 
class Transitional
{
	public static var ALWAYS:Transitional = new Transitional(Always);

	public var mode:ApplicationMode;  // application mode where this entity is protected
	public var destroyComponent:Bool; // true to remove this component when complete
	public var complete:Bool = false; // marked true when protected during transition
	public var kind:String; 		  // generic classification of transitions

	public function new(mode:ApplicationMode, destroyComponent:Bool = false)
	{	
		if(mode == null)
			throw "ApplicationMode cannot be null";

		this.mode = mode;
		this.destroyComponent = destroyComponent;
	}

	// Returns true if this entity should be protected
	public function isProtected(mode:ApplicationMode): Bool
	{
		return (this.mode == mode || 
			this.mode == Always);
	}

	// Returns true if this entity was protected during a transition, with the exception of Always (null)
	// transitions, which never really complete so always return false.
	public function isCompleted(): Bool
	{
		return complete && mode != null;
	}

	public function setKind(kind:String): Transitional
	{
		this.kind = kind;
		return this;
	}
}
