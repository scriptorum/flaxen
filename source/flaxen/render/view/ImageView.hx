package flaxen.render.view;

import openfl.geom.Rectangle;

import flaxen.component.Tile;
import flaxen.component.ImageGrid;
import flaxen.component.Image;

class ImageView extends View
{
	private var tile:Tile;
	private var tileValue:Int;
	private var imageGrid:ImageGrid;
	private var image:Image;
	private var display:com.haxepunk.graphics.Image;
	private var clip:Rectangle;

	override public function begin()
	{
		nodeUpdate();
	}

	private function setTile()
	{
		setImageDimensions(image, imageGrid);
		var rect = tile.rect(imageGrid);
		graphic = display = new com.haxepunk.graphics.Image(image.path, rect);
		display.flipped = image.flipped;
	}

	private function setImage()
	{
		graphic = display = new com.haxepunk.graphics.Image(image.path, image.clip);
		display.flipped = image.flipped;
		setImageDimensions(image);
	}

	override public function nodeUpdate()
	{
		var updateDisplay = false;

		var curImage = getComponent(Image);
		if(curImage != image || ((clip == null) != (curImage.clip == null)) ||
			(curImage.clip != null && !curImage.clip.equals(clip)))
		{
			image = curImage;
			clip = (curImage != null && curImage.clip != null) ? curImage.clip.clone() : null;
			updateDisplay = true;
		}

		// Image with Tile
		if(hasComponent(Tile))
		{			
			var curTile = getComponent(Tile);
			if(curTile != tile || curTile.value != tileValue)
			{
				tile = curTile;
				tileValue = curTile.value;
				updateDisplay = true;
			}

			var curImageGrid = getComponent(ImageGrid); // required component if Tile exists
			if(curImageGrid != imageGrid)
			{
				imageGrid = curImageGrid;
				updateDisplay = true;
			}

			if(updateDisplay)
				setTile();
		}

		// Image only
		else
		{
			if(updateDisplay)
				setImage();
		}

		super.nodeUpdate();
	}
}