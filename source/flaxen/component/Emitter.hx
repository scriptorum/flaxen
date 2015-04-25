/**
 * A basic particle emitter.
 *
 * - TODO: Change rotation to fireAngle and distance to fireDistance
 * - TODO: Add support for reversed motion (in HP's Emitter.setMotion)
 * - TODO: Add support for easing on motion, alpha, color, etc.
 */
package flaxen.component;

import flaxen.common.Completable;
import flaxen.component.Position;
import flaxen.component.Scale;
import flaxen.component.Rotation;

class Emitter implements Completable
{   
	/** Path to particle image, cannot be changed real-time */
    public var particle:String;
	/** Duration before particle removed */
    public var lifespan:Float = 1.0;
    public var lifespanRand:Float = 0.0;
    public var alphaEnd:Float = 0.0;
    public var alphaStart:Float = 1.0;
    public var distance:Float = 0.0;
    public var distanceRand:Float = 0.0;
    public var gravity:Float = 0.0;
    public var gravityRand:Float = 0.0;
    public var colorEnd:Int = 0x000000;
    public var colorStart:Int = 0xFFFFFF;
	/** Max simultaneous particles, this and lifespan determine fire rate */
    public var maxParticles:Int = 200;
	/** The direction the particle travels if given a distance */
    public var rotation:Rotation;
	/** A random amount from 0 to this is added to rotation */
    public var rotationRand:Rotation;
	/** Position of emission relative to emitter's position */
    public var position:Position;
	/** Define this for a random emission within a rectangle */
    public var emitRectRand:Position;
	/** Define this for a random emission within a circle */
    public var emitRadiusRand:Float = 0.0; 
	/** Defaults to 1,1 = no scaling of particle, cannot be changed real-time */
    public var scale:Scale;
	/** can set to false to stop the emitter, then later restart it */
    public var active:Bool = true;
	/** complete when all particles true=removed false=emitted */
    public var waitForLifespan:Bool = true;
	/** after all particles die, removes whole entity */
    public var destroyEntity:Bool = false;
	/** after all particles die, removes component */
    public var destroyComponent:Bool = false;
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
