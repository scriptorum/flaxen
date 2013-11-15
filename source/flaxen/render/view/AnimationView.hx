package flaxen.render.view;

import com.haxepunk.HXP;
import com.haxepunk.graphics.Spritemap;

import flaxen.component.Animation;
import flaxen.component.Image;

class AnimationView extends View
{
	private var animation:Animation;
	private var frames:Array<Int>;
	private var image:Image;
	private var spritemap:Spritemap;

	override public function begin()
	{
		nodeUpdate();
	}

	private function setAnim()
	{
		var cbFunc:CallbackFunction = (animation.looping ? null : animationFinished);
		spritemap = new Spritemap(image.path,
			Std.int(animation.subdivision.plot.width), 
			Std.int(animation.subdivision.plot.height), 
			cbFunc);
		spritemap.add("default", animation.frames, animation.speed, animation.looping);
		spritemap.play("default");
		graphic = spritemap;

		// Update image dimensions
		image.width = animation.subdivision.plot.width;
		image.height = animation.subdivision.plot.height;
	}

	private function animationFinished(): Void
	{
		entity.remove(Animation);
	}

	override public function nodeUpdate()
	{
		super.nodeUpdate();

		var updateDisplay = false;

		// Check for new image component
		var curImage = getComponent(Image);
		if(image != curImage)
		{
			image = curImage;
			updateDisplay = true;
		}

		// Check for new animation component
		var curAnim = getComponent(Animation);
		if(curAnim != animation || curAnim.frames != frames)
		{
			animation = curAnim;
			frames = animation.frames;
			updateDisplay = true;
		}

		// Change/update animation
		if(updateDisplay)
			setAnim();
	}
}