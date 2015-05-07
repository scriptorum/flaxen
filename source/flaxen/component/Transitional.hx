package flaxen.component;

import flaxen.common.Completable;
import flaxen.common.OnCompleteTransition;
import flaxen.component.Application;
import flaxen.Log;

/**
 * When transitioning from one application mode to another, all entities are destroyed, unless they are 
 * protected: Transitional entities are protected if their transitional mode is Always, Next, or 
 * matches the mode being transitioned to.
 * 
 * To transition the application to a new mode:
 *   flaxen.setMode(Play);
 * 
 * For a custom mode, a typedef is helpful:
 *    import flaxen.component.Application;
 *    typedef ConfigController = Mode("ConfigController");
 *    flaxen.setMode(ConfigController);
 *
 * To protect an entity from being removed when the mode changes:
 *    entity.add(Transitional.ALWAYS); // Never will be removed
 *    entity.add(Transitional.NEXT); // Will be protected through transition to next mode, only, then protection is removed
 *    entity.add(new Transitional(Play)); // Will be protected only if next mode matches this mode
 *
 *  - TODO: The entire "transitional" system needs to be made clearer and cleaner. Also, the mode system needs to support
 *      layered/stacked modes. For example, hitting ESC brings an options window, and selecting calibrate controller 
 * 		brings an additional window. The original content is not removed in these cases although they may be "paused" or 
 * 		otherwise recognize their activity has been commandeered. Hitting ESC progressively "unstacks" the layered modes.
 */
class Transitional implements Completable
{
	public static var ALWAYS:Transitional = new Transitional(Always);
	public static var NEXT:Transitional = new Transitional(Always, DestroyComponent);

	/** Application mode where this entity is protected */
	public var mode:ApplicationMode;  

	/** When this transition completes, what action do we take? */
	public var onComplete:OnCompleteTransition; 

	/** Marked true when protected during transition */
	public var complete:Bool = false; 

	/** Optional classification of transitions */
	public var kind:String; 		  


	public function new(mode:ApplicationMode, ?kind:String, ?onComplete:OnCompleteTransition)
	{	
		if(mode == null)
			Log.error("ApplicationMode cannot be null");

		this.mode = mode;
		this.kind = kind;
		this.onComplete = (onComplete == null ? None : onComplete);
	}

	/**
	 * Returns true if this entity should be protected
	 */
	public function isProtected(mode:ApplicationMode): Bool
	{	
		return (this.mode == mode || this.mode == Always);
	}

	/**
	 * Returns true if this entity was protected during a transition, with the exception of Always (null)
	 * transitions, which never really complete so always return false.
	 */
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
