package flaxen.demo; 

import ash.core.Entity;
import com.haxepunk.HXP;
import flaxen.core.Flaxen;
import flaxen.component.Image;
import flaxen.component.Position;
import flaxen.component.Offset;
import flaxen.component.Size;
import flaxen.component.Text;
import flaxen.common.Easing;
import flaxen.common.TextAlign;

class BitmapTextDemo extends Flaxen
{
	public static function main()
	{
		var demo = new BitmapTextDemo();
	}

/*
   Left Align Size Tests:
      Size 0, 0 -> No clipping
      Size X, 0 -> Clip to X, no vert clipping
      Size 0, Y -> Clip to Y, no horiz clipping

*/
	override public function ready()
	{
		var e:Entity = newEntity()
			.add(new Image("art/impact20yellow.png"))
			.add(new Position(HXP.halfWidth, HXP.halfHeight - 10))
			.add(new Size(HXP.width, 0))
			.add(new Text("AAABBBCCC\nHi there! 1234", 
				TextStyle.createBitmap(Center)));
	}
}
