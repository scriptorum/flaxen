package flaxen.component;

/**
 * Velocity indicates the distance moved in one second, applied to a
 * `flaxen.component.Position` component.
 *
 * This component is processed by the `flaxen.system.MovementSystem`.
 */
class Velocity
{
	/** The horizontal velocity */
	public var x:Float = 0;

	/** The horizontal velocity */
	public var y:Float = 0;

	/**
	 * Constructor.
	 * @param x The horizontal velocity
	 * @param y The vertical velocity
	 */
	public function new(x:Float, y:Float)
	{
		this.x = x;
		this.y = y;
	}

	/**
	 * This convenience method checks if both axes are within a certain 
	 * distance to 0. That is, if x is 5 and y is -5, lessThan(6) will 
	 * return true, but lessThan(5) will return false.
	 *
	 * - TODO: Users of this method may be more interested in 
	 * 	 checking the magnitude of x/y as a whole, rather than each
	 *   individual axis. Worth considering.
	 * 
	 * @param i The value to check for; must be a positive value
	 * @returns True if either axis is less than the value supplied
	 */
	public function lessThan(i:Float)
	{
		return (Math.abs(x) < i && Math.abs(y) < i);
	}

	/**
	 * Convenience setter.
	 * @param x The horizontal velocity
	 * @param y The vertical velocity
	 */
	public function set(x:Float, y:Float)
	{
		this.x = x;
		this.y = y;
	}

	/**
	 * Returns a new still, Velocity instance (0,0).
	 * @returns A Velocity instance
	 */
	public static function zero(): Velocity
	{
		return new Velocity(0, 0);
	}
}