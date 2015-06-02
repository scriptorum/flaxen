package flaxen.demo; 

import ash.core.Entity;
import flaxen.Flaxen;
import flaxen.component.Image;
import flaxen.component.Position;
import flaxen.component.Offset;
import flaxen.FlaxenHandler;

/**
 *	Shows a basic image, demonstrating showing an image, position, and offset.
 */
class SimpleHandler extends FlaxenHandler
{
	override public function start()
	{
		f.newEntity()
			.add(new Image("art/flaxen.png"))
			.add(Position.center())
			.add(Offset.center());
	}
}
