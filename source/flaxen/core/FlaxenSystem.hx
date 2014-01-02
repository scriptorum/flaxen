package flaxen.core;

import ash.core.Engine;
import ash.core.System;

class FlaxenSystem extends System
{
	public var ash:Engine; // Ash framework
	public var flaxen:Flaxen; // Flaxen framework - extends HaxePunk
	public var f:Flaxen; // Shorthand for convenience

	public function new(flaxen:Flaxen)
	{
		super();
		this.f = this.flaxen = flaxen;
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