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

class BitmapTextDemo extends Flaxen
{
	private static inline var YELLOW_FONT:String = "art/impact20yellow.png";

	public static function main()
	{
		var demo = new BitmapTextDemo();
	}

	override public function ready()
	{
		var t = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. ";
		var e:Entity = newEntity("demo")
			.add(new Image(YELLOW_FONT))
			.add(Size.screen().scale(.8))
			.add(Position.center())
			.add(new Text("This is bitmap text!\n\n"
					+ t + t + t + t + t + t + t + t))
			.add(TextStyle.createBitmap(true, Center, Center, -4, -2));

		var e2:Entity = newEntity()
			.add(new Text("This is regular TTF text."))
			.add(Position.topLeft());

		setUpdateCallback(function(f)
		{
			if(InputService.clicked)
			{
				var e = getEntity("demo");
				var t = e.get(Text);
				t.message = "The message has changed. Deal with it. Bitch. Yeah that's right, I called you a bitch.";


				newEntity()
					.add(new Image(YELLOW_FONT))
					.add(new Text("This is a font loaded from the cache"))
					.add(Position.bottomRight().subtract(10, 10))
					.add(Scale.half())
					.add(TextStyle.createBitmap(false, Right, Bottom, 0, 8, 0, 18));
			}
		});
	}
}
