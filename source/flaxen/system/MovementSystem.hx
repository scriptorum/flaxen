package flaxen.system;

import ash.core.Engine;
import ash.core.Node;
import ash.core.System;
import flaxen.component.Velocity;
import flaxen.component.Position;
import flaxen.Flaxen;
import flaxen.FlaxenSystem;

/**
 * System for processing movement.
 *
 * An entity must possess both `Position` and `Velocity`. Applies the velocity
 * to the position, treating velocity as the number of pixels moved in one 
 * second.
 * 
 * To use this system, it must be added to Ash: `flaxen.addSystems([MovementSystem])`.
 */
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

private class MovementNode extends Node<MovementNode>
{
	public var position:Position;
	public var velocity:Velocity;
}