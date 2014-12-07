package flaxen.core;

import ash.core.Engine;
import ash.core.System;

class FlaxenSystem extends System
{
	public var ash:Engine; // Ash framework
	public var f:Flaxen; // Flaxen

	public function new(flaxen:Flaxen)
	{
		super();
		this.f = flaxen;
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