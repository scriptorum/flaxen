package flaxen.component;

import flaxen.component.TextSource;
import flaxen.component.Booster;
import flaxen.component.Position;

// Barrel or rocket
class Orb implements TextSourceProvider
{
	public static var MIN_SIZE:Int = 11;
	public static var ROCKET_COST:Int = 10;
	public static var MAX_SIZE:Int = 200; // Not really a max, but orbs larger than this don't slow more
	public static var SIZE_RANGE = MAX_SIZE - MIN_SIZE;

	public var startingSize:Float;
	public var size:Float;
	public var isRocket:Bool = false;
	public var changed:Bool = true; // If size changed
	public var fired:Bool = false;
	public var needsBoost:Bool = false;
	public var lastBooster:Booster = null;
	public var launchPos:Position = null;
	public var actionQueueEntityName:String = null;
	public var tweenEntityName:String = null;
	public var launchPower:Float = 0;
	public var launchAngle:Float= 0;
	public var autoDestruct:Bool = false;

	public function new(size:Float = 100, isRocket:Bool = false)
	{
		this.size = size;
		this.isRocket = isRocket;
	}

	public function boost(booster:Booster): Void
	{
		lastBooster = booster;
		needsBoost = true;
	}

	public function fire(aq:String, tween:String, pos:Position, power:Float, angle:Float): Void
	{
		fired = true;
		actionQueueEntityName = aq;
		tweenEntityName = tween;
		launchPos = pos.clone();
		launchPower = power;
		launchAngle = angle;
	}

	public function turnToRocket(): Void
	{
		changed = true;
		isRocket = true;
		lastBooster = null;
		launchPos = null;
		launchPower = 0;
		needsBoost = false;
		actionQueueEntityName = null;
		tweenEntityName = null;
	}

	public function turnToBarrel(): Void
	{
		changed = true;
		isRocket = false;
		fired = false;
		actionQueueEntityName = null;
		tweenEntityName = null;
	}

	public function change(size:Float)
	{
		this.size = size;
		this.changed = true;
	}

	public function add(size:Float)
	{
		change(this.size + size);
	}

	public function getFloat(): Float
	{
		return size;
	}
}