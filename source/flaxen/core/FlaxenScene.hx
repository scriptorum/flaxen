package flaxen.core;

import ash.core.Engine;
import com.haxepunk.HXP;
import com.haxepunk.Scene;
import flaxen.core.Flaxen;

class FlaxenScene extends Scene
{
	private var flaxen:Flaxen;
	private var ash:Engine;

	public function new(flaxen:Flaxen)
	{
		this.flaxen = flaxen;
		this.ash = flaxen.ash;
		super();
	}

	override public function begin()
	{
		flaxen.ready();
	}

	override public function update()
	{
		ash.update(HXP.elapsed); // Update Ash (entity system)
		super.update(); // Update HaxePunk (game library)
	}
}
