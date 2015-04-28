package flaxen.system;

import ash.core.Node;
import flaxen.Flaxen;
import flaxen.FlaxenSystem;
import flaxen.component.ActionQueue;

class ActionQueueNode extends Node<ActionQueueNode>
{
	public var actionQueue:ActionQueue;
}

class ActionSystem extends FlaxenSystem
{
	public function new(f:Flaxen)
	{ 
		super(f); 
	}

	override public function update(time:Float)
	{
	 	for(node in ash.getNodeList(ActionQueueNode))
	 	{
	 		var aq = node.actionQueue;
	 		if(aq.execute())
	 		{
	 			if (aq.onComplete == DestroyEntity)
	 				ash.removeEntity(node.entity);

	 			else if(aq.onComplete == DestroyComponent)
	 				node.entity.remove(ActionQueue);
	 		}
	 	}
	}
}