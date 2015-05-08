package flaxen.action;

import ash.core.Entity;
import flaxen.Flaxen;

/**
 * Adds the specified free entity to Ash.
 */
class ActionAddEntity extends Action
{
	public var entity:Entity;
	public var flaxen:Flaxen;

	public function new(f:Flaxen, entity:Entity)
	{
		super();
		this.flaxen = f;
		this.entity = entity;
	}

	override public function execute(): Bool
	{
		if(flaxen == null)
			throw "Flaxen must be non-null";
		flaxen.addEntity(entity);
		return true;
	}

	override public function toString(): String
	{
		return 'ActionAddEntity (Entity:${entity.name})';
	}
}