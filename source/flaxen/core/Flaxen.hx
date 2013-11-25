/*
  TODO
   	- Maybe change input system to UpdateSystem, and let people choose if they want to use it
     	for input, update, or provide their own systems
	- Change order of alignments to valign,halign? (Top,Left looks more natural than the reverse)
	- When Image.width/height is set should be set to actual width height and not based on 
	  context. This is especially true if multiple entities share the same Image.
	- Put notes in each Component as to the consequence of multiple entities sharing it.
	- Add newEntityFromSet and newSingletonFromSet
 	- Add FlaxenOptions for initializing 
*/

package flaxen.core;

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
import flaxen.core.FlaxenScene;
import flaxen.core.FlaxenHandler;
import flaxen.core.ComponentSet;
import flaxen.node.CameraFocusNode;
import flaxen.node.LayoutNode;
import flaxen.node.SoundNode;
import flaxen.node.TransitionalNode;
import flaxen.service.CameraService;
import flaxen.service.InputService;
import flaxen.system.ActionSystem;
import flaxen.system.AudioSystem;
import flaxen.system.CameraSystem;
import flaxen.system.InputSystem;
import flaxen.system.ModeSystem;
import flaxen.system.RenderingSystem;
import flaxen.system.TweeningSystem;
import ash.core.Entity;
import ash.core.Node;
import com.haxepunk.HXP;

#if PROFILER
	import flaxen.system.ProfileSystem;
	import flaxen.service.ProfileService;
#end

enum FlaxenSystemGroup { Early; Standard; Late; }

class Flaxen extends com.haxepunk.Engine // HaxePunk game library
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
	private var layouts:Map<String, Layout>;
	private var sets:Map<String, ComponentSet>;

	public var ash:ash.core.Engine;
	public var baseWidth:Int;
	public var baseHeight:Int;
	public var layoutOrientation:Orientation;
	public var layoutOffset:Position;

	// width/height -> leave 0 to match window dimensions
	public function new(width:Int = 0, height:Int = 0, fps:Int = 60) 
	{
		layouts = new Map<String,Layout>();
		sets = new Map<String,ComponentSet>();
		ash = new ash.core.Engine(); // Ash entity component system

		// Add support for dependent node removal
		ash.getNodeList(DependentsNode).nodeRemoved.add(dependentsNodeRemoved);

		getApp(); // Create entity with Application component
		addBuiltInSystems(); // initialize entity component systems

		baseWidth = width;
		baseHeight = height;

		super(width, height, fps, false,
			#if HaxePunkForceBuffer com.haxepunk.RenderMode.BUFFER #else null #end);

		// HXP.screen.smoothing = true;		
	}

	override public function init()
	{
		#if HaxePunkConsole
			HXP.console.enable();
		#end

		HXP.scene = new FlaxenScene(this); // hook Ash into HaxePunk
		InputService.init();
	}	

	public function ready() { } // Override

	private function addBuiltInSystems()
	{
		// Early Systems
		addSystem(modeSystem = new ModeSystem(this), Early);
		addSystem(inputSystem = new InputSystem(this), Early);

		// Late Systems
		addSystem(new CameraSystem(this), Late); // TODO Maybe this shouldn't be standard
		addSystem(new ActionSystem(this), Late);
		addSystem(new TweeningSystem(this), Late);
		addSystem(new RenderingSystem(this), Late);
		addSystem(new AudioSystem(this), Late);
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
			case Early: coreSystemId++; 
			case Standard: userSystemId++;
			case Late: standardSystemId++; 
		}
    }

    override private function resize()
    {
    	if(baseWidth == 0)
			baseWidth = HXP.stage.stageWidth;
    	if(baseHeight == 0)
			baseHeight = HXP.stage.stageHeight;

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

        // Determine tall or wide layout
	    layoutOrientation = (HXP.stage.stageWidth < HXP.stage.stageHeight ? Portrait : Landscape); 
	    checkScreenOrientation();

	    // Determine best-fit scaling 
	    var wScale = HXP.stage.stageWidth / baseWidth;
	    var hScale = HXP.stage.stageHeight / baseHeight;
	    var scale = Math.min(wScale, hScale);
        HXP.screen.scaleX = HXP.screen.scaleY = scale;

        // Center all layouts on screen
	    layoutOffset = new Position(0,0);
	    if(scale == hScale)
	    	layoutOffset.x = (HXP.stage.stageWidth / HXP.screen.scaleY - baseWidth) / 2;
	    else layoutOffset.y = (HXP.stage.stageHeight / HXP.screen.scaleX - baseHeight) / 2;

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
    	HXP.resize(baseWidth, baseHeight);
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
    		throw "Layout " + name + " does not exist";
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
    // If an entity with this name already exists this will throw an error.
    // If addToAsh is false, the entity will not be added to Ash until you pass
    // it to addEntity(). Use this function over resolveEntity() when you want to 
    // create a singleton entity but expect no entity with this name to 
    // current exist.
	public function newSingleton(name:String, addToAsh:Bool = true): Entity 
	{
		if(name == null)
			throw "Singleton entity name may not be null";
		if(entityExists(name))
			throw "An entity with the name " + name + " already exists in Ash";
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

	// Ensures the named singleton exists and is empty of components
	public function resetSingleton(name:String): Entity
	{
		removeEntity(name);
		return newSingleton(name);
	}

	// Returns a unique entity name, with an optionally specified prefix
	public function getEntityName(prefix:String = DEFAULT_ENTITY_NAME,
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

	// Adds an entity to Ash. This will throw an error if an entity with this name
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
			throw "Demanded entity not found: " + name;
		return e;
	}

	// Returns true if the named entity exists in Ash, otherwise false
	public function entityExists(name:String): Bool
	{	
		return (getEntity(name) != null);
	}

	// Returns a component from a named entity, or null if entity or component not 
	// found. Specify component by class, such as Position.class. Use this over
	// entity.get() when you want to check for null once, since null.get() throws
	// an error.
	public function getComponent<T>(name:String, component:Class<T>): T
	{
		var e:Entity = getEntity(name);
		if(e == null)
			return null;
		return e.get(component);
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
			throw "Cannot remove missing entity " + name;
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
	public function installComponents(entity:Entity, name:String): Entity
	{
		var set = getComponentSet(name);
		set.addToEntity(entity);
		return entity;
	}

	// Convenience method, creating new entity and installing component set in one
	public function newEntityWithSet(setName:String, 
		?prefix:String, addToAsh:Bool = true): Entity 
	{
		var e = newEntity(prefix, addToAsh);
		return installComponents(e, setName);
	}

	// Convenience method, creating new singleton entity and installing component set in one
	public function newSingletonWithSet(setName:String, 
		entityName:String, addToAsh:Bool = true): Entity 
	{
		var e = newSingleton(entityName, addToAsh);
		return installComponents(e, setName);
	}

	public function getComponentSet(name:String): ComponentSet
	{
		var set = sets.get(name);
		if(set == null)
			throw "ComponentSet " + name + " not found";
		return set;
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

	// Adds a function that is called when an application mode is started
	public function setStartHandler(callback:FlaxenCallback, ?mode:ApplicationMode): Flaxen
	{
		modeSystem.registerStartHandler(mode == null ? Always : mode, callback);
		return this;
	}

	// Adds a function that is called when an application mode is stopped
	public function setStopHandler(callback:FlaxenCallback, ?mode:ApplicationMode): Flaxen
	{
		modeSystem.registerStopHandler(mode == null ? Always : mode, callback);
		return this;
	}

	// Adds a function that is called regularly only during a specific application mode.
	// Generally this is intended for input handler, but you could also use it just as
	// an update function. Updating should properly be done by adding your own custom
	// systems.
	public function setInputHandler(callback:FlaxenCallback, ?mode:ApplicationMode): Flaxen
	{
		inputSystem.registerHandler(mode == null ? Always : mode, callback);
		return this;
	}

	// Sets up all mode handlers in one shot.
	// Create a subclass of FlaxenHandler and override the functions you want.
	public function setHandler(handler:FlaxenHandler, ?mode:ApplicationMode): Flaxen
	{
		if(mode == null)
			mode = Always;

		setStartHandler(handler.start, mode);
		setStopHandler(handler.stop, mode);
		setInputHandler(handler.input, mode);

		return this;
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
		var e = (name == null ? newEntity("aq") : newSingleton(name));
		var aq = new ActionQueue();
		aq.name = e.name;
		e.add(aq);
		aq.destroyEntity = true;

		return aq;
	}

	// Creates a new Tween and adds a new Entity to hold it
	// This Entity will be destroyed when the tween completes
	public function addTween(source:Dynamic, target:Dynamic, duration:Float, 
		easing:EasingFunction = null, autoStart:Bool = true, name:String = null, 
		parent:String = null): Tween
	{
		var e = (name == null ? newEntity("tween") : newSingleton(name));
		var tween = new Tween(source, target, duration, easing, autoStart);
		tween.name = e.name;
		tween.destroyEntity = true;
		e.add(tween);

		if(parent != null)
			addDependentByName(parent, e.name);

		return tween;
	}
}

class DependentsNode extends Node<DependentsNode>
{
	public var dependents:Dependents;
}
