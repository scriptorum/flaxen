package flaxen.system;

import ash.core.Node;
import flaxen.core.Flaxen;
import flaxen.core.FlaxenSystem;
import flaxen.component.Position;
import flaxen.component.Tween;

class TweenNode extends Node<TweenNode>
{
	public var tween:Tween;
}

class TweeningSystem extends FlaxenSystem
{
	public function new(f:Flaxen)
	{ 
		super(f); 
	}

	override public function update(time:Float)
	{
	 	for(node in ash.getNodeList(TweenNode))
	 	{
	 		if(node.tween.complete)
	 			continue;

	 		node.tween.update(time);

	 		if(node.tween.complete)
	 		{
	 			if (node.tween.destroyEntity)
	 				ash.removeEntity(node.entity);

	 			else if(node.tween.destroyComponent)
	 				node.entity.remove(Tween);
	 		}
	 	}
	}
}