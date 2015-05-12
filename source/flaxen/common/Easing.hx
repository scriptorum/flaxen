package flaxen.common;

/**
 * A set of easing functions for tweening.
 *
 * Each `EasingFunction` takes a time value from 0-1, and returns an eased time value.
 * Some easing functions can return outside of the 0-1, say, to create an overshot/backup effect.
 *
 * These methods don't actually do any tweening, they only apply easing to a 0-1 T value. 
 * You might fight other easing systems calculating in start/change values and a 0-duration
 * time, but I think this "less pithy" way of doing easing functions puts the work of 
 * calculating the effect of an easing function on a tween into the Tween class itself, 
 * where t should be. 
 *
 * You can customize some of these easing functions using the customXxx methods.
 *
 * There are helper getXxx methods to assist you in creating your own easing functions.
 *
 * Although not a perfect match, you can use GreenSock's ease visualizer to 
 * get a better idea of how these easing functions affect movement:
 *
 * 		https://greensock.com/roughease
 */
class Easing
{
	/**
	 * Simple linear easing - i.e, no easing.
	 *
	 * This works like an easing function loopback, just passing back the supplied value.
	 * This method could have just as well been called `none`.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function linear(t:Float): Float
	{
		return t;
	}
			
	/**
	 * Quadratic in - accelerating from zero velocity.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function quadIn(t:Float): Float
	{
		return t * t;
	}
			
	/**
	 * Quadratic out - decelerating to zero velocity.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function quadOut(t:Float): Float
	{
		return getInverse(t, quadIn);
	}

	/**
	 * Quadratic easing in/out - acceleration until halfway, then deceleration.
	 *
	 * For quadOutIn, call poly(OutIn, 2).
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function quadInOut(t:Float): Float
	{
		return getSerial(t, quadIn, quadOut);
	}

	/**
	 * Cubic in - accelerating from zero velocity.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function cubicIn(t:Float): Float
	{
		return t * t * t;
	}

	/**
	 * Cubic out - decelerating to zero velocity.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function cubicOut(t:Float): Float
	{
		return getInverse(t, cubicIn);
	}

	/**
	 * Cubic easing in/out - acceleration until halfway, then deceleration
	 *
	 * For cubicOutIn, call poly(OutIn, 3).
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function cubicInOut(t:Float): Float
	{
		return getSerial(t, cubicIn, cubicOut);
	}

	/**
	 * Quartic in - accelerating from zero velocity.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function quartIn(t:Float): Float
	{
		return t * t * t * t;
	}

	/**
	 * Quartic easing out - decelerating to zero velocity.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function quartOut(t:Float): Float
	{
		return getInverse(t, quartIn);
	}

	/**
	 * Quartic easing in/out - acceleration until halfway, then deceleration.
	 *
	 * For quartOutIn, call poly(OutIn, 4).
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function quartInOut(t:Float): Float
	{
		return getSerial(t, quartIn, quartOut);
	}

	/**
	 * Quintic in - accelerating from zero velocity.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function quintIn(t:Float): Float
	{
		return t * t * t * t * t;
	}

	/**
	 * Quintic out - decelerating to zero velocity.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function quintOut(t:Float): Float
	{
		return getInverse(t, quintIn);
	}

	/**
	 * Quintic easing in/out - acceleration until halfway, then deceleration.
	 *
	 * For quintOutIn, call poly(OutIn, 3).
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function quintInOut(t:Float): Float
	{
		return getSerial(t, quintIn, quintOut);
	}

	/**
	 * Sinusoidal in - accelerating from zero velocity.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function sineIn(t:Float): Float
	{
		return -Math.cos(t * Math.PI / 2) + 1;
	}	

	/**
	 * Sinusoidal out - decelerating to zero velocity.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function sineOut(t:Float): Float
	{
		return getInverse(t, sineIn);
	}

	/**
	 * Sinusoidal in/out - accelerating until halfway, then decelerating.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function sineInOut(t:Float): Float
	{
		return getSerial(t, sineIn, sineOut);
	}		

	/**
	 * Exponential in - accelerating from zero velocity.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function expoIn(t:Float): Float
	{
		return Math.pow(2, 10 * (t - 1));
	}

	/**
	 * Exponential out - decelerating to zero velocity.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function expoOut(t:Float): Float
	{
		return getInverse(t, expoIn);
	}		

	/**
	 * Exponential in/out - accelerating until halfway, then decelerating.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function expoInOut(t:Float): Float
	{
		return getSerial(t, expoIn, expoOut);
	}

	/**
	 * Circular in - accelerating from zero velocity.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function circIn(t:Float): Float
	{
		return -(Math.sqrt(1 - t * t) - 1);
	}

	/**
	 * Circular out - decelerating to zero velocity.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function circOut(t:Float): Float
	{
		return getInverse(t, circIn);
	}			

	/**
	 * Circular easing in/out - acceleration until halfway, then deceleration.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function circInOut(t:Float): Float
	{
		return getSerial(t, circIn, circOut);
	}	 

	/**
	 * Back in - slow to back up, and then fast to target.
	 * 
	 * The backup amount is 10%. To customize this, create your 
	 * own easing function by calling `getBack`.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function backIn(t:Float): Float
	{
		return getBack(t, 1.70158); // 10% backup
	}

	/**
	 * Back out - slow to overshoot and then fast to target.
	 * 
	 * The overshoot amount is 10%. To customize this, create your 
	 * own easing function by calling the inverse of `getBack`.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function backOut(t:Float): Float
	{
		return getInverse(t, backIn); // 10% overshoot
	}
	 
	/**
	 * Back in/out - back up, overshoot target, and ease back.
	 *
	 * For back out/in, make your own easing function with
	 * `getSerial(t, backOut, backIn)`.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function backInOut(t:Float): Float
	{
		return getSerial(t, backIn, backOut);
	}

	/**
	 * Bounce in - four bounces, each dropping to 0 and gaining height.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function bounceIn(t:Float): Float
	{
		return getInverse(t, bounceOut);
	}
	 
	/**
	 * Bounce in - four bounces, each flying to 1 and losing height.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function bounceOut(t:Float): Float
	{
		if (t < (1 / 2.75))
			return (7.5625 * t * t);
		else if (t < (2 / 2.75))
		{
			t -= (1.5 / 2.75);
			return (7.5625 * t * t + .75);
		}
		else if (t < (2.5 / 2.75))
		{
			t -= (2.25 / 2.75);
			return (7.5625 * t * t + .9375);
		}

		t -= (2.625 / 2.75);
		return 7.5625 * t * t + .984375;
	}
	 
	/**
	 * Bounce in/out - bounce in to 0.5, then bounce out to 1.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function bounceInOut(t:Float): Float
	{
		return getSerial(t, bounceIn, bounceOut);
	}

	/**
	 * Totally random stuttering about the timeline. Totally. Random.
	 * The effect may look different depending on the frame rate.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	public static function random(t:Float): Float
	{
		return Math.random();
	}

	////// FUNCTIONS THAT RETURN CUSTOM EASING FUNCTIONS

	/**
	 * Custom polynomial easing.
	 *
	 * Supports any exponent. Supports In, Out, InOut, and OutIn.
	 *
	 * @param	dir			Which direction to ease, see `EaseDirection`
	 * @param	exp			The exponent for the polynomial; 2=quad, 3=cubic, 4=quartic, 5=quintic, etc.
	 * @param	midpoint	When doing InOut or OutIn, uses this to determine where to stop one ease and start the other
	 * @returns An easing function
	 */
	public static function customPoly(dir:EaseDirection, exp:Int = 2, midpoint = 0.5): EasingFunction
	{
		return switch(dir)
		{
			case In:
				return function(t:Float): Float 
				{ 
					return Math.pow(t, exp); 
				};

			case Out:
				return function(t:Float): Float 
				{ 
					return 1 - Math.pow(1 - t, exp); 
				};

			case InOut: 
				return function(t:Float): Float
				{ 
					return getSerial(t, customPoly(In, exp), customPoly(Out, exp), midpoint); 
				};

			case OutIn: 
				return function(t:Float): Float
				{ 
					return getSerial(t, customPoly(Out, exp), customPoly(In, exp), midpoint); 
				};
		}
	}

	/**
	 * Runs two easing functions in serial.
	 *
	 * Creates an easing function where the first ease occurs to the left 
	 * of the midpoint, and the second ease to the right of the midpoint.
	 * Each ease is scaled to fit within its range.
	 *
	 * @param	first		The first easing function, to operate from 0 to midpoint
	 * @param	second		The second easing function, to operate from midpoint to 1
	 * @param	midpoint	The point from 0-1 where the first easing turns to the second easing.
	 * @returns An easing function
	 */
	public static function customSerial(first:EasingFunction, second:EasingFunction, 
		midpoint:Float = 0.5): EasingFunction
	{
		return function(t:Float)
		{
			return getSerial(t, first, second, midpoint);
		}
	}

	/**
	 * Runs two easing functions in parallel.
	 *
	 * Supplies the result of the first easing function to the second easing function.
	 *
	 * @param	first		The first easing function
	 * @param	second		The second easing function
	 * @returns An easing function
	 */
	public static function customParallel(first:EasingFunction, second:EasingFunction): EasingFunction
	{
		return function(t:Float)
		{
			return getParallel(t, first, second);
		}
	}

	/**
	 * Applies jitter to another easing function.
	 *
	 * @param	func		The easing function to jitter
	 * @param	amount		The maximal amount of jitter; e.g., 0.1 means the variation is +/- 0.05.
	 * @returns An easing function
	 */
	public static function customJitter(func:EasingFunction, amount:Float = 0.05): EasingFunction
	{
		return function(t:Float)
		{
			return getJitter(func(t), amount);
		}
	}

	/**
	 * Applies a roughness to another easing function.
	 *
	 * You select the maximal amount of roughness, and the number of points to apply roughness.
	 * The roughness is interpolated between the points, so more points makes more perturbations.
	 *
	 * @param	func		The easing function to roughen
	 * @param	amount		The maximal amount of roughness; e.g., 0.1 means the variation is +/- 0.05.
	 * @param	points		The number of points where a new roughness peak is introduced
	 * @returns An easing function
	 */
	public static function customRough(func:EasingFunction, amount:Float = 0.1, points:Int = 10): EasingFunction
	{
		flaxen.Log.assert(points >= 2, 'Expected 2+ points but got $points');
		var intervals = 1 / points;
		var roughness = [];

		// Precalculate some roughness offsets at specified intervals
		{
			var side:Float = (Math.random() < 0.5 ? -1 : 1);
			var half:Float = amount / 2;
			for(p in 0...points + 1)
			{			
				var off = Math.random() * half;
				roughness.push(off * side);
				side *= -1;
			}
		}

		return function(t:Float)
		{
			var iPos:Float = t / intervals;						// determine position within division
			var c:Int = cast(iPos, Int);						// which closest point are we over
			var range:Float = roughness[c + 1] - roughness[c]; 	// determine range c and next point
			var t2:Float = iPos - c;							// determine 0-1 T between these two points
			var val = roughness[c] + range * t2;				// interpolate roughness at point T
			return func(t) + val;								// offset easing funciton with rough value
		}
	}	

	////// EASING FUNCTION HELPERS

	/**
	 * Returns the inverse value for an easing function, this applies the effect
	 * at the opposite sides of the timeline.
	 *
	 * Use this in an easing function definition.
	 *
	 * @param	t		A time value, usually from 0 to 1
	 * @param	func	An easing function to return the inverse of
	 * @returns	A time value, usually from 0 to 1
	 */
	inline public static function getInverse(t:Float, func:EasingFunction): Float
	{
		return 1 - func(1 - t);
	}		

	/**
	 * Combines two easing functions, serially.
	 *
	 * Returns a value where if t < midpoint, the value is eased and scaled 
	 * according to the first easing function, otherwise it is eased and scaled
	 * according to the second easing function.
	 *
	 * Use this in an easing function definition.
	 *
	 * - CONSIDER: Separate the time midpoint from the spatial midpoint, right now they mean the same thing
	 *
	 * @param	t			A time value, usually from 0 to 1
	 * @param	first		The first easing function, to operate from 0 to midpoint
	 * @param	second		The second easing function, to operate from midpoint to 1
	 * @param	midpoint	The point from 0-1 where the first easing turns to the second easing.
	 * @returns	A time value, usually from 0 to 1
	 */
	inline public static function getSerial(t:Float, first:EasingFunction, 
		second:EasingFunction, midpoint:Float = 0.5): Float
	{
		return (t < midpoint ? 
			first(t / midpoint) * midpoint : 
			second((t - midpoint) / (1 - midpoint)) * (1 - midpoint) + midpoint);
	}

	/**
	 * Combines two easing functions in parallel. The result of the first function
	 * is passed to the second function, and that result is returned.
	 *
	 * Use this in an easing function definition.
	 *
	 * @param	t			A time value, usually from 0 to 1
	 * @param	first		The first easing function, to operate from 0 to midpoint
	 * @param	second		The second easing function, to operate from midpoint to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	inline public static function getParallel(t:Float, first:EasingFunction,
		second:EasingFunction): Float
	{
		return second(first(t));
	}

	/**
	 * Adds an amount of continuous jitter to a T value.
	 *
	 * Use this in an easing function definition.
	 *
	 * @param	t			A time value, usually from 0 to 1
	 * @param	first		The first easing function, to operate from 0 to midpoint
	 * @param	second		The second easing function, to operate from midpoint to 1
	 * @returns	A time value, usually from 0 to 1
	 */
	inline public static function getJitter(t:Float, jitterAmount:Float): Float
	{
		return (Math.random() * jitterAmount) - jitterAmount/2 + t;
	}

	/**
	 * Calculates the back in value. See `backIn`.
	 * 
	 * Returns an eased T that backs below 0 by `amount` up before shooting to 1.
	 *
	 * @param	t	A time value, usually from 0 to 1
	 * @param	amount	The amount to back up; the defaults corresponds to about a 10% backup
	 * @returns	A time value, usually from 0 to 1
	 */
	inline public static function getBack(t:Float, amount:Float = 1.70158): Float
	{
		return t * t * ((amount + 1) * t - amount);
	}
}

/** The definition of an easing function, takes a T value from 0-1 and returns an altered T value */
typedef EasingFunction = Float->Float;

/** Some customXxx methods use this as a parameter */
enum EaseDirection { In; Out; InOut; OutIn; }

