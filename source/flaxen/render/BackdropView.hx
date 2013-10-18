package flaxen.render;

import flaxen.component.Image;

import com.haxepunk.graphics.Backdrop;

class BackdropView extends View
{
	override public function begin()
	{
		// trace("Placing backdrop entity at layer " + this.layer);
		var image = getComponent(Image);
		var backdrop = new Backdrop(image.path);
		graphic = backdrop;
	}
}