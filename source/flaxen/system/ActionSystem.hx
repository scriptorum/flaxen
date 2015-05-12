package flaxen.system;

import flaxen.Flaxen;
import flaxen.FlaxenSystem;
import flaxen.component.ActionQueue;
import flaxen.node.ActionQueueNode;

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
