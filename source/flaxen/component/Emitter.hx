/**
 * A basic particle emitter.
 *
 * - TODO: Change rotation to fireAngle and f to fireDistance
 * - TODO: Add support for reversed motion (in HP's Emitter.setMotion)
 * - TODO: Add support for easing on motion, alpha, color, etc.
 */
package flaxen.component;

import flaxen.common.Completable;
import flaxen.component.Scale;
import flaxen.component.Rotation;

class Emitter implements Completable
{   
	/** Path to particle image, cannot be changed real-time */
    public var particle:String;

	/** Duration before particle removed */
    public var lifespan:Float = 1.0;
    
    /** Adds a random amount to lifespan, from 0 to this value */
    public var lifespanRand:Float = 0.0;
    
    /** Sets the transparency of the particle at the end of its life; see `alphaStart` */
    public var alphaEnd:Float = 0.0;
    
    /** Sets the transparency of the particle at the start of its life; should match `alphaEnd` if you don't want an alpha shift */
    public var alphaStart:Float = 1.0;
    
    /** The distance to fire the particle */
    public var distance:Float = 0.0;
    
    /** Adds a random amount to distance, from 0 to this value */
    public var distanceRand:Float = 0.0;
    
    /** Applies downward velocity to all particles */
    public var gravity:Float = 0.0;
    
    /** Adds a random amount to gravity, from 0 to this value */
    public var gravityRand:Float = 0.0;
    
    /** Sets the color of the particle at the end of its life; see `colorStart` */
    public var colorEnd:Int = 0x000000;
    
    /** Sets the color of the particle when it is spawned; should match `colorEnd` if you don't want a color shift */
    public var colorStart:Int = 0xFFFFFF;

	/** Max simultaneous particles, this and lifespan determine fire rate */
    public var maxParticles:Int = 200;
	
    /** The direction the particle travels if given a distance */
    public var rotation:Rotation;
	
    /** A random amount from 0 to this is added to rotation */
    public var rotationRand:Rotation;
	
    /** Position of emission relative to emitter's position */
    public var position:{x:Float, y:Float};
	
    /** Define this for a random emission within a rectangle */
    public var emitRectRand:{x:Float, y:Float};
	
    /** Define this for a random emission within a circle */
    public var emitRadiusRand:Float = 0.0; 
	
    /** Defaults to 1,1 = no scaling of particle, cannot be changed real-time */
    public var scale:Scale;
	
    /** can set to false to stop the emitter, then later restart it */
    public var active:Bool = true;
	
    /** complete when all particles true=removed false=emitted */
    public var waitForLifespan:Bool = true;
	
    /** After all particles die, what action should we take? */
    public var onComplete:OnComplete;
	
    /** if > 0 stops emitter after creating this many particles */
    public var stopAfterEmissions:Int = 0;
	
    /** if > 0 stops emitter after this many seconds */
    public var stopAfterSeconds:Float = 0;

	/** See waitForLifespan. READ-ONLY. */
    public var complete:Bool = false;
	
    /** Number of particles emitted since emitter start. READ-ONLY. */
    public var totalEmissions:Int = 0;
	
    /** Calculated emissions rate; based on lifespan and maxParticles. READ-ONLY. */
    public var particlesPerSec:Float = 0;
	
    /** time elapsed since emitter start. READ-ONLY. */
    public var elapsed:Float = 0;
	
    /** accumulator, used internally.*/
    public var accum:Float = 0;

    public function new(particlePath:String)
    {
        this.particle = particlePath;
    }
}
