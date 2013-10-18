
package flaxen.core; 

import ash.core.Entity;
import com.haxepunk.HXP;
import flaxen.core.Flaxen;
import flaxen.component.Image;
import flaxen.component.Position;
import flaxen.component.Offset;

class Demo
{
	public static function main()
	{
		var flaxen = new Flaxen();
		//flaxen.addSystem();
		
		var e = flaxen.newEntity()
			.add(new Image("art/flaxen.png"))
			.add(new Position(HXP.halfWidth, HXP.halfHeight))
			.add(new Offset(-100, -50));
	}
}
