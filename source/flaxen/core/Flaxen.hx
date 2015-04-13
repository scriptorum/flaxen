/**
	FLAGS (lime test platform -DflagName):
		    console - Includes the HaxePunk console; press ` to open; be sure to include assets/console
		   profiler - Includes the ProfileSystem; press P to log profile stats
		forceBuffer - Forces software buffering when using CPP targets
*/

package flaxen.core;

import ash.core.Entity;
import ash.core.Node;
import flaxen.common.Easing;
import flaxen.component.ActionQueue;
import flaxen.component.Alpha;
import flaxen.component.Animation;
import flaxen.component.Application;
import flaxen.component.Audio;
import flaxen.component.CameraFocus;
import flaxen.component.Control;
import flaxen.component.Dependents;
import flaxen.component.Image;
import flaxen.component.Layout;
import flaxen.component.Offset;
import flaxen.component.Position;
import flaxen.component.Timestamp;
import flaxen.component.Transitional;
import flaxen.component.Tween;
import flaxen.component.Sound;
import flaxen.common.LoopType;
import flaxen.core.ComponentSet;
import flaxen.core.FlaxenHandler;
import flaxen.core.FlaxenOptions;
import flaxen.core.FlaxenScene;
import flaxen.core.FlaxenSystem;
import flaxen.node.CameraFocusNode;
import flaxen.node.LayoutNode;
import flaxen.node.SoundNode;
import flaxen.node.TransitionalNode;
import flaxen.service.CameraService;
import flaxen.service.InputService;
import flaxen.system.*;

#if profiler
	import flaxen.system.ProfileSystem;
#end

enum FlaxenSystemGroup { Early; Standard; Late; }

class Flaxen extends com.haxepunk.Engine // HaxePunk game library
{
	public static inline var DEFAULT_ENTITY:String = "fEntity"; // entity default name or prefix
	public static inline var CONTROL:String = "fControl"; // control entity name prefix
	public static inline var APPLICATION:String = "fApplication"; // Application mode entity
	public static inline var PROFILER:String = "fProfiler";
	public static inline var GLOBAL_AUDIO:String = "fGlobalAudio"; // Global audio entity

	private var coreSystemId:Int = 0;
	private var userSystemId:Int = 10000;
	private var standardSystemId:Int = 20000;
	private var nextEntityId:Int = 0;
	private var modeSystem:ModeSystem;
	private var updateSystem:UpdateSystem;
	private var layouts:Map<String, Layout>;
	private var sets:Map<String, ComponentSet>;

	public var ash:ash.core.Engine;
	public var baseWidth:Int;
	public var baseHeight:Int;
	public var layoutOrientation:Orientation;
	public var layoutOffset:Position;
	public var options:FlaxenOptions;

	// width/height -> leave 0 to match window dimensions
	// can pass a FlaxenOptions object instead for the first parameter
	public function new(?optionsOrWidth:Dynamic, ?height:Int, ?fps:Int, ?fixed:Bool, ?smoothing:Bool,
		?earlySystems:Array<Class<FlaxenSystem>>, ?lateSystems:Array<Class<FlaxenSystem>>)
	{
		if(Std.is(optionsOrWidth, FlaxenOptions))
			options = optionsOrWidth;
		else options = new FlaxenOptions(optionsOrWidth, height, fps, fixed, 
			smoothing, earlySystems, lateSystems);

		layouts = new Map<String,Layout>();
		sets = new Map<String,ComponentSet>();
		ash = new ash.core.Engine(); // Ash entity component system
		baseWidth = options.width;
		baseHeight = options.height;

		// Add support for dependent node removal
		ash.getNodeList(DependentsNode).nodeRemoved.add(dependentsNodeRemoved);

		getApp(); // Create entity with Application component

		// Prepare profile stats if requires
		#if profiler
			var stats = new ProfileStats();
			var pe = resolveEntity(PROFILER);
			pe.add(stats);
		#end

		// Add built-in entity component systems
		addSystems(options.earlySystems, Early); 
		addSystems(options.lateSystems, Late); 

		Log.assert(options.fps > 0, "FPS must be positive");
		super(options.width, options.height, options.fps, options.fixed,
			#if forceBuffer com.haxepunk.RenderMode.BUFFER #else null #end);

		com.haxepunk.HXP.screen.smoothing = options.smoothing;
	}

	override public function init()
	{
		#if console
			com.haxepunk.HXP.console.enable();
		#end

		com.haxepunk.HXP.scene = new FlaxenScene(this); // hook Ash into HaxePunk
		InputService.init();
	}	

	public function ready() { } // Override this to start your game

	// Adds a bunch of FlaxenSystems at once to the system group specified
	public function addSystems(systems:Array<Class<FlaxenSystem>>, ?group:FlaxenSystemGroup)
	{
		if(systems == null)
			return;

		for(sys in systems)
			addSystem(Type.createInstance(sys, [this]), group);
	}

	// Systems operate in the order that they are added.
	// Early systems process first, then user systems, then standard systems.
	// Unless you have a good reason, you probably want to leave it in the user group.
    public function addSystem(system:FlaxenSystem, ?group:FlaxenSystemGroup):Void
    {
    	// Default group
    	if(group == null)
    		group = Standard;

    	// Profiler start log
    	#if profiler
    		var name = Type.getClassName(Type.getClass(system));
    		ash.addSystem(new ProfileSystem(this, name, true), nextPriority(group));
    	#end

    	// Add system to ash
        ash.addSystem(system, nextPriority(group));

        // Profiler end log
    	#if profiler
    		ash.addSystem(new ProfileSystem(this, name, false), nextPriority(group));
    	#end

		// These systems need to be remembered for further configuration
    	if(Std.is(system, ModeSystem))
    		modeSystem = cast system;
    	else if(Std.is(system, UpdateSystem))
    		updateSystem = cast system;
    }

    private function nextPriority(?group:FlaxenSystemGroup): Int
    {
		return switch(group)
		{
			case Early: coreSystemId++; 
			case Standard: userSystemId++;
			case Late: standardSystemId++; 
		}
    }

    override private function resize()
    {
    	if(baseWidth == 0)
			baseWidth = com.haxepunk.HXP.stage.stageWidth;
    	if(baseHeight == 0)
			baseHeight = com.haxepunk.HXP.stage.stageHeight;

    	// fullScaleResize();
    	// nonScalingResize();
    	fluidResize();
    }

    // Same as the default HaxePunk resize handler
    // The screen is stretched out to fill the stage
    public function fullScaleResize()
    {
        super.resize();
    }

    public function nonScalingResize()
    {
        com.haxepunk.HXP.screen.scaleX = com.haxepunk.HXP.screen.scaleY = 1;
    	if(com.haxepunk.HXP.width == 0 || com.haxepunk.HXP.height == 0)
	        com.haxepunk.HXP.resize(com.haxepunk.HXP.stage.stageWidth, com.haxepunk.HXP.stage.stageHeight);
    }

    public function fluidResize()
    {
    	if(com.haxepunk.HXP.width == 0 || com.haxepunk.HXP.height == 0)
	        com.haxepunk.HXP.resize(com.haxepunk.HXP.stage.stageWidth, com.haxepunk.HXP.stage.stageHeight);

	  	com.haxepunk.HXP.windowWidth = com.haxepunk.HXP.stage.stageWidth;
        com.haxepunk.HXP.windowHeight = com.haxepunk.HXP.stage.stageHeight;

        // Determine tall or wide layout
	    layoutOrientation = (com.haxepunk.HXP.stage.stageWidth < com.haxepunk.HXP.stage.stageHeight ? Portrait : Landscape); 
	    checkScreenOrientation();

	    // Determine best-fit scaling 
	    var wScale = com.haxepunk.HXP.stage.stageWidth / baseWidth;
	    var hScale = com.haxepunk.HXP.stage.stageHeight / baseHeight;
	    var scale = Math.min(wScale, hScale);
        com.haxepunk.HXP.screen.scaleX = com.haxepunk.HXP.screen.scaleY = scale;

        // Center all layouts on screen
	    layoutOffset = new Position(0,0);
	    if(scale == hScale)
	    	layoutOffset.x = (com.haxepunk.HXP.stage.stageWidth / com.haxepunk.HXP.screen.scaleY - baseWidth) / 2;
	    else layoutOffset.y = (com.haxepunk.HXP.stage.stageHeight / com.haxepunk.HXP.screen.scaleX - baseHeight) / 2;

        updateLayouts(); // Update orientation and offset for all layouts
    }

    private function checkScreenOrientation()
    {
    	var newOrientation:Orientation = (baseWidth > baseHeight ? Landscape : Portrait);
    	if(layoutOrientation != newOrientation)
    	{
	    	var tmp = baseWidth;
	    	baseWidth = baseHeight;
	    	baseHeight = tmp;
    	}
    	com.haxepunk.HXP.resize(baseWidth, baseHeight);
    }

    /*
     * LAYOUT METHODS
     * If you add a Layout to an entity which also has a Position, that Position 
     * will be interpreted as relative to the Layout.
     */

	// Creates or replaces a new layout, indexed by name
	public function newLayout(name:String, portaitX:Float, portraitY:Float, 
		landscapeX:Float, landscapeY:Float): Layout
	{
		var l = new Layout(name, new Position(portaitX, portraitY), new Position(landscapeX, landscapeY));
		l.setOrientation(layoutOrientation, layoutOffset);
		return addLayout(l);
	}

	// Registers a layout. Make sure you set Layout.current to portrait or landscape 
	// to start.
    public function addLayout(layout:Layout): Layout
    {
	 	layouts.set (layout.name, layout);
    	return layout;
    }

    public function getLayout(name:String): Layout
    {
    	var layout:Layout = layouts.get(name);
    	if(layout == null)
    		Log.error("Layout " + name + " does not exist");
    	return layout;
    }

    // Swaps the current layout with the alternate layout
    // Usually this is because the screen orientation has changed
    public function updateLayouts(): Void
    {
    	for(node in ash.getNodeList(LayoutNode))
    		node.layout.setOrientation(layoutOrientation, layoutOffset);    		
    }

    /*
     * GENERAL ENTITY CONVENIENCE METHODS
     */

    // Constructs a new singleton entity and adds it to Ash; use this to create
    // an entity you wish to retrieve by name. You should never create a singleton
    // that ends in a number, as that might conflict with an autogenerated name.
    // If an entity with this name already exists this will Log.error( an error.
    // If addToAsh is false, the entity will not be added to Ash until you pass
    // it to addEntity(). Use this function over resolveEntity() when you want to 
    // create a singleton entity but expect no entity with this name to 
    // current exist.
	public function newSingleton(name:String, addToAsh:Bool = true): Entity 
	{
		if(name == null)
			Log.error("Singleton entity name may not be null");
		if(entityExists(name))
			Log.error("An entity with the name " + name + " already exists in Ash");
		var e:Entity = new Entity(name);
		if(addToAsh)
			addEntity(e);
		return e;
	}

	// Constructs entity and adds it to Ash; use this to create related entities.
	// Prefix is optional, if one is not supplied a default prefix is given.
    // A number will be added to the prefix to ensure its uniqueness. 
    // Like newSingleton() you can set addToAsh to false in order to skip
    // adding the entity to Ash until you call addEntity(). Provide a prefix
    // to make debugging entities easier when calling LogUtil.dumpLog().
	public function newEntity(?prefix:String, addToAsh:Bool = true): Entity 
	{
		var e:Entity = new Entity(getEntityName(prefix));
		if(addToAsh)
			addEntity(e);
		return e;
	}

	// Destroys the named singleton (if it exists) and recreates it, empty, without any components
	public function resetSingleton(name:String): Entity
	{
		removeEntity(name);
		return newSingleton(name);
	}

	// Creates and adds the second entity, making it dependent of the first entity
	// The parent may be specified by name or by passing the Entity itself
	// Returns the child entity
	public function newChildEntity(parent:Dynamic, child:String): Entity
	{
		var childEnt = newEntity(child);
		var parentEnt:Entity = (Std.is(parent, Entity) ? cast parent : demandEntity(cast parent));
		addDependent(parentEnt, childEnt);
		return childEnt;
	}

	// Creates and adds the second entity as a singleton, making it dependent of the first entity
	// The parent may be specified by name or by passing the Entity itself
	// Returns the child entity
	public function newChildSingleton(parent:Dynamic, child:String): Entity
	{
		var childEnt = newSingleton(child);
		var parentEnt:Entity = (Std.is(parent, Entity) ? cast parent : demandEntity(cast parent));
		addDependent(parentEnt, childEnt);
		return childEnt;
	}

	// Returns a unique entity name, with an optionally specified prefix
	public function getEntityName(prefix:String = DEFAULT_ENTITY,
		unique:Bool = true): String
	{
		var name:String = prefix + (unique ? Std.string(nextEntityId++) : "");
		return name;
	}

	// If an entity with this name exists in Ash, returns that entity.
	// Otherwise this creates a singleton entity with this name. Use this 
	// function over newSingleton() if you don't know if the singleton has been
	// already created, but if hasn't, want to ensure if gets created.
	// Generally this means you'll be overriding the existing components with
	// new components, which may or may be optimal.
	public function resolveEntity(name:String): Entity
	{
		var e = getEntity(name);
		if(e != null)
			return e;
		return addEntity(new Entity(name));
	}

	// Adds an entity to Ash. This will Log.error( an error if an entity with this name
	// has already been added to Ash.
	public function addEntity(entity:Entity): Entity
	{
		ash.addEntity(entity);
		// #if debug demandEntity(entity.name); #end // ensure add was successful in debug mode
		return entity;
	}

	/*
	 * GETTERS, CHECKERS, REMOVERS
	 */  

	// Returns the entity, looked up by name
	// Returns null if entity does not exist	
	public function getEntity(name:String): Entity
	{
		return name == null ? null : ash.getEntityByName(name);
	}

	// Returns the entity, looked up by name. Throws an error if demanded entity 
	// does not exist	
	// Use this when you expect and require an entity to exist in order to continue.
	public function demandEntity(name:String): Entity
	{
		var e = getEntity(name);
		if(e == null)
			Log.error("Demanded entity not found: " + name);
		return e;
	}

	// Returns true if the named entity exists in Ash, otherwise false
	public function entityExists(name:String): Bool
	{	
		return (getEntity(name) != null);
	}

	// Returns a component from a named entity, or null if entity or component not 
	// found. Specify component by class, such as Position.class. Use this over
	// entity.get() when you want to check for null once, since null.get() Log.error(s
	// an error.
	public function getComponent<T>(name:String, component:Class<T>): T
	{
		var e:Entity = getEntity(name);
		if(e == null)
			return null;
		return e.get(component);
	}

	// Same as getComponent but throws exceptions if entity or component are not found.
	public function demandComponent<T>(name:String, component:Class<T>): T
	{
		var e:Entity = demandEntity(name);
		if(!e.has(component))
			Log.error("Demanded component not found:" + component + " in entity " + name);
		return e.get(component);
	}

	// Returns true if the entity exists and it has the indicated component
	public function hasComponent<T>(name:String, component:Class<T>): Bool
	{
		return (getComponent(name, component) != null);
	}

	// Removes an entity, looked up by name
	// Returns quietly if entity is not found
	public function removeEntity(name:String): Bool
	{
		var e:Entity = getEntity(name);
		if(e != null)
		{
			ash.removeEntity(e);
			return true;			
		}
		return false;
	}

	public function demandRemoveEntity(name:String): Void
	{
		if(removeEntity(name) == false)
			Log.error("Cannot remove missing entity " + name);
	}

	/*
	 * COMPONENT SETS COVENIENCE METHODS
	 */

	// Creates or replaces a new ComponentSet object, indexed by name
	// A ComponentSet provides a way to simply add a set of components
	// to entities. See ComponentSet for details.
	public function newComponentSet(name:String): ComponentSet
	{
		var set = new ComponentSet();
		sets.set(name, set);
		return set;
	}

	// Adds a set of components to the entity. The ComponentSet is specified by name
	// and must have been previously defined by newComponentSet().
	public function addSet(entity:Entity, setName:String): Entity
	{
		var set = getComponentSet(setName);
		if(set == null)
			Log.error("Component set not found:" + setName);
		set.install(entity);
		return entity;
	}

	// Convenience method, creating new entity and installing component set in one
	public function newSetEntity(setName:String, 
		?prefix:String, addToAsh:Bool = true): Entity 
	{
		var e = newEntity(prefix, addToAsh);
		return addSet(e, setName);
	}

	// Convenience method, creating new singleton entity and installing component set in one
	public function newSetSingleton(setName:String, 
		entityName:String, addToAsh:Bool = true): Entity 
	{
		var e = newSingleton(entityName, addToAsh);
		return addSet(e, setName);
	}

	public function getComponentSet(name:String): ComponentSet
	{
		var set = sets.get(name);
		if(set == null)
			Log.error("ComponentSet " + name + " not found");
		return set;
	}

	public function getComponentSetKeys(): Iterator<String>
	{
		return sets.keys();
	}
	
	/*
	 * ENTITY STATS
	 */ 

	// Returns the number of nodes matching the supplied Node class
	public function countNodes<T:Node<T>>(?nodeClass:Class<T>): Int
	{
		var count:Int = 0;
	 	for(node in ash.getNodeList(nodeClass))
	 		count++;
	 	return count;
	}

	// Returns the number of entities in the Ash system
	public function countEntities(): Int
	{
		var count:Int = 0;
		for(entity in ash.entities)
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

	public function newMarker(markerName:String): Void
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

	public function newControl(control:Control): Entity
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
			Log.error("Cannot create dependency); child entity does not exist");
		if(parent == null)
			Log.error("Cannot create dependency; parent entity does not exist");

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
			{
				ash.removeEntity(e);
			}
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

	// Adds a function that is called when an application mode is started See setHandler.
	public function setStartCallback(callback:FlaxenCallback, ?mode:ApplicationMode): Flaxen
	{
		Log.assertNonNull(modeSystem, "ModeSystem is not available");
		modeSystem.registerStartHandler(callback, mode == null ? Default : mode);
		return this;
	}

	// Adds a function that is called when an application mode is stopped. See setHandler
	public function setStopCallback(callback:FlaxenCallback, ?mode:ApplicationMode): Flaxen
	{
		Log.assertNonNull(modeSystem, "ModeSystem is not available");
		modeSystem.registerStopHandler(callback, mode == null ? Default : mode);
		return this;
	}

	// Adds a function that is called regularly only during a specific application mode.
	// Generally this is intended for handling input, but you could also use it just as
	// an update function. See UpdateSystem for more information. Also see setHandler.
	public function setUpdateCallback(callback:FlaxenCallback, ?mode:ApplicationMode): Flaxen
	{
		Log.assertNonNull(updateSystem, "UpdateSystem is not available");
		updateSystem.registerHandler(callback, mode == null ? Default : mode);
		return this;
	}

	// Sets up all mode callbacks in one shot. Create a subclass of FlaxenHandler and
	// override the functions you want. You cannot "unset" a handler once set.
	// If a mode is not supplied, registers it as Default, which is the bootstrap mode.
	// If Always is supplied, the handlers are run in ALL MODES, after the primary handlers
	// run. For example: setHandler(handler1, Play); setHandler(handler2, Always); 
	// If you setMode(Play), handler1.start will be called, followed by handler2.start.
	public function setHandler(handler:FlaxenHandler, ?mode:ApplicationMode): Flaxen
	{
		setStartCallback(handler.start, mode);
		setStopCallback(handler.stop, mode);
		setUpdateCallback(handler.update, mode);
		return this;
	}

	/*
	 * GLOBAL AUDIO FUNCTIONS
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
		var entity:Entity = getEntity(GLOBAL_AUDIO);
		if(entity == null)
		{
			entity = new Entity(GLOBAL_AUDIO);
			entity.add(new GlobalAudio());
			entity.add(Transitional.ALWAYS);
			addEntity(entity);
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

		var pos:Position = e.get(Position);
		var image:Image = e.get(Image);
		if(image == null && e.has(Animation))
			image = e.get(Animation).image;
		if(pos == null || image == null)
			return false;

		var off:Offset = e.get(Offset);
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

		var e:Entity = getEntity(entityName);
		if(e == null)
			return false;

		var alpha:Alpha = e.get(Alpha);
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
	public function newActionQueue(name:String = null): ActionQueue
	{
		var e = (name == null ? newEntity("aq") : newSingleton(name));
		var aq = new ActionQueue();
		aq.name = e.name;
		e.add(aq);
		aq.destroyEntity = true;

		return aq;
	}

	// Creates a new Tween and adds a new Entity to hold it
	// This Entity will be destroyed when the tween completes
	public function newTween(source:Dynamic, target:Dynamic, duration:Float, 
		easing:EasingFunction = null, loop:LoopType = null, autoStart:Bool = true,
		name:String = null, parent:String = null): Tween
	{
		var e = (name == null ? newEntity("tween") : newSingleton(name));
		var tween = new Tween(source, target, duration, easing, loop, autoStart);
		tween.name = e.name;
		tween.destroyEntity = true;
		e.add(tween);

		if(parent != null)
			addDependentByName(parent, e.name);

		return tween;
	}

	// Convenience method for plays a new sound
	public function newSound(file:String, loop:Bool = false, volume:Float = 1, pan:Float = 0, 
		offset:Float = 0): Entity
	{
		var e = newEntity("sound");
		var sound = new Sound(file, loop, volume, pan, offset);
		sound.destroyEntity = true;
		e.add(sound);
		return e;
	}
}

class DependentsNode extends Node<DependentsNode>
{
	public var dependents:Dependents;
}
