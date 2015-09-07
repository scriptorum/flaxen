package flaxen.component;

/**
 * Determines the amount of camera "Scroll Factor" applied to the HaxePunk Entity, which controls
 * how much the Camera position offsets the drawn entity. Can be used for a parallax effect.
 */
class ScrollFactor
{
	public static var lock:ScrollFactor = new ScrollFactor(0.0);	// Locks the entity to match the camera (e.g., for UI elements)
	public static var free:ScrollFactor = new ScrollFactor(1.0);	// Frees the entity from the camera (e.g. for scrolling maps, default)
	public static var half:ScrollFactor = new ScrollFactor(0.5);	// Scrolls at half speed (e.g., for parallax background)

	public var x:Float = 1;
	public var y:Float = 1;

    /**
     * Constructor
     * A scroll factor of 0,0 means no scrolling when the camera moves.
     * 1,1 moves with the camera.
     * @param x The horizontal scroll factor
     * @param y The vertical scroll factor (defaults to null; if null, y will match x)
     */
	public function new(x:Float = 0, y:Float = null)
	{
		this.x = x;
		this.y = (y == null ? x : y);
	}
}