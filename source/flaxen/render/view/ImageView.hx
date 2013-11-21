package flaxen.render.view;

import flash.geom.Rectangle;

import flaxen.component.Tile;
import flaxen.component.Subdivision;
import flaxen.component.Image;

class ImageView extends View
{
	private var tile:Tile;
	private var tileValue:Int;
	private var subdivision:Subdivision;
	private var image:Image;
	private var display:com.haxepunk.graphics.Image.Image;
	private var clip:Rectangle;

	override public function begin()
	{
		nodeUpdate();
	}

	private function setTile()
	{
		var rect = tile.rect(subdivision);
		graphic = display = new com.haxepunk.graphics.Image(image.path, rect);
		setImageDimensions(image);
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
		if(curImage != image || curImage.clip != clip)
		{
			image = curImage;
			clip = curImage.clip;
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

			var curSubdivision = getComponent(Subdivision); // required component if Tile exists
			if(curSubdivision != subdivision)
			{
				subdivision = curSubdivision;
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