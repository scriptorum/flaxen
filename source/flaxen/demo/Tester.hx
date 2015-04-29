package flaxen.demo; 

import ash.core.Entity;
import flaxen.Flaxen;
import flaxen.component.Position;
import flaxen.component.Alpha;
import flaxen.component.Scale;

class Tester extends openfl.display.Sprite
{
	public function new () 
	{
		super();
		var r = new haxe.unit.TestRunner();
		var tests = new FlaxenTests();
		r.add(tests);
		r.run();

		#if cpp
		flaxen.Log.quit();
		#end
	}
}

class FlaxenTests extends haxe.unit.TestCase
{
	public var f:Flaxen;
	public var e:Entity;
	public var r:EntityRef;

	public function new() 
	{
		super();
	}

	public function assertNear(a:Float, b:Float, minDifference:Float = 0.00000001)
	{
		assertTrue(Math.abs(a-b) <= minDifference);
	}

	public function assertException(func:Void->Void)
	{
		var flag = false;
		try { func(); }
		catch(ex:Dynamic) { flag = true; }
		assertTrue(flag);
	}

	override public function setup()
	{
		f = new Flaxen();
	}

	override public function tearDown()
	{
		f = null;
	}

	public function testGenerateEntityName()
	{
		assertEquals("test0", f.generateEntityName("test#"));
		assertEquals("_entity1", f.generateEntityName());
		assertEquals("_entity2", f.generateEntityName(null));
		assertEquals("apples", f.generateEntityName("apples"));
	}

	public function testNewEntity()
	{
		e = f.newEntity("test#"); 
		assertEquals("test0", e.name);
		assertEquals(true, f.hasEntity(e.name));

		e = f.newEntity(); 
		assertEquals("_entity1", e.name);
		assertEquals(true, f.hasEntity("_entity1"));

		e = f.newEntity(null); 
		assertEquals("_entity2", e.name);
		assertEquals(true, f.hasEntity(e.name));

		e = f.newEntity("apples"); 
		assertEquals("apples", e.name);
		assertEquals(true, f.hasEntity("apples"));
	}

	public function testAddEntity()
	{
		e = f.newEntity("test#", false); 
		assertEquals("test0", e.name);
		assertEquals(false, f.hasEntity(e));
		f.ash.addEntity(e);
		assertEquals(true, f.hasEntity(e));

		e = f.newEntity(null, false); 
		assertEquals("_entity1", e.name);
		assertEquals(false, f.hasEntity(e));
		f.addEntity(e);
		assertEquals(true, f.hasEntity(e));

		e = f.newEntity("apples", false); 
		assertEquals("apples", e.name);
		assertEquals(false, f.hasEntity(e));
		f.addEntity(e);
		assertEquals(true, f.hasEntity("apples"));

		assertException(function() { f.addEntity(null); });

		e = f.newEntity("apples", false);
		assertException(function() { f.addEntity(e); });
	}

	public function testGetEntity()
	{
		// Success
		e = f.newEntity("bubbles");
		assertEquals(e, f.getEntity("bubbles"));

		// Failure - bad name
		assertEquals(null, f.getEntity("farts", false));
		assertException(function() { f.getEntity("farts"); });

		// Failure - not added to Ash - should be same as bad name
		e = f.newEntity("shampoo", false);
		assertEquals(null, f.getEntity("shampoo", false));
		assertException(function() { f.getEntity("shampoo"); });
	}

	public function testGetComponent()
	{
		// Full entity
		e = f.newEntity("bubbles");
		var pos = Position.zero();
		e.add(pos);
		assertEquals(pos, f.getComponent(e, Position));
		assertEquals(null, f.getComponent(e, Scale, false));
		assertException(function() { f.getComponent(e, Scale); });

		// Full entity name
		assertEquals(pos, f.getComponent("bubbles", Position));
		assertEquals(null, f.getComponent("bubbles", Scale, false));
		assertException(function() { f.getComponent("bubbles", Scale); });

		// Free entity
		e = f.newEntity("liberace", false);
		e.add(pos);
		assertEquals(pos, f.getComponent(e, Position));
		assertEquals(null, f.getComponent(e, Scale, false));
		assertException(function() { f.getComponent(e, Scale); });

		// Bad entity name
		assertEquals(null, f.getComponent("nobody", Position, false));
		assertException(function() { f.getComponent("nobody", Position); });
	}

	public function testHasComponent()
	{
		// Full entity
		e = f.newEntity("bubbles");
		e.add(Position.zero());
		assertTrue(f.hasComponent(e, Position));
		assertFalse(f.hasComponent(e, Scale));

		// Full entity name
		assertTrue(f.hasComponent("bubbles", Position));
		assertFalse(f.hasComponent("bubbles", Scale));

		// Free entity
		e = f.newEntity("liberace", false);
		e.add(Position.zero());
		assertTrue(f.hasComponent(e, Position));
		assertFalse(f.hasComponent(e, Scale));
		assertFalse(f.hasEntity(e));

		// Bad entity name
		assertException(function() { assertTrue(f.hasComponent("nobody", Position)); });
	}

	public function testRemoveComponent()
	{
		e = f.newEntity("bob");
		e.add(Position.zero());
		assertTrue(f.removeComponent(e, Position));
		assertFalse(f.removeComponent(e, Position, false));
		assertException(function() { f.removeComponent(e, Position); });
		assertFalse(f.hasComponent(e, Position));

		e = f.newEntity("nada", false);
		e.add(Position.zero());
		assertFalse(f.removeComponent("nada", Position, false));
		assertException(function() { f.removeComponent("nada", Position); });
		assertTrue(f.removeComponent(e, Position));
		assertFalse(f.hasComponent(e, Position));
	}

	public function testAddComponent()
	{
		var pos = Position.zero();
		var scale = Scale.full();

		// full entity
		e = f.newEntity("bob");
		f.addComponent(e, pos);
		assertTrue(f.hasComponent(e, Position));
		f.addComponent("bob", scale);
		assertTrue(f.hasComponent("bob", Scale));

		// free entity
		e = f.newEntity("frank", false);
		f.addComponent(e, pos);
		assertTrue(f.hasComponent(e, Position));

		// false entity
		assertEquals(null, f.addComponent("nobody", pos, null, false));
		assertException(function() { f.addComponent("nobody", scale); });

		// Component class redefined
		e = f.newEntity();
		var myPos = new MyPosition(10,10);
		f.addComponent(e, myPos);
		assertFalse(f.hasComponent(e, Position));
		f.addComponent(e, myPos, Position);
		assertTrue(f.hasComponent(e, Position));

		// Null entity
		assertEquals(null, f.addComponent(null, scale, false));
		assertException(function() { f.addComponent(null, scale); });

		// Null component
		e = f.newEntity();
		assertException(function() { f.addComponent(e, null); });
	}

	public function testAddComponents()
	{
		var pos = Position.zero();
		var scale = Scale.full();
		var components:Array<Dynamic> = [pos, scale];

		// full entity
		e = f.newEntity();
		assertEquals(e, f.addComponents(e, components));
		assertTrue(f.hasComponent(e, Position));
		assertTrue(f.hasComponent(e, Scale));

		e = f.newEntity("bob");
		assertEquals(e, f.addComponents("bob", components));
		assertTrue(f.hasComponent("bob", Position));
		assertTrue(f.hasComponent("bob", Scale));

		// free entity
		e = f.newEntity("frank", false);
		f.addComponents(e, components);
		assertTrue(f.hasComponent(e, Position));
		assertTrue(f.hasComponent(e, Scale));

		// false entity
		assertException(function() { f.addComponents("nobody", components); });
	}

	public function testResetEntity()
	{
		// Reset existing entity added to ash
		e = f.newEntity();
		e.add(Position.zero());
		assertEquals("_entity0", e.name);
		assertTrue(f.hasComponent(e, Position));
		var e2 = f.resetEntity(e);
		assertEquals(e, e2);
		assertFalse(f.hasComponent(e2, Position));
		
		// Pass string for free entity or fake entity
		assertException(function() { f.resetEntity("butterscotch"); } );

		// Pass free entity
		e = f.newEntity("dummy", false);
		e.add(Position.zero());
		assertFalse(f.hasEntity(e));
		assertTrue(f.hasComponent(e, Position));
	}

	public function testHasEntity()
	{
		// full entity
		e = f.newEntity("bob");
		assertTrue(f.hasEntity(e));
		assertTrue(f.hasEntity("bob"));

		// free entity
		e = f.newEntity("fred", false); // create free fred
		assertFalse(f.hasEntity("fred"));
		assertFalse(f.hasEntity(e));
		var e2 = f.newEntity("fred"); // Duplicate name beat you to it, free fred
		assertFalse(e == e2);
		assertFalse(f.hasEntity(e));
		assertTrue(f.hasEntity(e2));

		// false entity
		assertFalse(f.hasEntity("nobody"));

		// null
		assertFalse(f.hasEntity(null));
	}

	public function testResolveEntity()
	{
		// full entity		
		e = f.resolveEntity("resolver");
		assertTrue(f.hasEntity(e));
		var e2 = f.resolveEntity("resolver");
		assertTrue(f.hasEntity(e2));
		assertEquals(e, e2);

		// free entity
		e = f.newEntity("free", false);	
		assertFalse(f.hasEntity(e));
		var e2 = f.resolveEntity("free");
		assertFalse(e2 == e);
		assertFalse(f.hasEntity(e));
		assertTrue(f.hasEntity(e2));

		// null entity
		assertException(function() { f.resolveEntity(null); });
	}

	public function testResolveComponent()
	{
		// neither entity nor component exists
		var c = f.resolveComponent("newguy", Alpha, [0.5]);
		assertTrue(f.hasEntity("newguy"));
		assertTrue(f.hasComponent("newguy", Alpha));
		assertEquals(0.5, f.getComponent("newguy", Alpha).value);
		assertEquals(c, f.resolveComponent("newguy", Alpha, [0.5])); // should not recreate component

		// entity exists, but does not have component
		e = f.newEntity("second");
		assertEquals(0.3, f.resolveComponent(e, Alpha, [0.3]).value);
		e = f.newEntity("third");
		var a = f.resolveComponent("third", Alpha, [0.3]);
		assertEquals(a, e.get(Alpha));
		assertEquals(0.3, a.value);

		// entity has component
		e = f.newEntity("fourth");
		e.add(new Alpha(0.7));
		assertEquals(0.7, f.resolveComponent("fourth", Alpha, [0.2]).value);

		// free entity has component
		e = f.newEntity("dummy", false);
		assertFalse(f.hasEntity(e));
		assertEquals(0.9, f.resolveComponent(e, Alpha, [0.9]).value);
		assertFalse(f.hasEntity(e));
		assertTrue(f.hasComponent(e, Alpha));

		// null entity
		assertException(function() { f.resolveComponent(null, Position, [0,0]); });

		// null component
		e = f.newEntity();
		assertException(function() { f.resolveComponent(e, null, null); });

		// TODO Test null args, should be legit on component constructors with full defaults
	}
}

class MyPosition extends Position
{
	public var base:Bool = true;
	public function new(x:Float, y:Float)
	{
		super(x, y);
	}
}
