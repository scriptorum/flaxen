package flaxen.demo; 

import ash.core.Entity;
import flaxen.Flaxen;
import flaxen.component.Image;
import flaxen.component.Position;
import flaxen.component.Scale;
import flaxen.component.Size;
import flaxen.component.Text;
import flaxen.component.Offset;
import flaxen.service.InputService;
import flaxen.common.Easing;
import flaxen.common.TextAlign;

class BitmapTextHandler extends FlaxenHandler
{
	private static inline var YELLOW_FONT:String = "art/impact20yellow.png";

	override public function start()
	{
		var t = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. ";
		var e:Entity = f.newEntity("demo")
			.add(new Image(YELLOW_FONT))
			.add(Size.screen().scale(.8))
			.add(Position.center())
			.add(new Text("This is bitmap text!\n\n"
					+ t + t + t + t + t + t + t + t))
			.add(TextStyle.createBitmap(true, Center, Center, -4, -2));

		var style = TextStyle.createTTF();
		style.halign = HorizontalTextAlign.Right;
		f.newEntity("msg")
			.add(new Text("(Click) Switch Text"))
			.add(style)
			.add(new Size(com.haxepunk.HXP.width, 20)) // specify size of text box
			.add(new Position(0, com.haxepunk.HXP.height - 20)); // specify by upper left corner of text box
	}

	override public function update()
	{
		if(InputService.clicked)
		{
			f.removeEntity("msg");

			var e = f.getEntity("demo");
			var t = e.get(Text);
			t.message = "The message has changed. Deal with it. Wubba lubba dub dub!";

			f.newEntity()
				.add(new Image(YELLOW_FONT))
				.add(new Text("This is a font loaded from the cache"))
				.add(Position.bottomRight().subtract(10, 10))
				.add(Scale.half())
				.add(TextStyle.createBitmap(false, Right, Bottom, 0, 8, 0, 18));
		}
	}
}
