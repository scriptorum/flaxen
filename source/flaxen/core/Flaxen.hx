package flaxen.core;

import ash.core.System;
import ash.core.Entity;
import com.haxepunk.HXP;

// import flaxen.system.InitSystem;
// import flaxen.system.InputSystem;
import flaxen.service.EntityService;
import flaxen.system.RenderingSystem;
import flaxen.system.CameraSystem;
import flaxen.system.TweeningSystem;
import flaxen.system.AudioSystem;
import flaxen.system.ActionSystem;

#if PROFILER
	import flaxen.system.ProfileSystem;
	import flaxen.service.ProfileService;
#end

class Flaxen extends com.haxepunk.Engine
{
	public var ash:ash.core.Engine;
	public var entityService:EntityService;
	
	private var nextSystemPriority:Int = 0;

	public function new()
	{
		#if FORCE_BUFFER
			super(0, 0, 60, false, com.haxepunk.RenderMode.BUFFER);
		#else
			super();
		#end
	}

	override public function init()
	{
		#if HXP_CONSOLE
			HXP.console.enable();
		#end

		this.ash = new ash.core.Engine(); // ecs
		this.entityService = new EntityService(ash);
		initSystems(); // ash systems

		HXP.scene = new FlaxenScene(this);
	}	

	private function initSystems()
	{
		// addSystem(new InitSystem(ash, factory));
		// addSystem(new InputSystem(ash, factory));
		addSystem(new ActionSystem(this));
		addSystem(new TweeningSystem(this));
		addSystem(new CameraSystem(this));
		addSystem(new RenderingSystem(this));
		addSystem(new AudioSystem(this));
	}	

    public function addSystem(system:System):Void
    {
    	#if PROFILER
    		var name = Type.getClassName(Type.getClass(system));
    		ash.addSystem(new ProfileSystem(name, true), nextSystemPriority++);
    	#end

        ash.addSystem(system, nextSystemPriority++);

    	#if PROFILER
    		ash.addSystem(new ProfileSystem(name, false), nextSystemPriority++);
    	#end
    }

    public function newEntity(name:String = null): Entity
    {
    	return addEntity(new Entity(name));
    }

    public function addEntity(e:Entity): Entity
    {
    	ash.addEntity(e);
    	return e;
    }

    override private function resize()
    {
        HXP.screen.scaleX = HXP.screen.scaleY = 1;
    	var width = (HXP.width <= 0 ? HXP.stage.stageWidth : HXP.width);
    	var height = (HXP.height <= 0 ? HXP.stage.stageHeight : HXP.height);
        HXP.resize(width, height);
    }	
}
