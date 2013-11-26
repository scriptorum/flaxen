package flaxen.common;

import flaxen.common.Point;
import flaxen.util.MathUtil;
import flaxen.util.ArrayUtil;
import flaxen.core.Log;

class Array2D<T>
{
	private static var ORTHONGONAL_NEIGHBORS = Point.makeArray([-1,0,    0,-1,  1,0,   0,1]);
	private static var DIAGONAL_NEIGHBORS =    Point.makeArray([-1,-1,  1,-1,  -1,1,  1,1]);

	public var array:Array<T>;
	public var width:Int;
	public var height:Int;
	public var size:Int;

	public function new(width:Int, height:Int, fill:Dynamic)
	{
		this.width = width;
		this.height = height;
		this.size = width * height;
		array = new Array<T>();
		clear(fill);
	}

	public function clear(fill:Dynamic)
	{
		setRect(0, 0, width, height, fill);
	}

	inline public function indexWithinDomain(index:Int): Bool
	{
		return (index >= 0 && index < size);
	}

	inline public function verifyIndex(index:Int): Void
	{
		if (!indexWithinDomain(index))
			Log.error("Array2D index " + index + " is out of bounds");
	}

	public function withinDomain(x:Int, y:Int): Bool
	{
		return (x >= 0 && x < width && y >= 0 && y < height);
	}

	public function verify(x:Int, y:Int): Void
	{
		if (!withinDomain(x, y))
			Log.error("Array2D position " + x + "," + y +" is out of bounds");
	}

	public function getIndex(index:Int): T
	{
		verifyIndex(index);
		return array[index];
	}

	public function get(x:Int, y:Int): T
	{
		verify(x, y);
		return array[indexOf(x,y)];
	}

	public function setIndex(index:Int, value:T): Array2D<T>
	{
		verifyIndex(index);
		array[index] = value;
		return this;
	}

	public function set(x:Int, y:Int, value:T): Array2D<T>
	{
		verify(x, y);
		array[indexOf(x,y)] = value;
		return this;
	}

	public inline function indexOf(x:Int, y:Int): Int
	{
		return x + y * width;
	}

	public inline function fromIndex(index:Int): Point
	{
		var x = index % width;
		var y = Math.floor(index / width);
		return new Point(x, y);
	}

	public function setRect(xOff:Int, yOff:Int, width:Int, height:Int, value:Dynamic): Array2D<T>
	{
		for(x in xOff...width + xOff)
		for(y in yOff...height + yOff)
		{
			var v:T = (Std.is(value, Array) ? ArrayUtil.anyOneOf(value) : value);
			set(x, y, v);
		}
		return this;
	}

	// TODO change to static
	public function pointsMatch(x1:Int, y1:Int, x2:Int, y2:Int): Bool
	{
		return (x1 == x2 && y1 == y2);
	}

	// TODO change to static
	// If orthogonalOnly is passed, diagonal points are not considered adjacent
	public function pointsAreAdjacent(x1:Int, y1:Int, x2:Int, y2:Int, orthogonalOnly:Bool = false): Bool
	{
		var dx = MathUtil.idiff(x1, x2);
		var dy = MathUtil.idiff(y1, y2);

		if(orthogonalOnly)
			return ((dx == 1 && dy == 0) || (dx == 0 && dy == 1));

		return (pointsMatch(x1, y1, x2, y2) ? false : (dx <= 1 && dy <= 1));
	}

	public function indecesAreAdjacent(index1:Int, index2:Int, orthogonalOnly:Bool = false): Bool
	{
		var pt1 = fromIndex(index1);
		var pt2 = fromIndex(index2);
		return pointsAreAdjacent(pt1.x, pt1.y, pt2.x, pt2.y, orthogonalOnly);
	}

	public function getNeighboringIndeces(index:Int, orthogonalOnly:Bool = false): Array<Int>
	{
		var neighbors = new Array<Int>();
		var pt = fromIndex(index);
		for(set in orthogonalOnly ? [ORTHONGONAL_NEIGHBORS] : [ORTHONGONAL_NEIGHBORS, DIAGONAL_NEIGHBORS])
			for(offset in set)
			{
				var x = offset.x + pt.x;
				var y = offset.y + pt.y;
				if(withinDomain(x,y))
				{
					var idx = indexOf(x, y);
					neighbors.push(idx);
				}
			}

		return neighbors;
	}
}