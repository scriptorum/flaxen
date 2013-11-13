package flaxen.render.view;

import flash.geom.Rectangle;

import flaxen.component.Tile;
import flaxen.component.Image;

class ImageView extends View
{
	private var tile:Tile;
	private var tileNum:Int;
	private var image:Image;
	private var display:com.haxepunk.graphics.Image.Image;
	private var clip:Rectangle;

	override public function begin()
	{
		nodeUpdate();
	}

	private function setTile()
	{
		tile = getComponent(Tile);
		tileNum = tile.tile;
		image = getComponent(Image);
		var rect = tile.rect();
		graphic = display = new com.haxepunk.graphics.Image(image.path, rect);
		image.width = rect.width;
		image.height = rect.height;
	}

	private function setImage()
	{
		image = getComponent(Image);
		graphic = display = new com.haxepunk.graphics.Image(image.path, image.clip);
		clip = image.clip;
		if(clip == null)
		{
			image.width = display.width;
			image.height = display.height;
		}
		else
		{
			image.width = clip.width;
			image.height = clip.height;
		}
	}

	override public function nodeUpdate()
	{
		// Image with Tile
		if(hasComponent(Tile))
		{
			var curTile = getComponent(Tile);
			if(this.tile != curTile || this.image != getComponent(Image) ||  this.tileNum != curTile.tile)
				setTile();
		}

		// Image only
		else
		{
			var nextImage = getComponent(Image);
			if(this.image != nextImage || nextImage.clip != this.clip)
				setImage();
		}

		super.nodeUpdate();
	}
}