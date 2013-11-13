package flaxen.render.view;

import com.haxepunk.HXP;
import com.haxepunk.graphics.Spritemap;

import flaxen.component.Animation;
import flaxen.component.Tile;

class AnimationView extends View
{
	private var animation:Animation;
	private var spritemap:Spritemap;

	override public function begin()
	{
		nodeUpdate();
	}

	private function setAnim()
	{
		animation = getComponent(Animation);
		if(animation == null)
		{
			graphic = null;
			return;
		}

		var cbFunc:CallbackFunction = (animation.looping ? null : animationFinished);
		spritemap = new Spritemap(animation.image.path,
			Std.int(animation.subdivision.plot.width), 
			Std.int(animation.subdivision.plot.height), 
			cbFunc);
		spritemap.add("main", animation.frames, animation.speed, animation.looping);
		spritemap.play("main");
		graphic = spritemap;

		// Update image dimensions
		animation.image.width = animation.subdivision.plot.width;
		animation.image.height = animation.subdivision.plot.height;
	}

	private function animationFinished(): Void
	{
		entity.remove(Animation);
	}

	override public function nodeUpdate()
	{
		super.nodeUpdate();

		// Change/update animation
		var curAnim = getComponent(Animation);
		if(curAnim != animation)
			setAnim();
	}
}