package flaxen.test; 

import ash.core.Entity;
import flaxen.Flaxen;

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
