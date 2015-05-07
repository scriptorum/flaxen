package flaxen.action;

import ash.core.Entity;


/**
 * Removes the component from the specified entity.
 */
class ActionRemoveComponent extends Action
{
	public var component:Class<Dynamic>;
	public var entity:Entity;

	public function new(entity:Entity, component:Class<Dynamic>)
	{
		super();
		this.entity = entity;
		this.component = component;
	}

	override public function execute(): Bool
	{
		entity.remove(component); // remove quietly
		return true;
	}

	override public function toString(): String
	{
		return "ActionRemoveComponent (entity:" + entity.name + " component:"+ component + ")";
	}
}