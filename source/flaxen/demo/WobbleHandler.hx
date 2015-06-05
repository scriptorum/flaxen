package flaxen.demo; 

import ash.core.Entity;
import flaxen.Flaxen;
import flaxen.component.Image;
import flaxen.component.Position;
import flaxen.component.Offset;
import flaxen.component.Scale;
import flaxen.component.Tween;
import flaxen.component.Size;
import flaxen.common.TextAlign;
import flaxen.component.Text;
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
		var style = TextStyle.createTTF();
		style.halign = HorizontalTextAlign.Right;
		f.newEntity()
			.add(new Text("(Click) Switch Wobble"))
			.add(style)
			.add(new Size(com.haxepunk.HXP.width, 20)) // specify size of text box
			.add(new Position(0, com.haxepunk.HXP.height - 20)); // specify by upper left corner of text box

		f.resolveEntity(logo) // get or create entity
			.add(new Image("art/flaxen.png"))
			.add(new Position(com.haxepunk.HXP.halfWidth, com.haxepunk.HXP.halfHeight))
			.add(Offset.center());

		wobble(which);
	}

	override public function update()
	{
		if(InputService.clicked)
		{
			which = (which == 0 ? 1 : 0);
			wobble(which);
		}
	}

	public function wobble(which:Int)
	{
		var e = f.getEntity(logo);
		var other = 1 - which;
		var scale = new Scale();
		var tween = new Tween(0.2, Easing.quadOut, Both)
			.to(scale, "x", scales[which])
			.to(scale, "y", scales[other]);
		e.add(scale);
		e.add(tween);
	}
}
