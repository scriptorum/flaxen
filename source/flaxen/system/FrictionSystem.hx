package flaxen.system;

import ash.core.Engine;
import ash.core.Node;
import ash.core.System;
import flaxen.Flaxen;
import flaxen.FlaxenSystem;
import flaxen.component.Velocity;
import flaxen.component.Friction;

/**
 * System for processing friction.
 *
 * An entity must possess `Velocity` and `Friction`. Applies reduction to the velocity
 * based on the amount of friction. The higher the friction amount from 0, the greater 
 * the reduction.
 * 
 * To use this system, it must be added to Ash: `flaxen.addSystem(new FrictionSystem(flaxen))`.
 * It should probably be added after the `flaxen.system.MovementSystem`.
 */
class FrictionSystem extends FlaxenSystem
{
	/**
	 * Constructor.
	 *
	 * @param f The flaxen instance
	 */
	public function new(f:Flaxen)
	{ 
		super(f); 
	}

	override public function update(time:Float)
	{
	 	for(node in ash.getNodeList(FrictionNode))
	 	{
	 		var mult = 1 - node.friction.amount * time;
	 		node.velocity.x *= mult;
	 		node.velocity.y *= mult;

	 		if(node.velocity.lessThan(node.friction.minVelocity))
	 		{
	 			// Remove Velocity component
	 			if(node.friction.destroyComponent)
	 				node.entity.remove(Velocity);

	 			// Clamp velocity to 0
	 			else
	 				node.velocity.x = node.velocity.y = 0;
	 		}
	 	}
	}
}

private class FrictionNode extends Node<FrictionNode>
{
	public var velocity:Velocity;
	public var friction:Friction;
}