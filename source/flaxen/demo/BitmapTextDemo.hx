package flaxen.demo; 

import ash.core.Entity;
import com.haxepunk.HXP;
import flaxen.core.Flaxen;
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
	public static function main()
	{
		var demo = new BitmapTextDemo();
	}

	override public function ready()
	{
		var e:Entity = newEntity("demo", false)
			.add(new Image("art/impact20yellow.png"))
			.add(Size.screen())
			.add(Position.center())
			.add(new Text("This is bitmap text. {ABCDEFG} [1234]\n\nI'm typing a {really} long line Note: In the example above, a case statement reads '65, 90'. This is an example where a case expects to match either of the two (or several) values, listed as delimited by comma(s). Switches in Haxe are different from traditional switches: all cases are separate expressions so after one case expression is executed the switch block is automatically exited. As a consequence, break can't be used in a switch and the position of the default case is not important. On some platforms, switches on constant values (especially constant integers) might be optimized for better speed. Switches can also be used on enums with different semantics. It will be explained later in this document."))
			// .add(Scale.half())
			.add(TextStyle.forBitmap(true, Center, Center, -4, -2));

		var e2:Entity = newEntity()
			.add(new Text("This is regular TTF text."))
			.add(Position.topLeft());

		setInputHandler(function(f)
		{
			if(InputService.clicked)
			{
				var e = demandEntity("demo");
				var t = e.get(Text);
				t.message = "The message has changed. Deal with it. Bitch. Yeah that's right, I called you a bitch.";
			}
		});
	}
}
