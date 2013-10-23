package flaxen.core;

import ash.core.Engine;
import ash.core.System;

class FlaxenSystem extends System
{
	public var flaxen:Flaxen;
	public var ash:Engine;

	public function new(flaxen:Flaxen)
	{
		super();
		this.flaxen = flaxen;
		this.ash = flaxen.ash;
		init();
	}

	// Override with system initialization
	public function init(): Void
	{
	}

	// Override with custom system updating 
	override public function update(time:Float)
	{
	}
}