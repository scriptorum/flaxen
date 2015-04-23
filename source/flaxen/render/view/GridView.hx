package flaxen.render.view;

import flaxen.component.ImageGrid;
import flaxen.component.Image;
import flaxen.component.Grid;

import com.haxepunk.graphics.Tilemap;

/**
 * Displays a 2D matrix of images using a HaxePunk Tilemap.
 *
 * - TODO: Should view classes such as this know about nodes?*
 */ 
class GridView extends View
{
	public var tileMap:Tilemap;
	public var tileWidth:Int;
	public var tileHeight:Int;

	override public function begin()	
	{
		var imageGrid = getComponent(ImageGrid);
		var grid = getComponent(Grid);
		var image = getComponent(Image);
		setImageDimensions(image, imageGrid);

		tileWidth = cast imageGrid.tileWidth;
		tileHeight = cast imageGrid.tileHeight;

		tileMap = new Tilemap(image.path, Std.int(image.width), Std.int(image.height), tileWidth, tileHeight);
		graphic = tileMap;
	}

	override public function nodeUpdate()
	{
		super.nodeUpdate();
		
		var g = getComponent(Grid);
		if(g.changed)
		{
			for(y in 0...g.height)
			for(x in 0...g.width)
			{
				if(g.eraseBeforeUpdate)
					tileMap.clearRect(x, y);
				tileMap.setTile(x, y, g.get(x, y));
			}

			g.changed = false;
		}
	}
}