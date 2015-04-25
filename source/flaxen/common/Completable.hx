package flaxen.common;

/**
 * A completable component sets complete to true when it completes. Got that?
 * Some completable components can be restarted, which would set complete back
 * to false. Most completable components can take an action when it happens.
 * See `onComplete`.
 */
interface Completable 
{
	public var complete:Bool;
}

/**
 * When a component "completes," what action should we take?
 * This is a default OnComplete enum to use. Some components
 * provide their own alternate OnComplete with additional options.
 */
enum OnComplete
{
	/** Destroy the entity holding this component */
	DestroyEntity;

	/** Destroy the component, removing it from the entity */
	DestroyComponent;

	/** Stop, do nothing, have a sandwich or something */
	None;
}
