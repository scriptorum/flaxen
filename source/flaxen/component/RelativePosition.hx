/**
 * Maintains an absolute Position given parent and child Positions.
 * Whenever either parent or child are updated, this updates absolute.
 */
package flaxen.component;

class RelativePosition
{
	public var absolute:Position; // ultimate absolute position
	public var parent:Position; // master position
	public var child:Position; // position relative to parent

	public function new(absolute:Position, parent:Position, child:Position)
	{
		this.child = child;
		this.parent = parent;
		this.absolute = absolute;
		this.child.signal.add(updateAbsolute);
		this.parent.signal.add(updateAbsolute);
		updateAbsolute(null);
	}

	private function updateAbsolute(_)
	{
		absolute.set(parent.x + child.x, parent.y + child.y);
	}

	public function detach()
	{
		child.signal.remove(updateAbsolute);
		parent.signal.remove(updateAbsolute);
		absolute = child = parent = null; // now if you access these vars you get slapped
	}
}