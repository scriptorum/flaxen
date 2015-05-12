package flaxen.system;

import flaxen.Flaxen;
import flaxen.FlaxenSystem;
import flaxen.component.Position;
import flaxen.component.Tween;
import flaxen.node.TweenNode;

class TweenSystem extends FlaxenSystem
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
	 			if (node.tween.onComplete == DestroyEntity)
	 				ash.removeEntity(node.entity);

	 			else if(node.tween.onComplete == DestroyComponent)
	 				node.entity.remove(Tween);
	 		}
	 	}
	}
}


