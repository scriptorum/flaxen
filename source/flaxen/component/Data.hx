package flaxen.component;

/**
 * Arbitrary data object. 
 *
 * This can hold anything you want. It's primarily intended as a quick way to
 * to wrap anonymous objects and primitive values (numbers, strings), without
 * having to create a new component class.
 *
 * It is not necessary to wrap class instances - any class instance can be
 * used as a component, simply add it to the entity and retrieve it by class name.
 */ 
class Data
{
	public var value:Dynamic;
	
	public function new(value:Dynamic)
	{
		this.value = value;
	}
}