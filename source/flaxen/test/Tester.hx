package flaxen.test; 

import haxe.unit.TestRunner;
import flaxen.Log;
import openfl.display.Sprite;

/**
 * Unit test runner.
 */
class Tester extends Sprite
{
	public function new () 
	{
		super();
		var r = new TestRunner();
		r.add(new FlaxenTest());
		r.add(new ActionQueueTest());
		r.add(new TweenTest());
		r.run();

		#if !flash
		Log.quit();
		#end
	}
}
