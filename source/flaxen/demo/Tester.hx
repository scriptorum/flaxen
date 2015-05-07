package flaxen.demo; 

import ash.core.Entity;
import ash.core.Node;
import flaxen.component.ActionQueue;
import flaxen.component.Timestamp;
import flaxen.Flaxen;
import flaxen.component.Position;
import flaxen.component.Alpha;
import flaxen.component.Scale;
import flaxen.common.Completable;
import flaxen.system.ActionSystem;

using StringTools;

/**
 * Unit tester.
 *
 *  - TODO Split test cases into separate files, move out of demo folder
 */
class Tester extends openfl.display.Sprite
{
	public function new () 
	{
		super();
		var r = new haxe.unit.TestRunner();
		r.add(new FlaxenTest());
		r.add(new ActionQueueTest());
		r.run();

		#if cpp
		flaxen.Log.quit();
		#end
	}
}

class FlaxenTestCase extends haxe.unit.TestCase
{
	public var f:Flaxen;
	public var e:Entity;
	public var r:EntityRef;

	public function new() 
	{
		super();
	}

	public function assertNear(a:Float, b:Float, minDifference:Float = 0.00000001, ?c:haxe.PosInfos)
	{
		var diff = Math.abs(a-b);
		if(diff <= minDifference)
			return;

		currentTest.success = false;
		currentTest.error   = 'expected $a and $b to be nearer, but were $diff apart';
		currentTest.posInfos = c;
		throw currentTest;
	}

	public function assertException(func:Void->Void, ?c:haxe.PosInfos)
	{
		var flag = false;
		try { func(); }
		catch(ex:Dynamic) { flag = true; }

		if(flag)
			return;

		currentTest.success = false;
		currentTest.error   = "expected exception";
		currentTest.posInfos = c;
		throw currentTest;
	}

	public function assertNull(val:Dynamic, ?c:haxe.PosInfos)
	{
		if(val == null)
			return;

		currentTest.success = false;
		currentTest.error   = 'expected non null, but was $val';
		currentTest.posInfos = c;
		throw currentTest;
	}

	override public function setup()
	{
		f = new Flaxen();
	}
}

class FlaxenTest extends FlaxenTestCase
{
	public function new() 
	{
		super();
	}

	public function testNewEntity()
	{
		e = f.newEntity("test#"); 
		assertTrue(e.name.startsWith("test"));
		assertEquals(true, f.hasEntity(e.name));

		e = f.newEntity(); 
		assertTrue(e.name.startsWith(Flaxen.entityPrefix));
		assertEquals(true, f.hasEntity(e));
		var lastName = e.name;

		e = f.newEntity(null); 
		assertTrue(e.name.startsWith(Flaxen.entityPrefix));
		assertFalse(e.name == lastName);
		assertEquals(true, f.hasEntity(e.name));

		e = f.newEntity("apples"); 
		assertEquals("apples", e.name);
		assertEquals(true, f.hasEntity("apples"));
	}

	public function testAddEntity()
	{
		e = f.newEntity("test#", false); 
		assertEquals(false, f.hasEntity(e));
		f.ash.addEntity(e);
		assertEquals(true, f.hasEntity(e));

		e = f.newEntity(null, false); 
		assertEquals(false, f.hasEntity(e));
		f.addEntity(e);
		assertEquals(true, f.hasEntity(e));

		e = f.newEntity("apples", false); 
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
		assertFalse(f.hasComponent(e, Position));
		assertFalse(f.hasComponent(e, Scale));
		assertFalse(f.hasComponent("bubbles", Position));
		assertFalse(f.hasComponent("bubbles", Scale));
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
		assertTrue(e.name.startsWith(Flaxen.entityPrefix));
		e.add(Position.zero());
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

	public function testRemoveEntity()
	{
		// Test by name
		e = f.newEntity("bilbo"); 
		assertTrue(f.hasEntity("bilbo"));
		f.removeEntity("bilbo");
		assertFalse(f.hasEntity("bilbo"));

		// Test by entity
		e = f.newEntity(); 
		assertTrue(f.hasEntity(e));
		f.removeEntity(e);
		assertFalse(f.hasEntity(e));
	}

	public function getAllEntities()
	{
		// Test get all entities
		f.newEntity("bad");
		f.newEntity("leroy");
		f.newEntity("brown");

		var marks:Map<String, Int> = [ "bad" => 0, "leroy" => 0, "brown" => 0 ];
		for(e in f.getAllEntities())
			marks[e.name] += 1;

		assertEquals(1, marks["bad"]);
		assertEquals(1, marks["leroy"]);
		assertEquals(1, marks["brown"]);
	}

	public function testMarkers()
	{
		var name = f.newMarker("fred");
		assertEquals("_marker:fred", name);
		assertTrue(f.hasEntity(name));
		assertTrue(f.hasMarker("fred"));
		f.newMarker("fred"); // should not exception, although this does nothing (marker already exists)
		f.removeMarker("fred");
		assertFalse(f.hasMarker("fred"));
		f.removeMarker("fred"); // should not exception, although this does nothing (marker already removed)
	}

	public function testGetOneEntity()
	{
		// Test compulsory none exist throws exception
		assertException(function() { f.getOneEntity(AlphaNode); });

		// Test none exist returns null
		assertEquals(null, f.getOneEntity(AlphaNode, false));

		// Test one exists success
		e = f.newEntity();
		e.add(new Alpha(0));
		assertTrue(f.hasEntity(e));
		assertTrue(f.hasComponent(e, Alpha));
		assertEquals(e, f.getOneEntity(AlphaNode));

		// Test compulsory multiple exist exception
		var e2 = f.newEntity();
		e2.add(new Alpha(1));
		assertException(function() { f.getOneEntity(AlphaNode); });

		// Test multiple exist returns any one of
		var result = f.getOneEntity(AlphaNode, false);
		assertTrue(result == e || result == e2);
	}

	public function testCountNodes()
	{
		f.newEntity().add(Position.zero()); // ensure nonmatching nodes are not picked up
		assertEquals(0, f.countNodes(ScaleNode));
		f.newEntity().add(Scale.full());
		assertEquals(1, f.countNodes(ScaleNode));		
		f.newEntity().add(Scale.half());
		assertEquals(2, f.countNodes(ScaleNode));		
		e = f.newEntity().add(Scale.double());
		assertEquals(3, f.countNodes(ScaleNode));
		f.removeEntity(e);
		assertEquals(2, f.countNodes(ScaleNode));		
	}

	public function testNewWrapper()
	{
		// Add wrapper no name
		var pos = Position.zero();
		e = f.newWrapper(pos);
		assertTrue(f.hasEntity(e));
		assertTrue(e.name.startsWith(Flaxen.wrapperPrefix));
		assertEquals(pos, f.getComponent(e, Position));

		// Add wrapper with name
		e = f.newWrapper(pos, "bob");
		assertTrue(f.hasEntity(e));
		assertEquals("bob", e.name);
		assertEquals(pos, f.getComponent(e, Position));

		// Add wrapper with prefix
		e = f.newWrapper(pos, "twerk#");
		assertTrue(f.hasEntity(e));
		assertTrue(e.name.startsWith("twerk"));
		assertEquals(pos, f.getComponent(e, Position));
	}

	public function testGetEntities()
	{
		f.newWrapper(Alpha.opaque());
		f.newWrapper(Alpha.clear());
		e = f.newWrapper(Scale.full());

		var res = f.getEntities(AlphaNode);
		assertEquals(2, res.length);

		res = f.getEntities(ScaleNode);
		assertEquals(1, res.length);
		assertEquals(e, res[0]);
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

class ActionQueueTest extends FlaxenTestCase
{
	public var aq:ActionQueue;

	public function new() 
	{
		super();
	}

	override public function setup()
	{
		super.setup();
		aq = new ActionQueue();
	}

	public function testConstructor()
	{
		// Test no args (aq already created in setup)
		assertEquals(None, aq.onComplete);
		assertEquals(true, aq.running);
		assertEquals(null, aq.name);

		// Test full args
		aq = new ActionQueue(f, DestroyEntity, false, "bobby");
		assertEquals(DestroyEntity, aq.onComplete);
		assertEquals(false, aq.running);
		assertEquals("bobby", aq.name);
	}

	public function testAddActions() 
	{
		e = new Entity("burp");
		var pos = Position.zero();
		var act1 = new flaxen.action.ActionAddEntity(f, e);
		var act2 = new flaxen.action.ActionAddComponent(e, pos);
		var i = 0;
		var act3 = new flaxen.action.ActionThread(function() { return i++ > 0; }); 
		aq.addActions([act1, act2, act3]);

		assertFalse(f.hasEntity(e));
		assertFalse(aq.execute()); // execute all actions up to thread
		assertTrue(f.hasEntity(e));
		assertTrue(f.hasComponent(e, Position));
		assertTrue(aq.execute()); // execute thread again, which should now return true
	} 

	public function testWait() 
	{
		aq.wait(0.01); // 10ms
		assertFalse(aq.execute());
		var t1 = Timestamp.now();
		while(Timestamp.now() - t1 < 10) {}
		assertTrue(aq.execute());
	} 

	public function testLog()
	{
		var msg = "Testing log";
		aq.log(msg);
		assertTrue(aq.execute());
		assertEquals(msg, flaxen.Log.last);
	} 

	public function testAddComponent()
	{
		e = new Entity();
		var pos = Position.zero();
		aq.addComponent(e, pos);
		assertEquals(null, e.get(Position));
		assertTrue(aq.execute());
		assertEquals(pos, e.get(Position));
	}

	public function testRemoveComponent()
	{
		e = new Entity();
		var pos = Position.zero();
		e.add(pos);
		assertEquals(pos, e.get(Position));
		aq.removeComponent(e, Position);
		assertTrue(aq.execute());
		assertEquals(null, e.get(Position));
	}

	public function testAddEntity()
	{
		aq = new ActionQueue(f); // need flaxen
		e = new Entity();
		aq.addEntity(e);
		assertFalse(f.hasEntity(e));
		assertTrue(aq.execute());
		assertTrue(f.hasEntity(e));
	}

	public function testRemoveEntity()
	{
		aq = new ActionQueue(f); // need flaxen
		e = f.newEntity();
		aq.removeEntity(e);
		assertTrue(f.hasEntity(e));
		assertTrue(aq.execute());
		assertFalse(f.hasEntity(e));
	}

	public function testSetProperty()
	{
		var pos = Position.zero();
		aq.setProperty(pos, "x", 10.0);
		assertEquals(0.0, pos.x);
		assertTrue(aq.execute());
		assertEquals(10.0, pos.x);
	}

	public function testWaitForProperty()
	{
		var pos = Position.zero();
		aq.waitForProperty(pos, "x", 10.0);
		do { assertFalse(aq.execute()); }
		while(++pos.x < 10.0);
		assertTrue(aq.execute());
	}

	public function testCall()
	{
		var called = false;
		aq.call(function() { called = true; });
		assertFalse(called);
		assertTrue(aq.execute());
		assertTrue(called);
	}

	public function testWaitForCall()
	{
		var i = 0;
		aq.waitForCall(function() { return(++i > 1); });
		assertEquals(0, i);
		assertFalse(aq.execute());
		assertEquals(1, i);
		assertTrue(aq.execute());
		assertEquals(2, i);
	}

	public function testWrap()
	{
		aq = new ActionQueue(f); // need flaxen
		var pos = Position.zero();

		// Named entity
		aq.wrap(pos, "bubba");
		assertFalse(f.hasEntity("bubba"));
		assertFalse(f.hasComponent("bubba", Position));
		assertNull(f.getComponent("bubba", Position, false));
		assertTrue(aq.execute());
		assertTrue(f.hasEntity("bubba"));
		assertTrue(f.hasComponent("bubba", Position));
		assertEquals(pos, f.getComponent("bubba", Position));

		// Unnamed entity
		var scale = Scale.half();
		aq.wrap(scale);
		assertEquals(0, f.countNodes(ScaleNode));
		assertTrue(aq.execute());
		assertEquals(1, f.countNodes(ScaleNode));

		// Prefixed entity
		var alpha = Alpha.half();
		aq.wrap(alpha, "shrimp#");
		assertEquals(0, f.countNodes(AlphaNode));
		assertTrue(aq.execute());
		assertEquals(1, f.countNodes(AlphaNode));
		e = f.getOneEntity(AlphaNode);
		assertTrue(e.name.startsWith("shrimp"));
		assertTrue(f.hasEntity(e));
		assertTrue(f.hasComponent(e, Alpha));
		assertEquals(alpha, f.getComponent(e, Alpha));
	}

	public function testWaitForWrap()
	{
		aq = new ActionQueue(f);
		var comp:Completable = new Task();
		aq.waitForWrap(comp, "bubba");
		assertFalse(f.hasEntity("bubba"));
		assertFalse(aq.execute());
		assertTrue(f.hasEntity("bubba"));
		comp.complete = true;
		assertTrue(aq.execute());
	}

	public function testWaitForComplete()
	{
		var comp:Completable = new Task();
		aq.waitForComplete(comp);
		assertFalse(aq.execute());
		comp.complete = true;
		assertTrue(aq.execute());
	}

	public function testPriorityActions()
	{
		// Modify almost-empty queue
		aq = new ActionQueue(f);
		var o = { value:0 };
		assertEquals(0, o.value);
		aq.call(function() { aq.setProperty(o, "value", 3, true); });
		assertTrue(aq.execute());
		assertEquals(3, o.value);

		// Modify longer queue
		aq = new ActionQueue(f);
		o = { value:0 };
		aq.call(function() { o.value++; });
		aq.call(function() { aq.setProperty(o, "value", o.value + 5, true); });
		aq.call(function() { o.value *= 2; });
		assertTrue(aq.execute());
		assertEquals(12, o.value);

		// Modify queue from outside
		aq = new ActionQueue(f);
		o = { value:1 };
		var inc = function() { o.value++; };
		var double = function() { o.value *= 2; };
		aq.call(inc); // 3rd
		aq.call(inc, true); // run first
		aq.call(double, true); // 2nd
		aq.call(inc); // 4th
		assertTrue(aq.execute()); // should do 1, inc, double, inc, inc = 6
		assertEquals(6, o.value);
	} 

	// A more pragmatic example would be involve the ActionSystem, which this test does not
	// Something like: aq.waitForWrap(new ActionQueue().etc....)
	public function testNestedEntityQueue()
	{
		var a = 5;
		var addTen = function() { a += 10; };
		var timesTwo = function() { a *= 2; };

		var aq2 = new ActionQueue(f);
		aq2.call(addTen);
		aq2.call(addTen);

		aq.call(timesTwo);
		aq.waitForComplete(aq2);
		aq.call(timesTwo);

		assertFalse(aq.execute()); // run up to aq2
		assertTrue(aq2.execute()); // now complete aq2
		assertTrue(aq.execute()); // and finish aq
	
		assertEquals(60, a);
	}

	public function testRunning()
	{
		// Test running default
		assertTrue(aq.running);
		aq.call(function(){});
		assertTrue(aq.execute());
		assertTrue(aq.running);

		// Test delayed start, running initially false
		aq = new ActionQueue(f, None, false);
		assertFalse(aq.running);
		aq.running = true;
		aq.call(function(){});
		assertTrue(aq.execute());
		assertTrue(aq.running);
	}

	public function testComplete()
	{
		var val = 10;
		aq = f.newActionQueue()
			.call(function() { val *= 2; })
			.call(function() { val++; });

		assertFalse(aq.complete);
		aq.execute();
		assertTrue(aq.complete);
	}

	public function testPauseResume() 
	{
		var t = new Task();
		aq.waitForComplete(t);
		aq.waitForProperty(t, "complete", false);
		assertFalse(aq.execute());
		t.complete = true;
		assertFalse(aq.execute());
		t.complete = false; // meet the next action's condition
		aq.pause(); // turn off running
		for(i in 0...5) // Just to be sure, should stay false until resume
			assertFalse(aq.execute()); 
		aq.resume(); // Okay now resume
		assertTrue(aq.execute()); // And this one completes
		assertTrue(aq.complete);
	} 

	public function testWaitOnce()
	{
		aq.waitOnce();
		assertFalse(aq.execute());
		assertFalse(aq.complete);
		assertTrue(aq.execute());
		assertTrue(aq.complete);
	}

	public function testNewActionQueue()
	{
		aq = f.newActionQueue();
		assertTrue(aq.name.startsWith(Flaxen.actionQueuePrefix));
		assertTrue(aq.running);
		assertTrue(f.hasEntity(aq.name));
		assertEquals(DestroyEntity, aq.onComplete);
	}

	public function testActionSystem()
	{
		// Wrap free action queue, do not destroy (default with manually constructed queue)
		var val1 = 3;
		var aq1 = new ActionQueue()
			.call(function() { val1 *= 2; })
			.call(function() { val1++; });
		f.newWrapper(aq1, "first");
		assertTrue(f.hasEntity("first"));
		assertTrue(f.hasComponent("first", ActionQueue));

		// Use newActionQueue, destroy entity (default with newActionQueue call)
		var val2 = 10;
		var aq2 = f.newActionQueue()
			.call(function() { val2 *= 2; })
			.call(function() { val2++; });
		assertTrue(f.hasEntity(aq2.name));
		assertTrue(f.hasComponent(aq2.name, ActionQueue));

		// Use newActionQueue, destroy component (override default)
		var val3 = 50;
		var aq3 = f.newActionQueue()
			.call(function() { val3 *= 2; })
			.call(function() { val3++; })
			.setOnComplete(DestroyComponent);
		assertTrue(f.hasEntity(aq3.name));
		assertTrue(f.hasComponent(aq3.name, ActionQueue));

		assertEquals(3, f.countNodes(ActionQueueNode));

		// Run the action system, which should process all ActionQueues in Ash
		f.ash.update(0); // run ActionSystem along with other default systems

		// new ActionSystem(f).update(0);  // Would like to but can't test this way
		// The above is an illegal construct; Ash systems must be run by Ash or 
		// removed nodes can affect updating

		// Ensure all action queues ran to completion
		assertTrue(aq1.complete);
		assertTrue(aq2.complete);
		assertTrue(aq3.complete);

		// Ensure all values were updated appropriately
		assertEquals(7, val1);
		assertEquals(21, val2);
		assertEquals(101, val3);

		// Ensure destroyed components/entities are gone, and everything else remains
		assertTrue(f.hasEntity("first"));
		assertTrue(f.hasComponent("first", ActionQueue));
		assertFalse(f.hasEntity(aq2.name));
		assertTrue(f.hasEntity(aq3.name));
		assertFalse(f.hasComponent(aq3.name, ActionQueue));
	}
}

class Task implements Completable
{
	public var complete:Bool = false;
	public function new() { }
}

class ScaleNode extends Node<ScaleNode>
{
	public var scale:Scale;
}

class AlphaNode extends Node<AlphaNode>
{
	public var Alpha:Alpha;
}