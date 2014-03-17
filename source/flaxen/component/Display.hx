
package flaxen.component;

import flaxen.render.view.View;

// Contains a View, which wraps a HaxePunk entity

class Display
{
	public var updateId:Int = -1;
	public var view:View;
	public var destroyEntity:Bool = false;

	public function new(view:View, updateId:Int = -1)
	{
		recycle(view, updateId);
	}

	public function recycle(view:View, updateId:Int = -1)
	{
		this.updateId = updateId;
		this.view = view;
		this.destroyEntity = false;
	}
}