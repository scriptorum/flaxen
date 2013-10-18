package flaxen.component;

import flaxen.component.Position;
import flaxen.component.Scale;
import flaxen.component.Rotation;

class Emitter
{   
    public var particle:String; // Path to particle image, cannot be changed real-time
    public var lifespan:Float = 1.0; // Duration before particle removed
    public var lifespanRand:Float = 0.0;
    public var alphaEnd:Float = 0.0;
    public var alphaStart:Float = 1.0;
    public var distance:Float = 0.0;
    public var distanceRand:Float = 0.0;
    public var gravity:Float = 0.0;
    public var gravityRand:Float = 0.0;
    public var colorEnd:Int = 0x000000;
    public var colorStart:Int = 0xFFFFFF;
    public var maxParticles:Int = 200; // Max simultaneous particles, this and lifespan determine fire rate
    public var rotation:Rotation;
    public var rotationRand:Rotation;
    public var position:Position; // Position of emission relative to emitter's position
    public var emitRectRand:Position; // Define this for a random emission within a rectangle
    public var emitRadiusRand:Float = 0.0;  // Define this for a random emission within a circle
    public var scale:Scale; // Defaults to 1,1 = no scaling of particle, cannot be changed real-time
    public var active:Bool = true; // can set to false to stop the emitter, then later restart it
    public var waitForLifespan:Bool = true; // complete when all particles true=removed false=emitted
    public var destroyEntity:Bool = false; // after all particles die, removes whole entity
    public var destroyComponent:Bool = false; // after all particles die, removes component
    public var maxEmissions:Int = 0; // if > 0 stops emitter after creating this many particles

    // Read-only properties set by the EmitterView -- generally you should not modify these
    public var complete:Bool = false; // See waitForLifespan
    public var totalEmissions:Int = 0; // Number of particles emitted since emitter start
    public var particlesPerSec:Float = 0; // Calculated emissions rate; based on lifespan and maxParticles
    public var elapsed:Float = 0; // time elapsed since emitter start

    public function new(particle:String)
    {
        this.particle = particle;
    }
}
