package flaxen.component;

// Add to an entity as-is to affix the entity's image to the camera's position
// TODO Rename this class to something more understandable
class ScrollFactor
{
	public var amount:Float;
	public static var instance:ScrollFactor = new ScrollFactor(); // Affix entity to camera position

	public function new(amount:Float = 0)
	{
		this.amount = amount;
	}
}