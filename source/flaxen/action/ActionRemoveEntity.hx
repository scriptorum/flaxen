package flaxen.action;

import ash.core.Entity;

/**
 * Removes the specified entity from Ash.
 */
class ActionRemoveEntity extends Action
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
		flaxen.removeEntity(entity);
		return true;
	}

	override public function toString(): String
	{
		return 'ActionRemoveEntity (Entity:$entity)';
	}
}