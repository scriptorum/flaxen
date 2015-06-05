package flaxen.demo; 

import ash.core.Entity;
import flaxen.component.Friction;
import flaxen.component.Gravity;
import flaxen.component.Image;
import flaxen.component.Offset;
import flaxen.component.Position;
import flaxen.component.Size;
import flaxen.component.Velocity;
import flaxen.component.Text;
import flaxen.Flaxen;
import flaxen.FlaxenHandler;
import flaxen.FlaxenSystem;
import flaxen.system.FrictionSystem;
import flaxen.system.GravitySystem;
import flaxen.system.MovementSystem;

/**
 *	Demonstrates movement, friction, and gravity.
 *
 * - TODO: Add a DeathRegion component and system for removing entities that cross into or exit a square region.
 */
class MotionHandler extends FlaxenHandler
{
	private static var extraSystems:Array<Class<FlaxenSystem>> = [MovementSystem, FrictionSystem, GravitySystem];
	private var posX:Float;
	private var posY:Float;

	override public function start()
	{
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
			.add(new Position(posX, posY));
		posX += 150;
		return e;
	}

	override public function stop()
	{
		for(s in extraSystems)
			f.removeSystemByClass(s);
	}
}
