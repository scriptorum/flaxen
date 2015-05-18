package flaxen.action;

import flaxen.Flaxen;

/**
 * Applies a set of batch operations to the specified entity.
 */
class ActionBatch extends Action
{
	public var flaxen:Flaxen;
	public var entityRef:EntityRef;
	public var setName:String;

	public function new(f:Flaxen, entityRef:EntityRef, setName:String)
	{
		super();
		this.flaxen = f;
		this.entityRef = entityRef;
		this.setName = setName;
	}

	override public function execute(): Bool
	{
		if(flaxen == null)
			throw "Flaxen must be non-null";
		flaxen.addSet(entityRef, setName);
		return true;
	}

	override public function toString(): String
	{
		return 'ActionBatch (entity:${entityRef} setName:$setName)';
	}
}
