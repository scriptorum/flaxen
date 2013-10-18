package flaxen.system;

import ash.core.Engine;
import ash.core.System;
import ash.core.Node;

import flaxen.service.EntityService;
import flaxen.component.ActionQueue;

class ActionQueueNode extends Node<ActionQueueNode>
{
	public var actionQueue:ActionQueue;
}

class ActionSystem extends System
{
	public var factory:EntityService;
	public var engine:Engine;

	public function new(engine:Engine, factory:EntityService)
	{
		super();
		this.engine = engine;
		this.factory = factory;
	}

	override public function update(time:Float)
	{
	 	for(node in engine.getNodeList(ActionQueueNode))
	 	{
	 		var aq = node.actionQueue;
	 		if(aq.execute())
	 		{
	 			if (aq.destroyEntity)
	 				engine.removeEntity(node.entity);

	 			else if(aq.destroyComponent)
	 				node.entity.remove(ActionQueue);
	 		}
	 	}
	}
}