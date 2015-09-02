
package flaxen.component;

/**
 * Applies a scale transformation to the entity.
 * If an entity also has a `Size` the scale will be applied to that Size.
 */
class Scale
{
	public var x:Float;
	public var y:Float;

	/**
	 * Constructor
	 * @param x The x scaling, defaults to 1.0 (no scaling)
	 * @param y The y scaling, defaults to null (uniform scaling; x==y)
	 */
	public function new(x:Float = 1.0, ?y:Float = null)
	{
		set(x, y);
	}

	public function set(x:Float, ?y:Float = null)
	{
		this.x = x;
		this.y = (y == null ? x : y);
	}

	public function clone(): Scale
	{
		return new Scale(x, y);
	}

	inline public static function full(): Scale
	{
		return new Scale();
	}

	inline public static function half(): Scale
	{
		return new Scale(0.5, 0.5);
	}

	inline public static function double(): Scale
	{
		return new Scale(2.0, 2.0);
	}
}