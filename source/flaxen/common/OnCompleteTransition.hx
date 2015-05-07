package flaxen.common;

/**
 * When a transition "completes," what action should we take?
 * This enum is a custom variation of `flaxen.common.OnComplete`.
 * Currently, DestroyEntity is not supported.
 */
enum OnCompleteTransition
{ 	
	/** Destroy the component, removing it from the entity */
	DestroyComponent;

	/** Stop, do nothing, have a sandwich or something */
	None;
}