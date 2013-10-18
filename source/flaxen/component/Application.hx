package flaxen.component;

enum ApplicationMode { INIT; MENU; GAME; END; }

class Application
{
	public var mode:ApplicationMode;
	public var init:Bool;

	public function new()
	{
		changeMode(ApplicationMode.INIT);		
	}

	public function changeMode(mode:ApplicationMode): Void
	{
		this.mode = mode;
		this.init = true;
	}
}

// When transitioning from one mode to another, all entities are destroyed, unless they are protected.
// Transitional entities are protected if their transitional mode is ALWAYS or matches the mode being
// transitioned to. 
class Transitional
{
	public static var ALWAYS:Transitional = new Transitional(null);
	public var mode:ApplicationMode;  // application mode where this entity is protected, or null for ALWAYS
	public var destroyComponent:Bool; // true to remove this component when complete
	public var complete:Bool = false; // marked true when protected during transition
	public var kind:String; 		  // generic classification of transitions

	public function new(mode:ApplicationMode, destroyComponent:Bool = false)
	{	
		this.mode = mode;
		this.destroyComponent = destroyComponent;
	}

	// Returns true if this entity should be protected
	public function isProtected(mode:ApplicationMode): Bool
	{
		return (this.mode == null || this.mode == mode);
	}

	// Returns true if this entity was protected during a transition, with the exception of ALWAYS (null)
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
