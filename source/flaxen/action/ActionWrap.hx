package flaxen.action;

import flaxen.Flaxen;

/**
 * Wraps a component into new entity and adds that entity to Ash.
 * Optionally, an entity name or pattern may be supplied.
 */
class ActionWrap extends Action
{
	public var component:Dynamic;
	public var flaxen:Flaxen;
	public var name:String;

	public function new(f:Flaxen, component:Dynamic, name:String = null)
	{
		super();
		this.flaxen = f;
		this.component = component;
		this.name = name;
	}

	override public function execute(): Bool
	{
		if(flaxen == null)
			throw "Flaxen must be non-null";
		flaxen.newWrapper(component, name);
		return true;
	}

	override public function toString(): String
	{
		return 'ActionWrap (component:$component name:$name)';
	}
}
