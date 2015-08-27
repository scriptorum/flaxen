package flaxen.render.view;

import flaxen.component.Image;
import flaxen.component.Repeating;

import com.haxepunk.graphics.Backdrop;

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
		else if(curWidth != com.haxepunk.HXP.screen.width || 
			curHeight != com.haxepunk.HXP.screen.height)
				setBackdrop(image);
	}

	private function setBackdrop(image:Image)
	{
		var repeating:Repeating = getComponent(Repeating);
		curWidth = com.haxepunk.HXP.screen.width; // HAXEPUNK FIX
		curHeight = com.haxepunk.HXP.screen.height; // HAXEPUNK FIX
		graphic = new Backdrop(image.path, repeating.repeatX, repeating.repeatY);
		setImageDimensions(image);
		curImage = image;
	}
}