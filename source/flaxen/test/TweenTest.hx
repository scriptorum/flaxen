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
		tween = new Tween(10.0);
		value = 0.0;
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
		assertTrue(true);
	}
	
	public function testScrub()
	{
		assertTrue(true);
	}
	
	public function testSetElapsed()
	{
		assertTrue(true);
	}
	
	public function testSetLoop()
	{
		assertTrue(true);
	}
	
	public function testSetMaxLoops()
	{
		assertTrue(true);
	}
	
	public function testSetName()
	{
		assertTrue(true);
	}
	
	public function testSetOnComplete()
	{
		assertTrue(true);
	}
	
	public function testSetOptional()
	{
		assertTrue(true);
	}

	public function testTweenSystem()
	{
		assertTrue(true);
	}
	
	public function testNewTween()
	{
		assertTrue(true);
	}
}
