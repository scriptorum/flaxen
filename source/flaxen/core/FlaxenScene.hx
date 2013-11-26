/*
	TODO
	Implement focusGained/lost
*/
package flaxen.core;

import flaxen.core.Flaxen;
import ash.core.Engine;
import com.haxepunk.HXP;
import com.haxepunk.Scene;

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
		flaxen.ready();
	}

	override public function update()
	{
		ash.update(HXP.elapsed); // Update Ash (entity system)
		super.update(); // Update HaxePunk (game library)
	}

	//override public function focusGained() { } 
	//override public function focusGained() { } 
}
