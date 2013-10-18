package flaxen.component;

import flaxen.render.View;

// Wraps a HaxePunk entity
class Display
{
	public var view:View;
	public var destroyEntity:Bool = false;

	public function new(view:View)
	{
		this.view = view;
	}
}