package flaxen.common;

typedef EasingFunction = Float->Float->Float->Float->Float->Float;

// Robert Penner's easing functions
// t: time
// b: start value
// c: change in value
// d: duration
// o: optional - an optional value not used on most easing functions
class Easing
{
	// simple linear tweening - no easing:Float, no acceleration
	public static function linearTween(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		return c * t / d + b;
	}
			
	// quadratic easing in - accelerating from zero velocity
	public static function easeInQuad(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		t /= d;
		return c * t * t + b;
	}
			
	// quadratic easing out - decelerating to zero velocity
	public static function easeOutQuad(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		t /= d;
		return - c * t * (t - 2) + b;
	}

	// quadratic easing in/out - acceleration until halfway:Float, then deceleration
	public static function easeInOutQuad(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		t /= d / 2;
		if(t < 1) return c / 2 * t * t + b;
		t--;
		return - c / 2 * (t * (t - 2) - 1) + b;
	}

	// cubic easing in - accelerating from zero velocity
	public static function easeInCubic(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		t /= d;
		return c * t * t * t + b;
	}

	// cubic easing out - decelerating to zero velocity
	public static function easeOutCubic(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		t /= d;
		t--;
		return c * (t * t * t + 1) + b;
	}

	// cubic easing in/out - acceleration until halfway:Float, then deceleration
	public static function easeInOutCubic(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		t /= d / 2;
		if(t < 1) return c / 2 * t * t * t + b;
		t -= 2;
		return c / 2 * (t * t * t + 2) + b;
	}

	// quartic easing in - accelerating from zero velocity
	public static function easeInQuart(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		t /= d;
		return c * t * t * t * t + b;
	}

	// quartic easing out - decelerating to zero velocity
	public static function easeOutQuart(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		t /= d;
		t--;
		return - c * (t * t * t * t - 1) + b;
	}

	// quartic easing in/out - acceleration until halfway:Float, then deceleration
	public static function easeInOutQuart(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		t /= d / 2;
		if(t < 1) return c / 2 * t * t * t * t + b;
		t -= 2;
		return - c / 2 * (t * t * t * t - 2) + b;
	}

	// quintic easing in - accelerating from zero velocity
	public static function easeInQuint(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		t /= d;
		return c * t * t * t * t * t + b;
	}

	// quintic easing out - decelerating to zero velocity
	public static function easeOutQuint(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		t /= d;
		t--;
		return c * (t * t * t * t * t + 1) + b;
	}

	// quintic easing in/out - acceleration until halfway:Float, then deceleration
	public static function easeInOutQuint(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		t /= d / 2;
		if(t < 1) return c / 2 * t * t * t * t * t + b;
		t -= 2;
		return c / 2 * (t * t * t * t * t + 2) + b;
	}

	// sinusoidal easing in - accelerating from zero velocity
	public static function easeInSine(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		return - c * Math.cos(t / d * (Math.PI / 2)) + c + b;
	}	

	// sinusoidal easing out - decelerating to zero velocity
	public static function easeOutSine(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		return c * Math.sin(t / d * (Math.PI / 2)) + b;
	}		

	// sinusoidal easing in/out - accelerating until halfway:Float, then decelerating
	public static function easeInOutSine(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		return - c / 2 * (Math.cos(Math.PI * t / d) - 1) + b;
	}		

	// exponential easing in - accelerating from zero velocity
	public static function easeInExpo(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		return c * Math.pow(2, 10 * (t / d - 1) ) + b;
	}

	// exponential easing out - decelerating to zero velocity
	public static function easeOutExpo(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		return c * (-Math.pow(2, - 10 * t / d ) + 1 ) + b;
	}		

	// exponential easing in/out - accelerating until halfway:Float, then decelerating
	public static function easeInOutExpo(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		t /= d / 2;
		if(t < 1) return c / 2 * Math.pow(2, 10 * (t - 1) ) + b;
		t--;
		return c / 2 * (-Math.pow(2, - 10 * t) + 2 ) + b;
	}

	// circular easing in - accelerating from zero velocity
	public static function easeInCirc(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		t /= d;
		return - c * (Math.sqrt(1 - t * t) - 1) + b;
	}

	// circular easing out - decelerating to zero velocity
	public static function easeOutCirc(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		t /= d;
		t--;
		return c * Math.sqrt(1 - t * t) + b;
	}			

	// circular easing in/out - acceleration until halfway:Float, then deceleration
	public static function easeInOutCirc(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		t /= d / 2;
		if(t < 1) return - c / 2 * (Math.sqrt(1 - t * t) - 1) + b;
		t -= 2;
		return c / 2 * (Math.sqrt(1 - t * t) + 1) + b;
	}	 

	// back easing in - back up on source
	// o=1.70158 for a 10% bounce
	public static function easeInBack(t:Float, b:Float, c:Float, d:Float, o:Float): Float
	{
		t /= d;
		return c * t * t * ((o + 1) * t - o) + b;
	}
	 
	// back easing out - overshoot target
	// o=1.70158 for a 10% bounce
	public static function easeOutBack(t:Float, b:Float, c:Float, d:Float, o:Float): Float
	{
		t = t / d - 1;
		return c * (t * t * ((o+1) * t + o) + 1) + b;
	}
	 
	// back easing in/out - back up on source then overshoot target
	// o=1.70158 for a 10% bounce
	public static function easeInOutBack(t:Float, b:Float, c:Float, d:Float, o:Float): Float
	{
		t /= d;
		o *= 1.525;
		if ((t / 2) < 1) return c / 2 * (t * t * ((o + 1) * t - o)) + b;
		t -= 2;
		return c / 2 * (t * t * ((o + 1) * t + o) + 2) + b;
	}

	// bounce easing in
	public static function easeInBounce(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		return c - easeOutBounce (d - t, 0, c, d) + b;
	}
	 
	// bounce easing out
	public static function easeOutBounce(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		t /= d;
		if (t < (1 / 2.75))
			return c * (7.5625 * t * t) + b;
		else if (t < (2 / 2.75))
		{
			t -= (1.5 / 2.75);
			return c * (7.5625 * t * t + .75) + b;
		}
		else if (t < (2.5 / 2.75))
		{
			t -= (2.25 / 2.75);
			return c * (7.5625 * t * t + .9375) + b;
		}

		t -= (2.625 / 2.75);
		return c * (7.5625 * t * t + .984375) + b;
	}
	 
	// bounce easing in/out
	public static function easeInOutBounce(t:Float, b:Float, c:Float, d:Float, ?o:Float): Float
	{
		if (t < d / 2) return easeInBounce (t * 2, 0, c, d) * .5 + b;
		return easeOutBounce(t * 2 - d, 0, c, d) * .5 + c * .5 + b;
	}
}
