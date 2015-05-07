package flaxen.common;

/**
 * When an animation "completes," what action should we take?
 * This enum is a custom extension of `flaxen.common.OnComplete`.
 * An animation completes when it finishes its sequence (if LoopType
 * is None) or when the looping is interrupted by setting stop
 * to true.
 *
 * - Note: Pausing the animation with `paused=true` will not set 
 *   the complete flag. Setting OnComplete to Paused
 */
enum OnCompleteAnimation
{ 	
	/** Destroy the entity holding this component */
	DestroyEntity;

	/** Destroy the component, removing it from the entity */
	DestroyComponent;

	/** The animation disappears (default). */
	Clear;	

	/** The animation freezes on the last frame */
	Last;	

	/** The animation freezes on the first frame */
	First;	

	/** The animation remains on its last frame where it was manually stopped */
	Current;  
}