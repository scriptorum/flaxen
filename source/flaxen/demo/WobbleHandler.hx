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
import flaxen.FlaxenHandler;

/**
 *	Shows a wobbling image, demonstrating showing an image, scaling, tweening and input.
 */
class WobbleHandler extends FlaxenHandler
{
	private static var logo:String = "logo";
	private var scales = [0.5, 1.5];
	private var which = 0;

	override public function start()
	{
		var e:Entity = f.resolveEntity(logo) // get or create entity
			.add(new Image("art/flaxen.png"))
			.add(new Position(com.haxepunk.HXP.halfWidth, com.haxepunk.HXP.halfHeight))
			.add(Offset.center());

		wobble(e, which);
	}

	override public function update()
	{
		if(InputService.clicked)
		{
			var e = f.getEntity(logo); // get entity or Log.error( error 
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
