package flaxen.render.view;

import flaxen.component.Image;

import com.haxepunk.graphics.Backdrop;
import com.haxepunk.HXP;

class BackdropView extends View
{
	private var curImage:Image;
	private var curWidth:Float = 0; // HAXEPUNK FIX
	private var curHeight:Float = 0; // HAXEPUNK FIX

	override public function begin()
	{
		nodeUpdate();
	}

	override public function nodeUpdate()
	{
		super.nodeUpdate();

		// Image is required component, will always be there if we're at the point
		var image = getComponent(Image);
		if(image != curImage)
			setBackdrop(image);

		// Rebuild backdrop after scale change detected. This is a HACK to fix a bug in
		// HaxePunk. Backdrop should detect when a screen resize occurs but it does not.
		else if(curWidth != HXP.screen.width || curHeight != HXP.screen.height)
			setBackdrop(image);
	}

	private function setBackdrop(image:Image)
	{
		curWidth = HXP.screen.width; // HAXEPUNK FIX
		curHeight = HXP.screen.height; // HAXEPUNK FIX
		graphic = new Backdrop(image.path);
		setImageDimensions(image);
		curImage = image;
	}
}