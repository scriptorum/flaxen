/*
  TODO
    - Class only handles one animation at a time
    - Class recreates Spritemap after every change, this is suboptimal
    - Maybe add sequences for each loop type, so you can switch loop type and get the new animation?
    - Add support for "freeze at end" loop type.
*/
package flaxen.render.view;

import com.haxepunk.HXP;
import com.haxepunk.graphics.Spritemap;

import flaxen.component.Animation;
import flaxen.component.Display;
import flaxen.component.Image;
import flaxen.component.ImageGrid;
import flaxen.common.LoopType;
import flaxen.core.Log;

class AnimationView extends View
{
	private var animation:Animation;
	private var image:Image;
	private var imageGrid:ImageGrid;
	private var spritemap:Spritemap;

	override public function begin()
	{
		nodeUpdate();
	}

	private function setAnim()
	{
		graphic = spritemap = new Spritemap(image.path,
			Std.int(imageGrid.tileWidth), 
			Std.int(imageGrid.tileHeight), 
			animationFinished);
		spritemap.flipped = image.flipped;

		Log.assert(animation.speed != Math.POSITIVE_INFINITY, "Inifinite speed for spritemap " + image.path);
		Log.assert(animation.speed != Math.NEGATIVE_INFINITY, "Negative infinite speed for spritemap " + image.path);
		Log.assert(animation.speed != Math.NaN, "NaN speed for spritemap " + image.path);

		spritemap.add("play", animation.frameArr, animation.speed, animation.loop != LoopType.None);
		spritemap.play("play");

		setImageDimensions(image, imageGrid);
		animation.restart = animation.complete = false;
	}

	private function animationFinished(): Void
	{
		if(animation.loop != None && animation.stop == false)
			return;

		if(animation.destroyComponent)
			entity.remove(Animation);
		else if(animation.destroyEntity && entity.has(Display))
			entity.get(Display).destroyEntity = true;
		else stop();
	}

	private function stop()
	{
		switch(animation.stopType)
		{
			case Clear:
			graphic = null;

			case First:
			spritemap.setAnimFrame("play", 0);

			case Last:
			spritemap.setAnimFrame("play", animation.frameArr.length - 1);
		}	
		animation.stop = false;
		animation.complete = true;
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

		var curImageGrid = getComponent(ImageGrid);
		if(curImageGrid != imageGrid)
		{
			imageGrid = curImageGrid;
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

		// Pause/resume animation
		if(curAnim.paused == spritemap.active)
			spritemap.active = !curAnim.paused;

		super.nodeUpdate();
	}
}