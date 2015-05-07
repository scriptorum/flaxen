package flaxen.action;

import ash.core.Entity;

/**
 * Adds the component to the specified entity.
 */
class ActionAddComponent extends Action
{
	public var component:Dynamic;
	public var entity:Entity;

	public function new(entity:Entity, component:Dynamic)
	{
		super();
		this.entity = entity;
		this.component = component;
	}

	override public function execute(): Bool
	{
		entity.add(component);
		return true;
	}

	override public function toString(): String
	{
		return "ActionAddComponent (entity:" + entity.name + " component:"+ component + ")";
	}
}
