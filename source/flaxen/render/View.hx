//
// I'm still not happy with the way transformation points/position points work here.
//
package flaxen.render;

import flaxen.component.Layer;
import flaxen.component.ScrollFactor;
import flaxen.component.Origin;
import flaxen.component.Scale;
import flaxen.component.Size;
import flaxen.component.Rotation;
import flaxen.component.Offset;
import flaxen.component.Position;
import flaxen.component.Alpha;
import flaxen.component.Invisible;
import flaxen.component.Layout;

import ash.core.Entity;

class View extends com.haxepunk.Entity
{
	public var entity:Entity;
	public var currentSize:Size = null;
	public var currentScale:Scale = null;

	public function new(entity:Entity)
	{
		super();

		this.entity = entity;
		begin();
		nodeUpdate();

		// trace("Created view from " + entity.name + " with position " + x + "," + y);
	}

	public function hasComponent<T>(component:Class<T>): Bool
	{
		return entity.has(component);
	}

	public function getComponent<T>(component:Class<T>): T
	{
		var instance:T = entity.get(component);
		if(instance == null)
			throw("Cannot get component " + Type.getClassName(component) + " for entity " + entity.name);
		return instance;
	}

	public function begin(): Void
	{
		// Override
	}

	// If you override this, call super
	public function nodeUpdate(): Void
	{
		if(graphic == null)
			return;

		visible = !hasComponent(Invisible);
		if(!visible)
			return;

		// For certain view subclasses
		var img:com.haxepunk.graphics.Image = Std.is(graphic, com.haxepunk.graphics.Image) ? cast graphic : null;

		// Update layer
		if(hasComponent(Layer))
		{
			var newLayer = getComponent(Layer).layer;
			if(newLayer != this.layer)
				this.layer = newLayer;
		}

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
		}

		var scaleChanged = false;
		var sizeChanged = false;
		if(img != null)
		{
			// Update specified size
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
				if(o.x != img.originX || o.y != img.originY || scaleChanged)
				{
					img.originX = cast o.x; // HaxePunk scales origin for us
					img.originY = cast o.y; // But then they shift the position too! 
					img.x = cast(img.scaleX == 1 ? o.x : o.x * img.scaleX); // So calculate the scaled origin
					img.y = cast(img.scaleY == 1 ? o.y : o.y * img.scaleY); // And move the position back
				}
			}
			else if(img.originX != 0 || img.originY != 0)
				img.originX = img.originY = 0;	

			// Update rotation
			if(hasComponent(Rotation))
			{
				var rotation = getComponent(Rotation);
				if(rotation.angle != img.angle)
					img.angle = -rotation.angle; // clockwise, thank you
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
		if(hasComponent(Position))
		{
			// Update offset
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
				var o = getComponent(Layout);
				offsetX += o.current.x;
				offsetY += o.current.y;
			}

			var pos = getComponent(Position);
			var newx = pos.x + offsetX;
			var newy = pos.y + offsetY;

			if(newx != x || newy != y)
			{
				x = newx;
				y = newy;
			}
		}
	}
}