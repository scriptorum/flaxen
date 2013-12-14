package flaxen.core;

import flaxen.core.FlaxenSystem;
import flaxen.core.Log;
import flaxen.system.*;

class FlaxenOptions
{
	public var width:Int;
	public var height:Int;
	public var fps:Int;
	public var fixed:Bool;
	public var smoothing:Bool = false;

	// Which systems to build-in by default, you can always add them later with Flaxen.addSystem
	public var earlySystems:Array<Class<FlaxenSystem>>;
	public var lateSystems:Array<Class<FlaxenSystem>>;

	// Creates a basic FlaxenOptions object
	public function new(width:Int = 0, height:Int = 0, ?fps:Int, fixed:Bool = false, 
		smoothing:Bool = false, ?earlySystems:Array<Class<FlaxenSystem>>, 
		?lateSystems:Array<Class<FlaxenSystem>>)
	{
		this.width = width;
		this.height = height;
		this.fps = (fps == null || fps == 0 ? 60 : fps);
		this.fixed = fixed;
		this.smoothing = smoothing;

		if(earlySystems == null)
			this.earlySystems = [ModeSystem, InputSystem];
		else this.earlySystems = earlySystems;

		if(lateSystems == null)
			this.lateSystems = [ActionSystem, TweeningSystem, RenderingSystem, AudioSystem];
		else this.lateSystems = lateSystems;
	}
}


