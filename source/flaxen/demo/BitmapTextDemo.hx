package flaxen.demo; 

import ash.core.Entity;
import com.haxepunk.HXP;
import flaxen.core.Flaxen;
import flaxen.component.Image;
import flaxen.component.Position;
import flaxen.component.Offset;
import flaxen.component.Size;
import flaxen.component.Text;
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
			// .add(Position.bottom())
			// .add(Text.createBitmapText("Here's a wee bit of text.\n{And this line clips at the baseline!}", 
			// 	false, Center, Baseline, 0, 0, 5));
			.add(Position.center())
			.add(Text.createBitmapText("AAABBBCCC Hi there! 1234\n\nI'm typing a {really} long line Note: In the example above, a case statement reads '65, 90'. This is an example where a case expects to match either of the two (or several) values, listed as delimited by comma(s). Switches in Haxe are different from traditional switches: all cases are separate expressions so after one case expression is executed the switch block is automatically exited. As a consequence, break can't be used in a switch and the position of the default case is not important. On some platforms, switches on constant values (especially constant integers) might be optimized for better speed. Switches can also be used on enums with different semantics. It will be explained later in this document.", 
				true, Center, Center, -4, -2));

		// Equivalent without Ash:
		// var e = new com.haxepunk.Entity();
		// e.x = 320;
		// e.y = 240;
		// e.graphic = new flaxen.render.BitmapText("art/impact20yellow.png", 0, 0,
		// 	"AAABBBCCC Hi there! 1234\n\nI'm typing a really long line Note: In the example above, a case statement reads '65, 90'. This is an example where a case expects to match either of the two (or several) values, listed as delimited by comma(s). Switches in Haxe are different from traditional switches: all cases are separate expressions so after one case expression is executed the switch block is automatically exited. As a consequence, break can't be used in a switch and the position of the default case is not important. On some platforms, switches on constant values (especially constant integers) might be optimized for better speed. Switches can also be used on enums with different semantics. It will be explained later in this document.", 	
		// 	640, 480, true, Center, Center, -4, -2);
		// HXP.scene.add(e);

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
