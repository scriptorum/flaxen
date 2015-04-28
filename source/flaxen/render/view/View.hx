package flaxen.render.view;

import ash.core.Entity;
import com.haxepunk.Graphic;
import flaxen.component.Alpha;
import flaxen.component.Image;
import flaxen.component.ImageGrid;
import flaxen.component.Immutable;
import flaxen.component.Invisible;
import flaxen.component.Layer;
import flaxen.component.Layout;
import flaxen.component.Offset;
import flaxen.component.Origin;
import flaxen.component.Position;
import flaxen.component.Rotation;
import flaxen.component.Scale;
import flaxen.component.ScrollFactor;
import flaxen.component.Size;
import flaxen.Log;
import flaxen.render.view.View;
import openfl.display.Bitmap;

class View extends com.haxepunk.Entity
{
	public var entity:Entity;
	public var currentSize:Size = null;
	public var currentScale:Scale = null;
	public var currentGraphic:Graphic = null;

	public function new(entity:Entity)
	{
		super();

		this.entity = entity;
		begin();
		nodeUpdate();
	}

	public function hasComponent<T>(component:Class<T>): Bool
	{
		return entity.has(component);
	}

	public function getComponent<T>(component:Class<T>): T
	{
		var instance:T = entity.get(component);
		if(instance == null)
			Log.error("Cannot get component " + Type.getClassName(component) + " for entity " + entity.name);
		return instance;
	}

	public function begin(): Void
	{
		// Override
	}

	/**
	 * If you override this, call super
	 */
	public function nodeUpdate(): Void
	{
		if(graphic == null)
			return;	
			
		visible = !hasComponent(Invisible);
		if(!visible)
			return;

		var immutable:Immutable = entity.get(Immutable); 
		if(immutable != null) 
		{ 
			if(!immutable.changed)
				return;
			immutable.changed = false;
		}

		var graphicChanged = false;
		if(currentGraphic != graphic)
		{
			currentGraphic = graphic;
			graphicChanged = true;			
		}

		// Update layer
		var newLayer = hasComponent(Layer) ? getComponent(Layer).value : 0;	
		if(newLayer != this.layer)
			this.layer = newLayer;

		// Update scroll factor
		if(hasComponent(ScrollFactor))
		{
			if(graphic != null)
			{
				var amount = getComponent(ScrollFactor).amount;
				var graphic = cast(graphic, com.haxepunk.Graphic);
				if(amount != graphic.scrollX || amount != graphic.scrollY)
					graphic.scrollX = graphic.scrollY = amount;
			}
		} // TODO What if ScrollFactor is removed

		// For certain view subclasses
		var img:com.haxepunk.graphics.Image = 
			Std.is(graphic, com.haxepunk.graphics.Image) ? cast graphic : null;

		// Handle image specific updates
		var scaleChanged = graphicChanged;
		var sizeChanged = graphicChanged;
		if(img != null)
		{
			// Update specified size
			if(useSizeForImageScaling())
			{
				if(hasComponent(Size))
				{
					var size = getComponent(Size);
					if(currentSize == null || size.width != currentSize.width || size.height != currentSize.height)
					{
						scaleChanged = true;
						currentSize = size.clone();
					}
				}
				else if(currentSize != null)
				{				
					scaleChanged = true;
					currentSize = null;
				}
			}
 
			// Update scaling
			if(hasComponent(Scale))
			{
				var scale = getComponent(Scale);
				if(currentScale == null || scale.x != currentScale.x || scale.y != currentScale.y)
				{
					scaleChanged = true;
					currentScale = scale.clone();
				}
			}
			else if(currentScale != null)
			{
				scaleChanged = true;
				currentScale = null;
			}

			// Update final scaling
			if(scaleChanged)
			{
				img.scaleX = (currentScale == null ? 1 : currentScale.x) * 
					(currentSize == null ? 1 : currentSize.width / img.width); 
				img.scaleY = (currentScale == null ? 1 : currentScale.y) * 
					(currentSize == null ? 1 : currentSize.height / img.height); 
			}

			// Update origin
			if(hasComponent(Origin))
			{
				var o = getComponent(Origin);
				var ox = (o.asPercentage ? o.x * img.width : o.x);
				var oy = (o.asPercentage ? o.y * img.height : o.y);
				if(ox != img.originX || oy != img.originY || scaleChanged)
				{
					img.originX = cast ox; // HaxePunk scales origin for us
					img.originY = cast oy; // But then they shift the position too! 
					img.x = cast(img.scaleX == 1 ? ox : ox * img.scaleX); // So calculate the scaled origin
					img.y = cast(img.scaleY == 1 ? oy : oy * img.scaleY); // And move the position back
				}
			}
			else if(img.originX != 0 || img.originY != 0)
				img.originX = img.originY = 0;	

			// Update rotation
			if(hasComponent(Rotation))
			{
				var rotation = getComponent(Rotation);
				var targetAngle = -rotation.angle; // convert CW to CCW (HaxePunk's preference)
				if(img.angle != targetAngle)
					img.angle = targetAngle;
			}

			// Update alpha
			if(hasComponent(Alpha))
			{
				var alpha = getComponent(Alpha);
				if(img.alpha != alpha.value)
					img.alpha = alpha.value;
			}
		}

		// Update position
		if(hasComponent(flaxen.component.Position))
		{
			// Update offset
			// TODO Consider adding currentOffset for faster offset updating/checking
			var offsetX:Float = 0;
			var offsetY:Float = 0;
			if(hasComponent(Offset))
			{
				var o = getComponent(Offset);
				var ox = (o.asPercentage ? o.x * img.width : o.x);
				var oy = (o.asPercentage ? o.y * img.height : o.y);
				offsetX = ((img == null || img.scaleX == 1) ? ox : ox * img.scaleX);
				offsetY = ((img == null || img.scaleY == 1) ? oy : oy * img.scaleY);
			}

			if(hasComponent(Layout))
			{
				var o:Layout = cast getComponent(Layout);
				offsetX += o.current.x;
				offsetY += o.current.y;
			}

			var pos:flaxen.component.Position = cast getComponent(Position);
			var newx = pos.x + offsetX;
			var newy = pos.y + offsetY;

			if(newx != x || newy != y)
			{
				x = newx;
				y = newy;
			}
		}
	}

	/**
	 * Override to supply a custom use for the Size component instead of image scaling
	 * Only needed for Image subclasses that don't want automatic scaling from Size
	 */
	private function useSizeForImageScaling()
	{ 
		return true; 
	} 

	/**
	 * Updates the dimensions stored in the Image component
	 * Optionally calculates and updates the tilesAcross/Down in an ImageGrid component
	 */
	public function setImageDimensions(image:Image, ?imageGrid:ImageGrid)
	{
		var bitmap = com.haxepunk.HXP.getBitmap(image.path);
		#if debug
			if(bitmap == null)
				Log.error("Bitmap not found (" + image.path + ")");
		#end

		image.width = bitmap.width;
		image.height = bitmap.height;

		if(imageGrid == null)
		{
			image.clipWidth = (image.clip != null ? image.clip.width : bitmap.width);
			image.clipHeight = (image.clip != null ? image.clip.height : bitmap.height);
		}
		else
		{
			imageGrid.tilesAcross = Std.int(bitmap.width / imageGrid.tileWidth);
			imageGrid.tilesDown = Std.int(bitmap.height / imageGrid.tileHeight);
			image.clipWidth = imageGrid.tileWidth;
			image.clipHeight = imageGrid.tileHeight;

			#if debug
				// Right now there's no support for clipping and gridding.
				if(image.clip != null)
					Log.error("An image with a clip cannot have an ImageGrid");
			#end
		}
	}

	/**
	 * Override for special behavior when a view is destroyed
	 */
	public function destroy()
	{
		if(graphic != null)
			graphic.destroy();
		graphic = null;
	}
}