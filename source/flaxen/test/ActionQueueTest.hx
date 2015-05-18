package flaxen.test; 

import ash.core.Entity;
import ash.core.Node;
import flaxen.common.Completable;
import flaxen.component.ActionQueue;
import flaxen.component.Alpha;
import flaxen.component.Position;
import flaxen.component.Scale;
import flaxen.component.Timestamp;
import flaxen.Flaxen;
import flaxen.node.ActionQueueNode;
import flaxen.system.ActionSystem;

using StringTools;

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

	public function testBatch()
	{
		// Create component set with shared Alpha component set to half opacity
		f.newComponentSet("centered")
			.add(Alpha.half());

		// Create empty entity
		e = f.newEntity();
		assertTrue(f.hasEntity(e));
		assertFalse(f.hasComponent(e, Alpha));

		// Create action queue
		aq = new ActionQueue(f);
		aq.addSet(e, "centered");

		// Run AQ, ensure entity has had batch applied
		aq.execute();
		assertTrue(f.hasEntity(e));
		assertTrue(f.hasComponent(e, Alpha));
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

///// HELPER CLASSES

@:dox(hide) private class Task implements Completable
{
	public var complete:Bool = false;
	public function new() { }
}

@:dox(hide) private class ScaleNode extends Node<ScaleNode>
{
	public var scale:Scale;
}

@:dox(hide) private class AlphaNode extends Node<AlphaNode>
{
	public var Alpha:Alpha;
}
