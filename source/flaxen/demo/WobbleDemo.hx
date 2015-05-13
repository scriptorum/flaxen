package flaxen.demo; 

import ash.core.Entity;
import flaxen.Flaxen;
import flaxen.component.Image;
import flaxen.component.Position;
import flaxen.component.Offset;
import flaxen.component.Scale;
import flaxen.component.Tween;
import flaxen.component.Application;
import flaxen.service.InputService;
import flaxen.common.Easing;

/**
 *	Shows a wobbling image, demonstrating showing an image, scaling, tweening and input.
 */
class WobbleDemo extends Flaxen
{
	private static var logo:String = "logo";
	private var scales = [0.5, 1.5];
	private var which = 0;

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

		wobble(e, which);
	}

	public function handleInput(_)
	{
		if(InputService.clicked)
		{
			var e = getEntity(logo); // get entity or Log.error( error 
			var tween = e.get(Tween);
			which = (which == 0 ? 1 : 0);
			wobble(e, which);
		}
	}

	public function wobble(e:Entity, which:Int)
	{
		var other = 1 - which;
		var scale = new Scale();
		var tween = new Tween(0.2, Easing.quadOut, Both)
			.to(scale, "x", scales[which])
			.to(scale, "y", scales[other]);
		e.add(scale);
		e.add(tween);
	}
}
