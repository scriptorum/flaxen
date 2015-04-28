package flaxen.system;

import ash.core.Engine;
import ash.core.System;

import flaxen.Flaxen;
import flaxen.FlaxenSystem;
import flaxen.node.MovementNode;
import flaxen.component.Velocity;

class MovementSystem extends FlaxenSystem
{
	public function new(f:Flaxen)
	{ 
		super(f); 
	}

	override public function update(time:Float)
	{
	 	for(node in ash.getNodeList(MovementNode))
	 	{
	 		node.position.x += node.velocity.x * time;
	 		node.position.y += node.velocity.y * time;
	 	}
	}
}