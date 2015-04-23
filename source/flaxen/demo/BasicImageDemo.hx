package flaxen.demo; 

import ash.core.Entity;
import flaxen.core.Flaxen;
import flaxen.component.Image;
import flaxen.component.Position;
import flaxen.component.Offset;

/**
 *	Shows a basic image, demonstrating showing an image, position, and offset.
 */
class BasicImageDemo extends Flaxen
{
	public static function main()
	{
		var demo = new BasicImageDemo();
	}

	override public function ready()
	{
		var e:Entity = newEntity()
			.add(new Image("art/flaxen.png"))
			.add(Position.center())
			.add(Offset.center());
	}
}
