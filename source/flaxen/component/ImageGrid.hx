// 
// Defines an image that is divided into subimages in a 2d array.
// Required for any views that uses Tile, Grid or Animation.
//

package flaxen.component;

class ImageGrid
{
	public var tileWidth:Int; // tile width
	public var tileHeight:Int; // tile height
	public var tilesAcross:Int; // Calculated by View
	public var tilesDown:Int; // Calculated by View

	public function new(width:Int, height:Int)
	{
		this.tileWidth = width;
		this.tileHeight = height;
	}

	public static function create(tileWidth:Int, tileHeight:Int): ImageGrid
	{
		return new ImageGrid(tileWidth, tileHeight);
	}
}