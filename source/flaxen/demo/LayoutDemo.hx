package flaxen.demo; 

import ash.core.Entity;
import com.haxepunk.utils.Key;
import flaxen.Flaxen;
import flaxen.component.Image;
import flaxen.component.Position;
import flaxen.component.Offset;
import flaxen.component.Scale;
import flaxen.component.Tween;
import flaxen.component.Layer;
import flaxen.component.Text;
import flaxen.component.Size;
import flaxen.component.Repeating;
import flaxen.component.Application;
import flaxen.service.InputService;
import flaxen.common.Easing;
import flaxen.common.TextAlign;


/**
 * Layout demo. Numerous issues with this solution, probably going to overhaul it.
 * 
 * - TODO: The screen backdrop occasionally ends abruptly on resize. It seems to happen
 * 	  somewhat randomly. If you switch to fullscreen (F) and back it goes away.
 * 	  I so far can only reproduce it on Flash.
 * - TODO: I'd rather use CTRL/CMD-ENTER to toggle fullscreen. Right now, Flash 
 * 	  requires ESC to leave fullscreen mode. Also, I'm triggering on the F
 * 	  key instead the desired key combo.
 * - TODO: Text is not positioning correctly.
 */
class LayoutDemo extends Flaxen
{
	private static var logo:String = "logo";
	private var scales = [0.5, 1.5];
	private var which = 0;

	public static function main()
	{
		var LayoutDemo = new LayoutDemo(640, 480);
	}

	override public function ready()
	{
		// Layouts
		var central = newLayout("central", 	0, 		160,	0, 		0); 
		var panelA = newLayout("panelA", 	0,		0, 		480, 	0);
		var panelB = newLayout("panelB", 	160,	0, 		480, 	160);
		var panelC = newLayout("panelC", 	320,	0, 		480, 	320);

		// Backdrop, no layout
		newEntity()
			.add(new Image("art/metalpanels.png"))
			.add(Repeating.instance)
			.add(Position.zero())
			.add(new Layer(20));

		// Central content
		var e:Entity = resolveEntity(logo) // get or create entity
			.add(new Image("art/flaxen.png"))
			.add(new Position(240, 240)) // center of central layout
			.add(central)
			.add(Offset.center()); // center image
		wobble(e);

		var travertine = new Image("art/travertine.png");
		var travLayer = new Layer(15);
		for(x in [0, 160, 320])
		for(y in [0, 160, 320])
			newEntity().add(travertine).add(central).add(travLayer).add(new Position(x, y));

		// Panel content
		var style = TextStyle.createTTF(0xFFFF88, 40, null, Center);
		for(panel in [{ layout:panelA, label:"A" }, { layout:panelB, label:"B" }, { layout:panelC, label:"C"}])
		{
			newEntity().add(travertine).add(panel.layout).add(travLayer).add(new Position(0, 0));
			newEntity().add(new Text(panel.label)).add(style).add(panel.layout)
				.add(new Position(0,60)).add(new Size(160, 160));
		}

		setUpdateCallback(function(_)
		{
			if(InputService.lastKey() == Key.F)
			{
				com.haxepunk.HXP.fullscreen = !com.haxepunk.HXP.fullscreen;
				InputService.clearLastKey();
			}
		});
	}

	public function wobble(e:Entity)
	{
		var other = which;
		which = 1 - which;

		var scale = new Scale();
		var tween = new Tween(0.2, Easing.quadOut, Both)
			.to(scale, "x", scales[which])
			.to(scale, "y", scales[other]);
		e.add(scale);
		e.add(tween);
	}
}
