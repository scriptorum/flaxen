//
// A position that can be serve as the parent position for children.
// The context of x/y means the absolute position of the entity.
// Parent is the parent entity, and offset is the relative position of this child.
// Anytime the parent is updated, the absolute x/y of the child is updated.
// Not great. Needed something to fit this bill.
// Note that if you assign x/y through the property or set() you will actually be
// changing the offset x/y. The x/y returns the absolute value. If you want the 
// relative value, use offset.x/y.
//
package flaxen.component;

import ash.signals.Signal0;

class NestablePosition extends flaxen.component.Position
{
	public var offset:Position;
	public var parent:Position;
	public var signal:Signal0;

	override public function new(x:Float, y:Float, parent:NestablePosition = null)
	{
		signal = new Signal0();
		offset = new Position(x,y);
		if(parent == null)
			this.parent = Position.zero();
		else 
		{
			this.parent = parent;
			parent.signal.add(this.updateAbsolute);
		}
		super(0, 0);
		updateAbsolute();
	}

	private function updateAbsolute()
	{
		this._x = parent.x + offset.x;
		this._y = parent.y + offset.y;
		signal.dispatch(); // Update children
	}

	override public function set(x:Float, y:Float)
	{
		offset.set(x, y);
		updateAbsolute();
	}

	override public function set_x(x:Float): Float
	{
		offset.x = x;
		updateAbsolute();
		return x;
	}

	override public function set_y(y:Float): Float
	{
		offset.y = y;
		updateAbsolute();
		return y;
	}

	override public function toString(): String
	{
		return "NestablePosition(absolute:" + super.toXY() + " offset:" + 
			offset.toXY() + " parent:" + parent.toXY() + ")";
	}
}