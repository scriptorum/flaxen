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
import flaxen.FlaxenHandler;


/**
 * Layout demo. Numerous issues with this solution, probably going to overhaul it.
 * 
 * - TODO: The screen backdrop occasionally ends abruptly on resize. It seems to happen
 * 	  somewhat randomly. If you switch to fullscreen (F) and back it goes away.
 * 	  I so far can only reproduce it on Flash.
 * - TODO: Text is not positioning correctly. It's not scaled. Probably TextView issue. 
 * - TODO: Handler needs a way of identifying and responding to a resize event
 */
class LayoutHandler extends FlaxenHandler
{
	private static var logo:String = "logo";
	private var scales = [0.5, 1.5];
	private var which = 0;

	override public function start()
	{
		// Layouts
		var central = f.newLayout("central", 	0, 		160,	0, 		0); 
		var panelA =  f.newLayout("panelA", 	0,		0, 		480, 	0);
		var panelB =  f.newLayout("panelB", 	160,	0, 		480, 	160);
		var panelC =  f.newLayout("panelC", 	320,	0, 		480, 	320);

		// Backdrop, no layout
		f.newEntity()
			.add(new Image("art/metalpanels.png"))
			.add(Repeating.instance)
			.add(Position.zero())
			.add(new Layer(20));

		var travertine = new Image("art/travertine.png");
		var travLayer = new Layer(15);
		for(x in [0, 160, 320])
		for(y in [0, 160, 320])
			f.newEntity().add(travertine).add(central).add(travLayer).add(new Position(x, y));

		// Panel content
		var style = TextStyle.createTTF(0xFFFF88, 40, null, Center);
		for(panel in [{ layout:panelA, label:"A" }, { layout:panelB, label:"B" }, { layout:panelC, label:"C"}])
		{
			f.newEntity().add(travertine).add(panel.layout).add(travLayer).add(new Position(0, 0));
			f.newEntity().add(new Text(panel.label)).add(style).add(panel.layout)
				.add(new Position(0,60)).add(new Size(160, 160));
		}

		// Central content
		var style = TextStyle.createTTF(0x008833, 40, null, Center);
		f.resolveEntity("msg")
			.add(new Text("Resize The Window"))
			.add(style)
			.add(new Size(480, 60))
			.add(central)
			.add(new Position(0, 225));
	}
}
