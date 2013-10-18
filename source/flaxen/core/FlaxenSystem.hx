package flaxen.core;

import ash.core.Engine;
import ash.core.System;
import flaxen.service.EntityService;

class FlaxenSystem extends System
{
	public var flaxen:Flaxen;
	public var entityService:EntityService;
	public var ash:Engine;

	public function new(flaxen:Flaxen)
	{
		super();
		this.flaxen = flaxen;
		this.entityService = flaxen.entityService;
		this.ash = flaxen.ash;
		init();
	}

	public function init(): Void
	{		
	}

	override public function update(time:Float)
	{
	}
}