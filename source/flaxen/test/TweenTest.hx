package flaxen.test; 

import ash.core.Entity;
import flaxen.common.Completable;
import flaxen.common.Easing;
import flaxen.common.LoopType.Forward;
import flaxen.common.LoopType;
import flaxen.component.Position;
import flaxen.component.Tween;
import flaxen.Flaxen;
import flaxen.node.TweenNode;
import flaxen.system.TweenSystem;

using StringTools;

class TweenTest extends FlaxenTestCase
{
	public var tween:Tween;
	public var value:Float;

	public function new() 
	{
		super();
	}

	override public function setup()
	{
		super.setup();
		value = 0.0;
		tween = new Tween(10.0);
	}

	public function testConstructor()
	{
		// Test limited args (TweenTest.setup)
		assertEquals(10.0, tween.duration);
		assertTrue(Easing.linear == tween.easing);
		assertEquals(LoopType.None, tween.loop);
		assertEquals(OnComplete.None, tween.onComplete);
		assertNull(tween.name);
		assertTrue(tween.running);

		// Test full args
		tween = new Tween(1.0, Easing.quadIn, Forward, DestroyComponent, false, "donuts");
		assertEquals(1.0, tween.duration);
		assertTrue(Easing.quadIn == tween.easing);
		assertFalse(Easing.linear == tween.easing);
		assertEquals(LoopType.Forward, tween.loop);
		assertEquals(OnComplete.DestroyComponent, tween.onComplete);
		assertEquals("donuts", tween.name);
		assertFalse(tween.running);

		// Test 0 duration exception
		assertException(function() { new Tween(0); });
		assertException(function() { new Tween(-1); });
	}

	public function testBasicTween()
	{
		var pos = Position.zero();
		tween.addTarget(pos, "x", 10);
		tween.addTarget(pos, "y", 20);
		tween.update(5); // halfway
		assertEquals(5.0, pos.x);
		assertEquals(10.0, pos.y); 
		assertFalse(tween.complete);
		tween.update(5); // finish
		assertTrue(tween.complete);
		assertEquals(10.0, pos.x);
		assertEquals(20.0, pos.y);
	}

	public function testInitial()
	{
		tween.to(this, "value", 100, 50);
		tween.update(0);
		assertEquals(50.0, value);
		assertFalse(tween.complete);
		tween.update(5);
		assertEquals(75.0, value);
		assertFalse(tween.complete);
		tween.update(10);
		assertEquals(100.0, value);
		assertTrue(tween.complete);
	}

	public function testEasing()
	{
		// Create custom easing
		var reverseEasing = function(t:Float): Float
		{
			return 1 - t;
		}

		tween.to(this, "value", 10, reverseEasing);
		tween.update(0);
		assertNear(10.0, value);
		tween.update(3);
		assertNear(7.0, value);
		tween.update(4);
		assertNear(3.0, value);
		tween.update(3);
		assertNear(0.0, value);
	}

	public function testPauseResume() 
	{
		tween.to(this, "value", 10.0);
		tween.update(5);
		assertEquals(5.0, value);
		tween.pause();
		assertFalse(tween.running);
		tween.update(5);
		assertEquals(5.0, value); // ensure no effect from paused update

		tween.resume();
		assertTrue(tween.running);
		tween.update(5);
		assertEquals(10.0, value); // ensure no effect from paused update
		assertTrue(tween.complete);
	}
	
	public function testAddTarget()
	{
		tween.to(this, "value", 10, 5, Easing.quadIn);
		tween.to(this, "value", 10);

		@:privateAccess assertEquals(2, tween.targets.length);
		@:privateAccess assertTrue(tween.targets[0].easing == Easing.quadIn);
		@:privateAccess assertTrue(tween.targets[1].easing == Easing.linear);
		@:privateAccess assertTrue(tween.targets[0].initial == 5.0);
		@:privateAccess assertTrue(tween.targets[1].initial == 0.0);
		@:privateAccess assertTrue(tween.targets[0].change == 5.0);
		@:privateAccess assertTrue(tween.targets[1].change == 10.0);
	}
	
	public function testRestart()
	{
		tween.to(this, "value", 10, 0);
		assertEquals(0.0, tween.elapsed);
		assertFalse(tween.complete);
		tween.update(5);
		assertFalse(tween.complete);
		assertEquals(5.0, tween.elapsed);
		tween.update(5);
		assertEquals(10.0, tween.elapsed);
		assertTrue(tween.complete);

		tween.restart();
		assertEquals(0.0, tween.elapsed);
		assertFalse(tween.complete);
		tween.update(5);
		assertFalse(tween.complete);
		assertEquals(5.0, tween.elapsed);
		tween.update(5);
		assertEquals(10.0, tween.elapsed);
		assertTrue(tween.complete);
	}
	
	public function testScrub()
	{
		tween.to(this, "value", 10);
		tween.scrub(0.5, true); // scrub as %
		assertEquals(5.0, value);
		assertFalse(tween.running);
		tween.scrub(1.0, true); // scrubbing to end should not complete tween
		assertEquals(10.0, value);
		assertFalse(tween.complete);
		tween.scrub(2.5); // scrub as elapsed
		assertEquals(2.5, value);
		tween.resume(); // turn off scrubbing
		assertTrue(tween.running);
		tween.update(2.5);
		assertEquals(5.0, value);
		tween.update(9999); // total elapsed cannot exceed duration
		assertTrue(tween.complete);
		assertEquals(10.0, tween.elapsed);
	}
	
	public function testSetElapsed()
	{
		assertTrue(true);
	}
	
	public function testLooping()
	{
		// Simple forward loop
		tween = new Tween(10.0, null, Forward);
		assertEquals(0, tween.loopCount);
		tween.update(999);
		assertEquals(1, tween.loopCount);
		assertEquals(0.0, tween.elapsed);
		tween.update(2.0);
		assertEquals(2.0, tween.elapsed); // Ensure we're going forward still
		tween.update(999);
		assertEquals(2, tween.loopCount);
		assertFalse(tween.complete);

		// Test backward
		tween = new Tween(10.0, null, Backward);
		tween.to(this, "value", 10, 0);
		tween.update(3);
		assertEquals(7.0, value); // test backward

		// Test forward and back looping
		tween = new Tween(10.0, null, Both);
		tween.to(this, "value", 10, 0);
		tween.update(3);
		assertEquals(0, tween.loopCount);
		assertEquals(3.0, value); // test forward
		tween.update(7);
		assertEquals(1, tween.loopCount); // loop
		assertEquals(10.0, value); // should still be at end
		tween.update(3); // test backward
		assertEquals(7.0, value); // should be backward
		tween.update(10);
		assertEquals(2, tween.loopCount); // loop again
		assertEquals(0.0, value); // should be at start
		tween.update(3);
		assertEquals(3.0, value); // And back to forward
	}
	
	public function testMaxLoops()
	{
		tween = new Tween(10.0, null, Forward)
			.setMaxLoops(3);
		assertFalse(tween.complete);
		assertEquals(0, tween.loopCount);
		tween.update(10);
		assertFalse(tween.complete);
		assertEquals(1, tween.loopCount);
		tween.update(10);
		assertFalse(tween.complete);
		assertEquals(2, tween.loopCount);
		tween.update(10);
		assertTrue(tween.complete);
		assertEquals(3, tween.loopCount);
	}
	
	public function testNewTween()
	{
		tween = f.newTween(10.0);
		assertTrue(tween.name.startsWith(Flaxen.tweenPrefix));
		assertTrue(tween.running);
		assertTrue(f.hasEntity(tween.name));
		assertEquals(DestroyEntity, tween.onComplete);
	}

	public function testTweenSystem()
	{
		var o = { first:0.0, second:0.0, third:0.0 };

		// Wrap free tween, do not destroy (default with manually constructed tween)
		var tween1 = new Tween(10)
			.addTarget(o, "first", 10);
		f.newWrapper(tween1, "first");
		assertTrue(f.hasEntity("first"));
		assertTrue(f.hasComponent("first", Tween));

		// Use newTween, destroy entity (default with newTween call)
		var tween2 = f.newTween(10)
			.addTarget(o, "second", 20);
		assertTrue(f.hasEntity(tween2.name));
		assertTrue(f.hasComponent(tween2.name, Tween));

		// Use newTween, destroy component (override default)
		var tween3 = f.newTween(10)
			.addTarget(o, "third", 30)
			.setOnComplete(DestroyComponent);
		assertTrue(f.hasEntity(tween3.name));
		assertTrue(f.hasComponent(tween3.name, Tween));

		assertEquals(3, f.countNodes(TweenNode));

		// Run the tween system, which should process all tweens in Ash
		f.ash.update(10); // run TweenSystem with time of 10s, enough to complete all tweens

		// Ensure all action queues ran to completion
		assertTrue(tween1.complete);
		assertTrue(tween2.complete);
		assertTrue(tween3.complete);

		// Ensure all values were updated appropriately
		assertEquals(10.0, o.first);
		assertEquals(20.0, o.second);
		assertEquals(30.0, o.third);

		// Ensure destroyed components/entities are gone, and everything else remains
		assertTrue(f.hasEntity("first"));
		assertTrue(f.hasComponent("first", Tween));
		assertFalse(f.hasEntity(tween2.name));
		assertTrue(f.hasEntity(tween3.name));
		assertFalse(f.hasComponent(tween3.name, Tween));	
	}
}
