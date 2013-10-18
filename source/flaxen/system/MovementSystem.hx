package flaxen.system;

import ash.core.Engine;
import ash.core.System;

import flaxen.node.MovementNode;
import flaxen.service.EntityService;
import flaxen.component.Velocity;

class MovementSystem extends System
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
	 	for(node in engine.getNodeList(MovementNode))
	 	{
	 		node.position.x += node.velocity.x * time;
	 		node.position.y += node.velocity.y * time;
	 	}
	}
}