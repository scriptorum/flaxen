package flaxen.component;

/**
 * Friction indicates the reduction of `flaxen.component.Velocity` over one second.
 * This component is processed by the `flaxen.system.FrictionSystem`.
 */
class Friction
{
	/**
	 * The amount of friction to apply. This is the amount of velocity to 
	 * reduce represented as a multipler. Therefore, 0 is no friction,
	 * and 0.1 will reduce velocity by 10% over the course of 1 second.
	 */
	public var amount:Float = 0;

	/** 
	 * If greater than zero, represents the minimum velocity for either 
	 * axis. If both axes drop below this value, the velocity is reduced 
	 * to 0. 
	 */
	public var minVelocity:Float = 0;

	/**
	 * If true, instead of reducing velocity to 0 when `minVelocity` is
	 * reached, the Velocity component will be removed. See the
	 * `FrictionSystem`. This can be used to reduce unnecessary processing.
	 */
	public var destroyComponent:Bool = false;

	/**
	 * Constructor.
	 * @param amount 0 is no friction, smaller the number, the lower the drag
	 * @param minVelocity If velocity drops below this, velocity is clamped to 0
	 * @param destroyComponent If true, when velocity reaches 0, this removes the Velocity altogether
	 */
	public function new(amount:Float, minVelocity:Float = 0, destroyComponent:Bool = false)
	{
		this.amount = amount;
		this.minVelocity = minVelocity;
		this.destroyComponent = destroyComponent;
	}
}