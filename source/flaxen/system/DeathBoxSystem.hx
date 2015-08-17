package flaxen.system;

import ash.core.Node;
import flaxen.Flaxen;
import flaxen.FlaxenSystem;
import flaxen.component.Position;
import flaxen.component.DeathBox;

/**
 * A death box is an area on the screen for automatically removing entities
 * that either stray out of or into specified areas.
 *
 * An entity must possess `Position` and a `DeathBox` to be susceptible to this system.
 * 
 * To use this system, it must be added to Ash: `flaxen.addSystem(new DeathBoxSystem())`.
 * It should probably be added after the `flaxen.system.MovementSystem`.
 */
class DeathBoxSystem extends FlaxenSystem
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
	 	for(node in ash.getNodeList(DeathBoxNode))
	 	{
	 		var inside:Bool = node.position.isInside(node.deathBox.rect);
	 		if(node.deathBox.deathInside == inside)
	 			f.removeEntity(node.entity);
	 	}
	}
}

private class DeathBoxNode extends Node<DeathBoxNode>
{
	public var position:Position;
	public var deathBox:DeathBox;
}
