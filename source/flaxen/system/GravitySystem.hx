package flaxen.system;

import ash.core.Engine;
import ash.core.Node;
import ash.core.System;
import flaxen.Flaxen;
import flaxen.FlaxenSystem;
import flaxen.component.Velocity;
import flaxen.component.Gravity;

/**
 * Simple system for processing gravity.
 *
 * An entity must possess `Velocity` and `Gravity`. Applies an increase to the velocity
 * based on the amount of Gravity in the entity.
 * 
 * To use this system, it must be added to Ash: `flaxen.addSystem(new GravitySystem(flaxen))`.
 * It should probably be added after the `flaxen.system.MovementSystem`.
 */
class GravitySystem extends FlaxenSystem
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
	 	for(node in ash.getNodeList(GravityNode))
	 	{
	 		node.velocity.x += node.gravity.x * time;
	 		node.velocity.y += node.gravity.y * time;
	 	}
	}
}

private class GravityNode extends Node<GravityNode>
{
	public var velocity:Velocity;
	public var gravity:Gravity;
}