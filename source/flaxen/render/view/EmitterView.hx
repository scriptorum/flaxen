package flaxen.render.view;

import openfl.geom.Rectangle;

import flaxen.component.ImageGrid;
import flaxen.component.Emitter;
import flaxen.component.Rotation;
import flaxen.component.Display;

/*
 * Particle emitter display.
 */
class EmitterView extends View
{
	private static inline var FX:String = "FX";

	private var emitter:Emitter;
	private var change:Emitter; // Tests for changes
	private var display:com.haxepunk.graphics.Emitter;
	private var frameWidth:Int = 0;
	private var frameHeight:Int = 0;

	override public function begin()
	{
		type = "emitter";
		nodeUpdate();
	}

	private function setDisplay()
	{
		var displayChanged = false;
		var emitter = getComponent(Emitter);
		if(this.emitter != emitter)
		{
			this.emitter = emitter;
			if(emitter == null)
			{
				graphic = display = null;
				change = null;
				return;
			}

			change = new Emitter(emitter.particle);
			var bm = com.haxepunk.HXP.getBitmap(emitter.particle);
			var pWidth:Int = emitter.scale == null ? bm.width : cast (bm.width * emitter.scale.x);
			var pHeight:Int = emitter.scale == null ? bm.height : cast (bm.height * emitter.scale.y);
			graphic = display = new com.haxepunk.graphics.Emitter(emitter.particle, pWidth, pHeight);
	        display.newType(FX, [0]);
	        displayChanged = true;
		}

		// Check for an optional ImageGrid component
		// If found, supply frame information to the emitter
		var newFrameWidth:Int = 0;
		var newFrameHeight:Int = 0;
		if(hasComponent(ImageGrid))
		{
			var grid = getComponent(ImageGrid);
			newFrameWidth = grid.tileWidth;
			newFrameHeight = grid.tileHeight;
		}

		var lifespanChanged:Bool = false;
		if(displayChanged || 
			!Rotation.match(emitter.rotation, change.rotation) || 
			!Rotation.match(emitter.rotation, change.rotation) || 
			emitter.distance != change.distance || 
			emitter.distanceRand != change.distanceRand || 
			emitter.lifespan != change.lifespan || 
			emitter.lifespanRand != change.lifespanRand)
		{
			var angle:Int = emitter.rotation == null ? 90 : cast (-emitter.rotation.angle) % 360;
			var angleRand:Int = emitter.rotationRand == null ? 0 : cast -emitter.rotationRand.angle;
	
			// Adjust angle values so that actual angle = angle +/- angleRand
			if(angleRand != 0)
			{
				// TODO Not sure why Neko does this differently, possibly HaxePunk 1.72a bug? Figure out later.
				#if !neko
					angle -= angleRand;
				#end
				angleRand *= 2;			
			}

	        display.setMotion(FX, angle, emitter.distance, emitter.lifespan, 
	        	angleRand, emitter.distanceRand, emitter.lifespanRand, null);

			change.rotation = Rotation.safeClone(emitter.rotation);
			change.rotationRand = Rotation.safeClone(emitter.rotationRand);
			change.distance = emitter.distance;
			change.distanceRand = emitter.distanceRand;
			change.lifespan = emitter.lifespan;
			change.lifespanRand = emitter.lifespanRand;
			lifespanChanged = true;
		}

		if(displayChanged || emitter.colorStart != change.colorStart || emitter.colorEnd != change.colorEnd)
		{
	        display.setColor(FX, emitter.colorStart, emitter.colorEnd);
	        change.colorStart = emitter.colorStart;
	        change.colorEnd = emitter.colorEnd;
		}

		if(displayChanged || emitter.alphaStart != change.alphaStart || emitter.alphaEnd != change.alphaEnd)
		{
	        display.setAlpha(FX, emitter.alphaStart, emitter.alphaEnd);
	        change.alphaStart = emitter.alphaStart;
	        change.alphaEnd = emitter.alphaEnd;

		}

		if(displayChanged || emitter.gravity != change.gravity || emitter.gravityRand != change.gravityRand)
		{
	        display.setGravity(FX, emitter.gravity, emitter.gravityRand);
	        change.gravity = emitter.gravity;
	        change.gravityRand = emitter.gravityRand;
		}

		if(displayChanged || emitter.maxParticles != change.maxParticles || lifespanChanged)
		{
			emitter.particlesPerSec = emitter.maxParticles / (emitter.lifespan + emitter.lifespanRand / 2);
			var secondsPerParticle = 1/ emitter.particlesPerSec;
			if(emitter.accum < secondsPerParticle)
				emitter.accum = secondsPerParticle;
			change.maxParticles = emitter.maxParticles;
		}

		if(displayChanged || newFrameWidth != frameWidth || newFrameHeight != frameHeight)
		{
			frameWidth = newFrameWidth;
			frameHeight = newFrameHeight;
			display.setSource(emitter.particle, frameWidth, frameHeight);
		}
	}

	override public function nodeUpdate()
	{		
		if(hasComponent(Emitter))
		{				
			// Check for changes in the emitter and update the view accordingly
			setDisplay();

			if(emitter.active)
			{
				// Possibly fire more particles out
				if(display.particleCount < emitter.maxParticles)
				{
		        	emitter.elapsed += com.haxepunk.HXP.elapsed;
		        	emitter.accum += com.haxepunk.HXP.elapsed;
		        	var needed:Int = Math.floor(emitter.accum * emitter.particlesPerSec);
		        	emitter.accum -= needed / emitter.particlesPerSec;

		        	for(i in 0...needed)
		        		fire();
				}

		    	// Stop emitter if we've created enough
		    	if((emitter.stopAfterEmissions > 0 && emitter.totalEmissions >= emitter.stopAfterEmissions)
		    			|| (emitter.stopAfterSeconds > 0 && emitter.elapsed >= emitter.stopAfterSeconds))
		    	{
    				emitter.active = false;
		    	}
			}

			// Check if emitter should be marked as complete
			if(!emitter.complete)
			{
				if(emitter.waitForLifespan)
				{
					if(display.particleCount <= 0)
						emitter.complete = true;
				}
				else
				{
					if(!emitter.active)
						emitter.complete = true;
				}
			}

			// Emitter completed on previous update, check for auto-kill of component/entity
			else
			{
				if(emitter.destroyComponent)
					entity.remove(Emitter);

				else if(emitter.destroyEntity && entity.has(Display))
					entity.get(Display).destroyEntity = true;
			}
		}

		super.nodeUpdate();
	}

	public function fire()
	{
		// Emit particle within a rectangle
    	var px = emitter.position == null ? 0 : emitter.position.x;
    	var py = emitter.position == null ? 0 : emitter.position.y;

		if(emitter.emitRectRand != null)
		{
        	var ox = emitter.emitRectRand.x;
        	var oy = emitter.emitRectRand.y;
			display.emitInRectangle(FX, px + -ox / 2, py + -oy / 2, ox, oy);
		}

		// Emit particle within a radius
		else if(emitter.emitRadiusRand > 0)
			display.emitInCircle(FX, px, py, emitter.emitRadiusRand);			

		// Emit particle at a specific point
    	else display.emit(FX, px, py);

    	emitter.totalEmissions++;
	}
}