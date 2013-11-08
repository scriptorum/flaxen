/*
	TODO 
		o The screen backdrop occasionally ends abruptly on resize. It seems to happen
		  somewhat randomly. If you switch to fullscreen (F) and back it goes away.
		  I so far can only reproduce it on Flash.

		o I'd rather use CTRL/CMD-ENTER to toggle fullscreen. Right now, Flash 
		  requires ESC to leave fullscreen mode. Also, I'm triggering on the F
		  key instead the desired key combo.
*/

package flaxen.demo; 

import ash.core.Entity;
import com.haxepunk.HXP;
import com.haxepunk.utils.Key;
import flaxen.core.Flaxen;
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
import flaxen.util.Easing;

class LayoutDemo extends Flaxen
{
	private static var logo:String = "logo";

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
			.add(new Position(0,0))
			.add(new Layer(20));

		// Central content
		var e:Entity = resolveEntity(logo) // get or create entity
			.add(new Image("art/flaxen.png"))
			.add(new Position(240, 240)) // center of central layout
			.add(central)
			.add(Offset.center); // center image
		wobble(e, { x:0.8, y:1.2 });

		var travertine = new Image("art/travertine.png");
		var travLayer = new Layer(15);
		for(x in [0, 160, 320])
		for(y in [0, 160, 320])
			newEntity().add(travertine).add(central).add(travLayer).add(new Position(x, y));

		// Panel content
		var style = new TextStyle(0xFFFF88, 40, null, center, true);
		for(panel in [{ layout:panelA, label:"A" }, { layout:panelB, label:"B" }, { layout:panelC, label:"C"}])
		{
			newEntity().add(travertine).add(panel.layout).add(travLayer).add(new Position(0, 0));
			newEntity().add(new Text(panel.label, style)).add(panel.layout)
				.add(new Position(0,60)).add(new Size(160, 160));
		}

		setInputHandler(function(_)
		{
			if(InputService.lastKey() == Key.F)
			{
				HXP.fullscreen = !HXP.fullscreen;
				InputService.clearLastKey();
			}
		});
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
