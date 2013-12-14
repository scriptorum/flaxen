package flaxen.component;

/*
 * This is for changing the transformation point of an Image. It does not change the center point!
 * To do that, use Offset. (Center point? Maybe you mean 'position' point?)
 * 
 * Note that HaxePunk's notion of origin really means "transformation and center point." I dunlike.
 *
 * TODO - Support percentage based origins like in Offset, and add center() static function
 */
class Origin
{
	public var x:Float;
	public var y:Float;

	public function new(x:Float, y:Float)
	{
		this.x = x;
		this.y = y;
	}
}