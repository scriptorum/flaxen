package flaxen.core;

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
import flaxen.component.Transitional;
import flaxen.component.Alpha;
import flaxen.component.Audio;
import flaxen.component.Timestamp;
import flaxen.component.Offset;
import flaxen.component.CameraFocus;
import flaxen.component.Layout;
import flaxen.node.SoundNode;
import flaxen.node.TransitionalNode;
import flaxen.node.CameraFocusNode;
import flaxen.node.LayoutNode;
import flaxen.util.Easing;
import flaxen.service.InputService;
import flaxen.service.CameraService;
import flaxen.system.ModeSystem;
import flaxen.system.InputSystem;
import flaxen.system.RenderingSystem;
import flaxen.system.CameraSystem;
import flaxen.system.TweeningSystem;
import flaxen.system.AudioSystem;
import flaxen.system.ActionSystem;

#if PROFILER
	import flaxen.system.ProfileSystem;
	import flaxen.service.ProfileService;
#end

enum FlaxenSystemGroup { Core; User; Standard; }
typedef FlaxenHandler = Flaxen -> Void;

class Flaxen extends com.haxepunk.Engine
{
	public static inline var DEFAULT_ENTITY_NAME:String = "fEntity"; // entity default name or prefix
	public static inline var CONTROL:String = "fControl"; // control entity name prefix
	public static inline var APPLICATION:String = "fApplication"; // Application mode entity
	public static inline var GLOBAL_AUDIO_NAME:String = "fGlobalAudio"; // Global audio entity

	private var coreSystemId:Int = 0;
	private var userSystemId:Int = 10000;
	private var standardSystemId:Int = 20000;
	private var nextEntityId:Int = 0;
	private var modeSystem:ModeSystem;
	private var inputSystem:InputSystem;
	private var layouts:Map<String,Layout>;
	private var layoutAsPortait:Bool = false;

	public var ash:ash.core.Engine;
	public var startWidth:Int;
	public var startHeight:Int;

	public function new(width:Int = 0, height:Int = 0) // leave 0 to match window dimensions
	{
		this.layouts = new Map<String,Layout>();
		this.ash = new ash.core.Engine(); // ecs
		getApp(); // Create entity with Application component
		addBuiltInSystems(); // initialize entity component systems

		startWidth = width;
		startHeight = height;

		super(width, height, 60, false,
			#if FORCE_BUFFER com.haxepunk.RenderMode.BUFFER #else null #end);
	}

	override public function init()
	{
		#if HXP_CONSOLE
			HXP.console.enable();
		#end

		HXP.scene = new FlaxenScene(this); // hook Ash into HaxePunk
	}	

	public function ready() { } // Override

	private function addBuiltInSystems()
	{
		// Core Systems
		addSystem(modeSystem = new ModeSystem(this), Core);
		addSystem(inputSystem = new InputSystem(this), Core);

		// Standard Systems
		addSystem(new CameraSystem(this), Standard); // TODO Maybe this shouldn't be standard
		addSystem(new ActionSystem(this), Standard);
		addSystem(new TweeningSystem(this), Standard);
		addSystem(new RenderingSystem(this), Standard);
		addSystem(new AudioSystem(this), Standard);
	}

	// Systems operate in the order that they are added.
	// Core systems process first, then user systems, then standard systems.
	// Unless you have a good reason, you probably want to leave it in the user group.
    public function addSystem(system:FlaxenSystem, ?group:FlaxenSystemGroup):Void
    {
    	// Default group
    	if(group == null)
    		group = User;

    	// Profiler start log
    	#if PROFILER
    		var name = Type.getClassName(Type.getClass(system));
    		ash.addSystem(new ProfileSystem(name, true), nextPriority(group));
    	#end

    	// Add system to ash
        ash.addSystem(system, nextPriority(group));

        // Profiler end log
    	#if PROFILER
    		ash.addSystem(new ProfileSystem(name, false), nextPriority(group));
    	#end
    }

    private function nextPriority(?group:FlaxenSystemGroup): Int
    {
		return switch(group)
		{
			case Core: coreSystemId++; 
			case User: userSystemId++;
			case Standard: standardSystemId++; 
		}
    }

    override private function resize()
    {
    	if(startWidth == 0)
			startWidth = HXP.stage.stageWidth;
    	if(startHeight == 0)
			startHeight = HXP.stage.stageHeight;

    	// fullScaleResize();
    	// nonScalingResize();
    	fluidResize();
    }

    // Same as the default HaxePunk resize handler
    // The screen is stretched out to fill the stage
    public function fullScaleResize()
    {
        if (HXP.width == 0) HXP.width = HXP.stage.stageWidth;
        if (HXP.height == 0) HXP.height = HXP.stage.stageHeight;
        HXP.windowWidth = HXP.stage.stageWidth;
        HXP.windowHeight = HXP.stage.stageHeight;
        HXP.screen.scaleX = HXP.stage.stageWidth / HXP.width;
        HXP.screen.scaleY = HXP.stage.stageHeight / HXP.height;
        HXP.resize(HXP.stage.stageWidth, HXP.stage.stageHeight);
    }

    public function nonScalingResize()
    {
        HXP.screen.scaleX = HXP.screen.scaleY = 1;
    	if(HXP.width == 0 || HXP.height == 0)
	        HXP.resize(HXP.stage.stageWidth, HXP.stage.stageHeight);
    }

    public function fluidResize()
    {
    	if(HXP.width == 0 || HXP.height == 0)
	        HXP.resize(HXP.stage.stageWidth, HXP.stage.stageHeight);
	  	HXP.windowWidth = HXP.stage.stageWidth;
        HXP.windowHeight = HXP.stage.stageHeight;

	    // Determine best scaling maintaining aspect ratio
	    var hdiff = Math.abs(HXP.stage.stageWidth - startWidth);
	    var vdiff = Math.abs(HXP.stage.stageHeight - startHeight);
	    var offset = new Position(0,0);
	    var isPortrait:Bool;
	    if(vdiff < hdiff) 
	    {
	        HXP.screen.scaleX = 1;
	        HXP.screen.scaleY = HXP.stage.stageHeight / startHeight;
	    	offset.x = (HXP.stage.stageHeight - (HXP.screen.scale * startHeight)) / 2;
	    	isPortrait = false;
	    }
	    else
	    {
	        HXP.screen.scaleX = HXP.stage.stageWidth / startWidth;
	        HXP.screen.scaleY = 1;
	    	offset.y = (HXP.stage.stageWidth - (HXP.screen.scale * startWidth)) / 2;
	    	isPortrait = true;
	    }

	    trace("Offset:" + offset.x + "," + offset.y);

        // Determine master offset
        setLayoutOrientation(isPortrait); // Change orientation of all layouts
    }

    /*
     * LAYOUT METHODS
     * If you add a Layout to an entity which also has a Position, that Position 
     * will be interpreted as relative to the Layout.
     */

	public function newLayout(name:String, portaitX:Float, portraitY:Float, 
		landscapeX:Float, landscapeY:Float): Layout
	{
		var l = new Layout(name, new Position(portaitX, portraitY), new Position(landscapeX, landscapeY));
		trace("Creating new layout " + name + ", screen dim:" + HXP.width + "x" + HXP.height);
		l.setOrientation(HXP.height >= HXP.width);
		return addLayout(l);
	}

	// Registers a new layout. Make sure you set Layout.current to portrait or landscape to start.
    public function addLayout(layout:Layout): Layout
    {
    	if(layouts.get(layout.name) != null)
    		throw "Layout " + layout.name + " already exists";
	 	layouts.set (layout.name, layout);
    	return layout;
    }

    public function getLayout(name:String): Layout
    {
    	var layout:Layout = layouts.get(name);
    	if(layout == null)
    		throw "Layout " + name + " does not exist";
    	return layout;
    }

    // Swaps the current layout with the alternate layout
    // Usually this is because the screen orientation has changed
    public function setLayoutOrientation(portraitOrientation:Bool): Void
    {
    	for(node in ash.getNodeList(LayoutNode))
    		node.layout.setOrientation(portraitOrientation);
    }

    /*
     * GENERAL ENTITY CONVENIENCE METHODS
     */

    // Constructs NEW entity, does NOT add it to Ash
    // If unique is true, a unique number will be added to the entity name to ensure its uniqueness
	public function makeEntity(name:String = DEFAULT_ENTITY_NAME, unique:Bool = true): Entity 
	{
		var name:String = name + (unique ? Std.string(nextEntityId++) : "");
		return new Entity(name);
	}

	// Constructs NEW entity and ADDS it to Ash
    // If unique is true, a unique number will be added to the entity name to ensure its uniqueness
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
		// #if debug demandEntity(entity.name); #end // ensure add was successful in debug mode
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

	// Returns the entity, looked up by name
	// Returns null if entity does not exist	
	public function getEntity(name:String): Entity
	{
		return name == null ? null : ash.getEntityByName(name);
	}

	// Returns the entity, looked up by name
	// Throws an error if demanded entity does not exist	
	public function demandEntity(name:String): Entity
	{
		var e = getEntity(name);
		if(e == null)
			throw "Demanded entity not found: " + name;
		return e;
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
	 * You can split the application into different modes. The app starts in Default mode.
	 * Register handlers to be called when transitioning from (stop) or transitioning to
	 * (start) a mode. Register an input handler for a mode here as well. There can be
	 * only one start/stop/input handler per mode, but you can also specify the virtual 
	 * mode Always (or null). The Always handler will be called (always) in every mode, 
	 * after the mode-specific handler is called.
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

	// TODO I like this idea, but I don't like how it's implmented.
	// You can add a Transitional to an entity and specify a kind in it.
	// This is a classification. You can then use this method to remove all
	// entities having or lacking specific kind values.
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

	// Queues up a transition to the new mode; causes the stop handler to execute, 
	// eliminates unprotected entities, then executes the start handler.
	public function setMode(mode:ApplicationMode): Void
	{
		var app = getApp();
		app.changeMode(mode);
	}

	// Queues up a self-transition to the current mode; causes the stop handler to execute, 
	// eliminates unprotected entities, then executes the start handler.
	public function restartMode(): Void
	{
		var app:Application = getApp();
		setMode(app.curMode);
	}	

	// Adds a function that is called when an application mode is started
	// For example, this will log some text to console at game start:
	// 		setStartHandler(function(f:Flaxen) { f.newEntity().add(Image("art/img.png")); });
	public function setStartHandler(handler:FlaxenHandler, ?mode:ApplicationMode): Void
	{
		modeSystem.registerStartHandler(mode == null ? Always : mode, handler);
	}

	// Adds a function that is called when an application mode is stopped
	// This happens before the unprotected entities are removed.
	// 		setStopHandler(function(_) { trace("Removed"); }, Play);
	public function setStopHandler(handler:FlaxenHandler, ?mode:ApplicationMode): Void
	{
		modeSystem.registerStopHandler(mode == null ? Always : mode, handler);
	}

	// Adds a function that is called regularly only during a specific application mode.
	// This function should check user inputs and respond appropriately.
	// 		setInputHandler(function(_) { if(InputSerice.clicked) /* respond */; }, User("MyMode"));
	public function setInputHandler(handler:FlaxenHandler, ?mode:ApplicationMode): Void
	{
		inputSystem.registerHandler(mode == null ? Always : mode, handler);
	}

	// TODO Rename FlaxenHandler to FlaxenFunc or SimpleFunc
	// Sets up all mode handlers in one shot.
	// Create a subclass of FlaxenHandler and override the functions you want.
	// public function setHandler(handlerObj:FlaxenHandler, ?mode:ApplicationMode): Void
	// {
	// 	if(mode == null)
	// 		mode = Always;
	// 	setStartHandler(handlerObj.start, mode);
	// 	setStopHandler(handlerObj.start, mode);
	// 	setInputHandler(handlerObj.start, mode);
	// }

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

	// MOVE TO CameraService?
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
	// This Entity will be destroyed when the queue completes
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
	// This Entity will be destroyed when the tween completes
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
