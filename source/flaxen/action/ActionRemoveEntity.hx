package flaxen.action;

import ash.core.Entity;
import flaxen.Flaxen;

/**
 * Removes the specified entity from Ash.
 */
class ActionRemoveEntity extends Action
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
		flaxen.removeEntity(entity);
		return true;
	}

	override public function toString(): String
	{
		return 'ActionRemoveEntity (Entity:${entity.name})';
	}
}