package flaxen.system;

import ash.core.Engine;
import ash.core.System;
import ash.core.Node;

import flaxen.service.EntityService;
import flaxen.component.Position;
import flaxen.component.Tween;

class TweenNode extends Node<TweenNode>
{
	public var tween:Tween;
}

class TweeningSystem extends System
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
	 	for(node in engine.getNodeList(TweenNode))
	 	{
	 		if(node.tween.complete)
	 			continue;

	 		node.tween.update(time);

	 		if(node.tween.complete)
	 		{
	 			if (node.tween.destroyEntity)
	 				engine.removeEntity(node.entity);

	 			else if(node.tween.destroyComponent)
	 				node.entity.remove(Tween);
	 		}
	 	}
	}
}