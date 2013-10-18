package flaxen.core;

import ash.core.Engine;
import com.haxepunk.HXP;
import com.haxepunk.Scene;

class FlaxenScene extends Scene
{
	private var ash:Engine;

	public function new(flaxen:Flaxen)
	{
		this.ash = flaxen.ash;
		super();
	}

	override public function update()
	{
		ash.update(HXP.elapsed); // Update Ash (entity system)
		super.update(); // Update HaxePunk (game library)
	}
}
