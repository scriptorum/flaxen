/*
 *	Shows a wobbling image, demonstrating showing an image, scaling, tweening and input.
 */
package flaxen.demo; 

import ash.core.Entity;
import flaxen.core.Flaxen;
import flaxen.component.Image;
import flaxen.component.Position;
import flaxen.component.Offset;
import flaxen.component.Scale;
import flaxen.component.Tween;
import flaxen.component.Application;
import flaxen.service.InputService;
import flaxen.common.Easing;

class WobbleDemo extends Flaxen
{
	private static var logo:String = "logo";

	public static function main()
	{
		var demo = new WobbleDemo();
	}

	override public function ready()
	{
		setUpdateCallback(handleInput);

		var e:Entity = resolveEntity(logo) // get or create entity
			.add(new Image("art/flaxen.png"))
			.add(new Position(com.haxepunk.HXP.halfWidth, com.haxepunk.HXP.halfHeight))
			.add(Offset.center());

		wobble(e, { x:0.8, y:1.2 });
	}

	public function handleInput(_)
	{
		if(InputService.clicked)
		{
			var e = getEntity(logo); // get entity or Log.error( error 
			var tween = e.get(Tween);
			var target = { x:tween.target.y, y:tween.target.x }; // swap targets
			wobble(e, target);
		}
	}

	public function wobble(e:Entity, wobbleTarget:Dynamic)
	{
		var scale = new Scale();
		var tween = new Tween(scale, wobbleTarget, 0.2, Easing.easeOutQuad);
		tween.loop = Both;

		e.add(scale);
		e.add(tween);
	}
}
