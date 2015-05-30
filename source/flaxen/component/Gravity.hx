package flaxen.component;

/**
 * Gravity indicates the change of `flaxen.component.Velocity` over one second
 * towards a particular axis end (usually down).
 *
 * This is a low-rent Gravity implementation. It must be added to each entity
 * that experiences gravity, so it's not very useful as a broad spectrum force.
 * You must implement your own system to handle landing on floors/surfaces,
 * or going off-screen.
 *
 * This component is processed by the `flaxen.system.GravitySystem`.
 */
class Gravity
{
	/**
	 * The amount of gravity to apply. This is the amount to add to Velocity.
	 * and 0,-10 will add a 10 pixel downward velocty every second.
	 */
	public var x:Float = 0;
	public var y:Float = 0;

	/**
	 * Constructor.
	 * @param x The horizontal gravity, negative pulls left, positive pulls right
	 * @param y The vertical gravity, negative pulls down, positive pulls up
	 */
	public function new(x:Float = 0, y:Float = -10)
	{
		this.x = x;
		this.y = y;
	}
}