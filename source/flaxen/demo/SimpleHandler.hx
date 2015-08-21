package flaxen.demo; 

import ash.core.Entity;
import flaxen.common.TextAlign;
import flaxen.component.Image;
import flaxen.component.Offset;
import flaxen.component.Position;
import flaxen.component.Size;
import flaxen.component.Text;
import flaxen.FlaxenHandler;
import flaxen.service.CameraService;
import flaxen.service.InputService;

/**
 *	Shows a basic image, demonstrating showing an image, position, and offset.
 */
class SimpleHandler extends FlaxenHandler
{
	override public function start()
	{
		CameraService.init(f);

		f.newEntity()
			.add(new Image("art/flaxen.png"))
			.add(Position.center())
			.add(Offset.center());

		var style = TextStyle.createTTF();
		style.halign = HorizontalTextAlign.Right;
		f.newEntity()
			.add(new Text("(Click) Rumble/shake"))
			.add(style)
			.add(new Size(com.haxepunk.HXP.width, 20)) // specify size of text box
			.add(new Position(0, com.haxepunk.HXP.height - 20)); // specify by upper left corner of text box
	}

	override public function update()
	{
		if(InputService.clicked)
		{
			f.newSound("sound/rumble.wav");
			CameraService.shake(1.96, 3);
		}
	}

	override public function stop()
	{
		CameraService.reset(); // In case we switch handlers mid-shake
	}
}
