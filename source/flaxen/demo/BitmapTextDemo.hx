
package flaxen.demo; 

import ash.core.Entity;
import com.haxepunk.HXP;
import flaxen.core.Flaxen;
import flaxen.component.Image;
import flaxen.component.Position;
import flaxen.component.Offset;
import flaxen.component.Size;
import flaxen.component.Text;
import flaxen.util.Easing;

class BitmapTextDemo extends Flaxen
{
	public static function main()
	{
		var demo = new BitmapTextDemo();
	}

	override public function ready()
	{
		var e:Entity = newEntity()
			.add(new Image("art/impact20yellow.png"))
			.add(new Position(0, HXP.halfHeight - 10))
			.add(new Text("Hi there! 1234", TextStyle.createBitmap(new Size(20,20))));
	}
}
