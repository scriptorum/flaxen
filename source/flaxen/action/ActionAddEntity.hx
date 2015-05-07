package flaxen.action;

import flaxen.Flaxen;
import ash.core.Entity;

/**
 * Adds the specified free entity to Ash.
 */
class ActionAddEntity extends Action
{
	public var entity:Entity;
	public var flaxen:Flaxen;

	public function new(flaxen:Flaxen, entity:Entity)
	{
		super();
		this.flaxen = flaxen;
		this.entity = entity;
	}

	override public function execute(): Bool
	{
		flaxen.addEntity(entity);
		return true;
	}

	override public function toString(): String
	{
		return "ActionAddEntity (entity:" + entity.name + ")";
	}
}