/*
  TODO
    - Class only handles one animation at a time
    - Class recreates Spritemap after every change, this is suboptimal
*/
package flaxen.render.view;

import com.haxepunk.HXP;
import com.haxepunk.graphics.Spritemap;

import flaxen.component.Animation;
import flaxen.component.Display;
import flaxen.component.Image;

class AnimationView extends View
{
	private var animation:Animation;
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
		if(animation.destroyComponent)
			entity.remove(Animation);
		else if(animation.destroyEntity && entity.has(Display))
			entity.get(Display).destroyEntity = true;
		else animation.complete = true;
	}

	override public function nodeUpdate()
	{
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
		if(curAnim != animation || curAnim.changed)
		{
			animation = curAnim;
			animation.changed = false;
			updateDisplay = true;
		}

		if (animation.restart)
			updateDisplay = true;

		if(animation.stop)
		{
			if(spritemap == null)
				animationFinished();
			else spritemap.complete = true;
			animation.stop = false;
		}

		// Change/update animation
		else if(updateDisplay || animation.restart)
			setAnim();

		super.nodeUpdate();
	}
}