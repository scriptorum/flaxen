package flaxen.demo; 

import ash.core.Entity;
import flaxen.component.DeathBox;
import flaxen.component.Friction;
import flaxen.component.Gravity;
import flaxen.component.Image;
import flaxen.component.Layer;
import flaxen.component.Offset;
import flaxen.component.Position;
import flaxen.component.Size;
import flaxen.component.Text;
import flaxen.component.Velocity;
import flaxen.Flaxen;
import flaxen.FlaxenHandler;
import flaxen.FlaxenSystem;
import flaxen.system.DeathBoxSystem;
import flaxen.system.FrictionSystem;
import flaxen.system.GravitySystem;
import flaxen.system.MovementSystem;
import openfl.geom.Rectangle;

/**
 *	Demonstrates movement, friction, and gravity.
 *
 * - TODO: Add a DeathRegion component and system for removing entities that cross into or exit a square region.
 */
class MotionHandler extends FlaxenHandler
{
	private var box:Rectangle = new Rectangle(100, 50, 400, 380);
	private var extraSystems:Array<Dynamic>;
	private var posX:Float;
	private var posY:Float;

	override public function start()
	{
		extraSystems = [MovementSystem, FrictionSystem, GravitySystem, DeathBoxSystem];	
		f.addSystems(extraSystems);

		posX = 150;
		posY = 80;

		newEnt("Velocity")
			.add(new Velocity(0,60));
		newEnt("Friction")
			.add(new Velocity(0,150))
			.add(new Friction(0.8, 5));
		newEnt("Gravity")
			.add(Velocity.zero())
			.add(new Gravity(0, 100));

		f.newEntity()
			.add(new Image("art/box.png"))
			.add(new Size(box.width, box.height))
			.add(new Position(box.x, box.y))
			.add(new Layer(20));
		f.newEntity()
			.add(new Text("DeathBox"))
			.add(TextStyle.createTTF(0x00FFFF, 14, null, Right))
			.add(new Size(100, 20))
			.add(new Position(box.x + box.width - 105, box.y + box.height - 25));
	}

	public function newEnt(name:String): Entity
	{
		f.newEntity()
			.add(new Text(name))
			.add(TextStyle.createTTF(0x00FFFF, 14, null, Center))
			.add(new Size(100, 20))
			.add(new Position(posX - 50, posY - 50));

		var e = f.newEntity()
			.add(new Image("art/f.png"))
			.add(Offset.center())
			.add(new Position(posX, posY))
			.add(new DeathBox(box, false));
		posX += 150;
		return e;
	}

	override public function stop()
	{
		for(s in extraSystems)
			f.removeSystemByClass(s);
	}
}
