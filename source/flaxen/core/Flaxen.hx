/*
    TODO:
    1. Change ModeSystem to allow custom-defined behaviors when game modes are transitioned.
    2. Add transition-out-of behaviors as well.
    3. Add support for InputSystem, to make it easier to hook in inputs.
    4. Add Intents.
    5. Improve how custom systems are added to the framework.
*/

package flaxen.core;

import ash.core.System;
import ash.core.Entity;
import ash.core.Node;
import com.haxepunk.HXP;
import flaxen.component.Control;
import flaxen.component.ActionQueue;
import flaxen.component.Tween;
import flaxen.component.Dependents;
import flaxen.component.Position;
import flaxen.component.Image;
import flaxen.component.Animation;
import flaxen.component.Application;
import flaxen.component.Alpha;
import flaxen.component.Audio;
import flaxen.component.Timestamp;
import flaxen.component.Offset;
import flaxen.component.CameraFocus;
import flaxen.node.SoundNode;
import flaxen.node.TransitionalNode;
import flaxen.node.CameraFocusNode;
import flaxen.util.Easing;
import flaxen.service.InputService;
import flaxen.service.CameraService;
import flaxen.system.ModeSystem;
// import flaxen.system.InputSystem;
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
	public static inline var DEFAULT_ENTITY_NAME:String = "fEntity"; // entity default name or prefix
	public static inline var CONTROL:String = "fControl"; // control entity name prefix
	public static inline var APPLICATION:String = "fApplication"; // Application mode entity
	public static inline var GLOBAL_AUDIO_NAME:String = "fGlobalAudio"; // Global audio entity

	private var nextSystemPriority:Int = 0;
	private var nextId:Int = 0;
	private var modeSystem:ModeSystem;

	public var ash:ash.core.Engine;
	
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
		getApp(); // Create entity with Application component
		initSystems(); // initialize entity component systems
		HXP.scene = new FlaxenScene(this); // hook Ash into HaxePunk

		// #if PROFILER
		// 	ProfileService.init();
		// 	var e = new Entity("profileControl");
		// 	e.add(ProfileControl.instance);
		// 	e.add(Transitional.Always);
		// 	ash.addEntity(e);
		// #end		
	}	

	private function initSystems()
	{
		modeSystem = new ModeSystem(this);
		addSystem(modeSystem);
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

    override private function resize()
    {
        HXP.screen.scaleX = HXP.screen.scaleY = 1;
    	var width = (HXP.width <= 0 ? HXP.stage.stageWidth : HXP.width);
    	var height = (HXP.height <= 0 ? HXP.stage.stageHeight : HXP.height);
        HXP.resize(width, height);
    }

    /*
     * GENERAL ENTITY CONVENIENCE METHODS
     */

    // Constructs NEW entity, does NOT add it to Ash
    // If unique is true, a unique number will be added to the entity name to ensure its uniqueness
	public function makeEntity(name:String = DEFAULT_ENTITY_NAME, unique:Bool = true): Entity 
	{
		var name:String = name + (unique ? Std.string(nextId++) : "");
		return new Entity(name);
	}

	// Constructs NEW entity and ADDS it to Ash
	public function newEntity(?name:String, unique:Bool = true): Entity 
	{
		return add(makeEntity(name, unique));
	}

	// FINDS or MAKES a named entity and ADDS it to ASH
	// This is generally the preferred way to create an entity that will be retrieved by name
	public function resolveEntity(name:String): Entity
	{
		var e = getEntity(name);
		if(e != null)
			return e;
		return add(new Entity(name));
	}

	// ADDS an entity to Ash
	public function add(entity:Entity): Entity
	{
		ash.addEntity(entity);
		return entity;
	}

	// ADDS an entity to Ash, and adds a single component instance to the entity
	public function addSimpleEntity(component:Dynamic, ?name:String, ?unique:Bool): Entity
	{
		var e = newEntity(name, unique);
		e.add(component);
		return e;
	}

	/*
	 * GETTERS and CHECKERS
	 */  

	// Returns the entity, looks up by name
	// Returns null if entity does not exist	
	public function getEntity(name:String): Entity
	{
		return name == null ? null : ash.getEntityByName(name);
	}

	// Returns true if the named entity exists in Ash, otherwise false
	public function entityExists(name:String): Bool
	{	
		return (getEntity(name) != null);
	}

	// Returns a component from a named entity, or null if entity not found
	// Specify component by class, such as Position.class
	public function getComponent<T>(name:String, component:Class<T>): T
	{
		var e:Entity = getEntity(name);
		if(e == null)
			return null;
		return e.get(component);
	}

	/*
	 * REMOVERS
	 */

	// Removes an entity, looked up by name
	// Returns quietly if entity is not found
	public function removeEntity(name:String): Void
	{
		var e:Entity = getEntity(name);
		if(e != null)
			ash.removeEntity(e);
	}

	/*
	 * ENTITY STATS
	 */ 

	// Returns the number of nodes matching a node list
	// Supply a Node object
	public function countNodes<T:Node<T>>(nodeClass:Class<T>): Int
	{
		var count:Int = 0;
	 	for(node in ash.getNodeList(nodeClass))
	 		count++;
	 	return count;
	}

	/* 
	 * MARKER FUNCTIONS
	 * Markers are entities with no content, identified by a unique name.
	 * They can be used ad-hoc controls; systems can check for the existence
	 * of a marker as permission to do some behavior.
	 */

	// 
	public function expandMarkerName(markerName:String): String
	{
		return markerName == null ? null : markerName + "Marker";
	}

	public function hasMarker(markerName:String): Bool
	{
		var name = expandMarkerName(markerName);
		return (getEntity(name) != null);
	}

	public function addMarker(markerName:String): Void
	{
		var name = expandMarkerName(markerName);
		if(!hasMarker(name))
			resolveEntity(name);
	}

	public function removeMarker(markerName:String): Void
	{
		var name = expandMarkerName(markerName);
		var entity = getEntity(name);
		if(entity != null)
			ash.removeEntity(entity);
	}

	/*
	 * CONTROL FUNCTIONS
	 * This creates a single entity which you can add control components to.
	 * Controls are formalized markers, each control type needs a separate 
	 * subclass of Control; systems can check for the existence
	 * of a marker as permission to do some behavior. This MAY be a smidge faster
	 * than markers, but I'm not sure. I'm leaning toward removing controls, 
	 * or having them just be markers with a special suffix.
	 */

	public function addControl(control:Control): Entity
	{
		var e = resolveEntity(CONTROL);
		e.add(control);
		return e;
	}

	public function removeControl(control:Class<Control>): Entity
	{
		var e = resolveEntity(CONTROL);
		e.remove(control);
		return e;
	}

	public function hasControl(control:Class<Control>): Bool
	{
		var e = resolveEntity(CONTROL);
		return e.has(control);
	}

	/*
	 * DEPENDENCIES
	 * Add a dependency to ensure than an entity will be removed whenever
	 * its parent is removed.
	 */

	// Callback; forces the cascade removal of dependent entities
	private function dependentsNodeRemoved(node:DependentsNode): Void
	{
		removeDependents(node.entity);
	}

	// Creates a lifecycle dependency between entities. When the parent entity
	// is destroyed, all of its dependent children will also be immediately destroyed.
	public function addDependent(parent:Entity, child:Entity): Void
	{		
		if(child == null)
			throw("Cannot create dependency; child entity does not exist");
		if(parent == null)
			throw("Cannot create dependency; parent entity does not exist");

		var dependents = parent.get(Dependents);
		if(dependents == null)
		{
			dependents = new Dependents();
			parent.add(dependents);
		}

		dependents.add(child.name);
	}

	// Same as addDependent, but works with entity names
	public function addDependentByName(parentName:String, childName:String): Void
	{
		var parent = ash.getEntityByName(parentName);
		var child = ash.getEntityByName(childName);
		addDependent(parent, child);
	}

	// Destroys all dependents of the entity
	public function removeDependents(e:Entity): Void
	{
		var dependents:Dependents = e.get(Dependents);
		if(dependents == null)
			return;

		for(name in dependents.names)
		{
			var e:Entity = ash.getEntityByName(name);
			if(e != null)
				ash.removeEntity(e);
		}

		dependents.clear();
	}

	/*
	 * APPLICATION AND TRANSITION FUNCTIONS
	 */

	 // The application is a universal entity storing the current game mode, and 
	 // whether or not this mode has been initialized. The application entity
	 // is protected from removal when transitioning.
	public function getApp(): Application
	{
		var e = resolveEntity(APPLICATION);
		var app = e.get(Application);
		if(app == null)
		{
			app = new Application();
			e.add(app);
			e.add(Transitional.ALWAYS);
		}
		return app;
	}

	// Transitions to another mode
	public function transitionTo(mode:ApplicationMode): Void
	{
		// Remove all entities, excepting those marked as transitional for this mode
		for(e in ash.entities)
		{
			if(e.has(Transitional))
			{
				var transitional:Transitional = e.get(Transitional);
				if(transitional.isProtected(mode))
				{
					if(transitional.destroyComponent)
						e.remove(Transitional);
					else 
						transitional.complete = true;					
					continue;
				}
			}

			ash.removeEntity(e);
		}
	}

	public function removeTransitionedEntities(matching:String = null, excluding:String = null)
	{
		for(node in ash.getNodeList(TransitionalNode))
		{
			if(node.transitional.isCompleted()) // should spare Always transitionals from removal
			{
				if(matching != null && matching != node.transitional.kind)
					continue;
				if(excluding != null && excluding == node.transitional.kind)
					continue;

				ash.removeEntity(node.entity);				
			}
		}
	}

	public function restartApplicationMode(): Void
	{
		var app:Application = getApp();
		app.nextMode = app.currentMode;
		app.currentMode = null;
	}	

	// Adds a function that is called when an application mode is started
	// For example, this will log some text to console at game start:
	// 		setModeStartHandler(Init, function(_) { trace("Hi"); });
	public function setStartHandler(mode:ApplicationMode, handler:ModeHandler): Void
	{
		modeSystem.registerStartHandler(mode, handler);
	}

	// Adds a function that is called when an application mode is stopped
	// This happens before the unprotected entities are removed.
	public function setStopHandler(mode:ApplicationMode, handler:ModeHandler): Void
	{
		modeSystem.registerStopHandler(mode, handler);
	}

	/*
	 * AUDIO FUNCTIONS
	 */

	// Stops all currently playing sounds
	public function stopSounds(): Void
	{
		var globalAudio:GlobalAudio = getGlobalAudio();
		globalAudio.stop(Timestamp.create());
	}

	// Return/create global audio object; use to set global volume, mute, 
	// or stop audio after a cutoff
	public function getGlobalAudio(): GlobalAudio
	{
		var entity:Entity = getEntity(GLOBAL_AUDIO_NAME);
		if(entity == null)
		{
			entity = new Entity(GLOBAL_AUDIO_NAME);
			entity.add(new GlobalAudio());
			entity.add(Transitional.ALWAYS);
			add(entity);
		}
		return entity.get(GlobalAudio);
	}

	// Stops a specific sound from playing
	public function stopSound(file:String): Void
	{
		for(node in ash.getNodeList(SoundNode))
		{
			if(node.sound.file == file)
				node.sound.stop = true;
		}
	}

	/*
	 * GUI FUNCTIONS
	 * Move to InputService?
	 */

	// Entity hit test, does not currently respect the Scale component
	// nor the ScaleFactor component.
	public function hitTest(e:Entity, x:Float, y:Float): Bool
	{
		if(e == null)
			return false;

		var pos = e.get(Position);
		var image = e.get(Image);
		if(image == null && e.has(Animation))
			image = e.get(Animation).image;
		if(pos == null || image == null)
			return false;

		var off = e.get(Offset);
		if(off != null)
		{
			if(off.asPercentage)
			{
				x -= off.x * image.width;
				y -= off.y * image.height;
			}
			else
			{
				x -= off.x;
				y -= off.y;
			}
		}

		return(x >= pos.x && x < (pos.x + image.width) && 
			y >= pos.y && y < (pos.y + image.height));
	}

	// Rough button (or any item) click checker; does not handle layering or entity ordering
	// An entity is pressed if the mouse is being clicked, the cursor is within
	// the dimensions of the entity, and the entity has full alpha (or as specified).
	public function isPressed(entityName:String, minAlpha:Float = 1.0): Bool
	{
		if(!InputService.clicked)
			return false;

		var e = getEntity(entityName);
		if(e == null)
			return false;

		var alpha = e.get(Alpha);
		if(alpha != null && alpha.value < minAlpha)
			return false;
	 			
	 	return hitTest(e, InputService.mouseX, InputService.mouseY);
	}	

	// MOVE TO CameraService
	public function changeCameraFocus(entity:Entity): Void
	{
		for(node in ash.getNodeList(CameraFocusNode))
			node.entity.remove(CameraFocus);

		if(entity != null)
			entity.add(CameraFocus.instance);			
	}	

	/*
	 * COMMON COMPONENT SHORTCUTS
	 */

	// Creates a new ActionQueue and a new Entity to hold it
	// The Entity will be destroyed when the queue completes
	public function addActionQueue(name:String = null): ActionQueue
	{
		var e = makeEntity("aq");
		if(name != null)
			e.name = name;

		var aq = new ActionQueue();
		e.add(aq);
		aq.destroyEntity = true;
		add(e);
		aq.name = e.name;

		return aq;
	}

	// Creates a new Tween and adds a new Entity to hold it
	// The Entity will be destroyed when the tween completes
	public function addTween(source:Dynamic, target:Dynamic, duration:Float, 
		easing:EasingFunction = null, autoStart:Bool = true, name:String = null, 
		parent:String = null): Tween
	{
		var e = makeEntity("tween");
		if(name != null)
			e.name = name;

		var tween = new Tween(source, target, duration, easing, autoStart);
		tween.destroyEntity = true;
		e.add(tween);
		add(e);
		tween.name = e.name;

		if(parent != null)
			addDependentByName(parent, e.name);

		return tween;
	}
}

class DependentsNode extends Node<DependentsNode>
{
	public var dependents:Dependents;
}
