package flaxen;

import flaxen.Flaxen;
import ash.core.Engine;
import com.haxepunk.Scene;

/**
 * - TODO: Implement focusGained/lost
 */
class FlaxenScene extends Scene
{
	public var flaxen:Flaxen;
	public var ash:Engine;

	public function new(f:Flaxen)
	{
		this.flaxen = f;
		this.ash = f.ash;
		super();
	}

	override public function begin()
	{
		flaxen.getApp().ready = true;
		flaxen.ready();
	}

	override public function update()
	{
 		ash.update(com.haxepunk.HXP.elapsed); // Update Ash (entity system)
		super.update(); // Update HaxePunk (game library)
	}

	// override public function focusGained() { } 
	//override public function focusGained() { } 
}
