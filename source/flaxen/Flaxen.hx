package flaxen;

import ash.core.Entity;
import ash.core.Node;
import com.haxepunk.ds.Either;
import flaxen.common.Easing;
import flaxen.common.LoopType;
import flaxen.component.ActionQueue;
import flaxen.component.Alpha;
import flaxen.component.Animation;
import flaxen.component.Application;
import flaxen.component.Audio;
import flaxen.component.Dependents;
import flaxen.component.Image;
import flaxen.component.Layout;
import flaxen.component.Offset;
import flaxen.component.Position;
import flaxen.component.Sound;
import flaxen.component.Timestamp;
import flaxen.component.Transitional;
import flaxen.component.Tween;
import flaxen.ComponentSet;
import flaxen.FlaxenHandler;
import flaxen.FlaxenOptions;
import flaxen.FlaxenScene;
import flaxen.FlaxenSystem;
import flaxen.node.LayoutNode;
import flaxen.node.SoundNode;
import flaxen.node.TransitionalNode;
import flaxen.service.CameraService;
import flaxen.service.InputService;
import flaxen.system.*;

#if profiler
	import flaxen.system.ProfileSystem;
#end

/**
 * The core engine.
 *
 * Flaxen blends an entity/component system with a Haxe-based game engine, 
 * powered by HaxePunk and Ash. The core of Flaxen is built over the HaxePunk
 * engine, and maintains a reference to Ash.
 *
 * Typically you will extend this class:
 *
 * ```
 * class MyFlaxenApp extends Flaxen
 * {
 *     public static function main()
 *     {
 *         new MyFlaxenApp();
 *     }
 *
 *     override public function ready()
 *     {
 *         // Setup here...
 *         var entity:Entity = newEntity("player"); 
 *         ...
 *     }
 * }
 * ```
 *
 * But you may also instantiate it directly, with the caveat that HaxePunk 
 * is not fully initialized until Flaxen.getApp().ready returns true.
 * *(Needs to be tested)* 
 *
 * ```
 * class MyFlaxenApp
 * {
 *     public static function main()
 *     {
 * 		    var f = new Flaxen();
 * 		    f.newActionQueue()
 * 			    .waitForProperty(f.getApp(), "ready", true)
 * 			    .call(ready);
 *     }
 *
 *     public function ready()
 *     {
 *         // Setup here...
 *         var entity:Entity = newEntity("player"); 
 *         ...
 *     }
 * }
 * ```
 *
 * Flaxen responds to the following Haxe flags. These can be set with `-DflagName` or `<haxeflag name="flagName"/>`.
 * <pre>
 *     console - Includes the HaxePunk console; press ` to open; be sure to include assets/console
 *    profiler - Includes the ProfileSystem; press P to log profile stats
 * forceBuffer - Forces software buffering when using CPP targets
 * </pre>
 */
class Flaxen extends com.haxepunk.Engine
{
	public static inline var APPLICATION:String = "fApplication"; // Application mode entity
	public static inline var PROFILER:String = "fProfiler"; // Profiler entity name
	public static inline var GLOBAL_AUDIO:String = "fGlobalAudio"; // Global audio entity

	private var coreSystemId:Int = 0;
	private var userSystemId:Int = 10000;
	private var standardSystemId:Int = 20000;
	private var uniqueId:Int = 0;
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

	/**
	 * width/height -> leave 0 to match window dimensions
	 * can pass a FlaxenOptions object instead for the first parameter
	 */
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

	/**
	 * Adds a bunch of FlaxenSystems at once to the system group specified.
	 */
	public function addSystems(systems:Array<Class<FlaxenSystem>>, ?group:FlaxenSystemGroup)
	{
		if(systems == null)
			return;

		for(sys in systems)
			addSystem(Type.createInstance(sys, [this]), group);
	}

	/**
     * Systems operate in the order that they are added.
     * Early systems process first, then user systems, then standard systems.
     * Unless you have a good reason, you probably want to leave it in the user group.
     */
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

    @:dox(hide) private function nextPriority(?group:FlaxenSystemGroup): Int
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

	/**
	 * fullScaleResize();
	 */
    	// nonScalingResize();
    	fluidResize();
    }

	/**
	 * Same as the default HaxePunk resize handler
	 * The screen is stretched out to fill the stage
	 */
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
     * Creates or replaces a new layout, indexed by name.
     * If you add a Layout to an entity which also has a Position, that Position 
     * will be interpreted as relative to the Layout.
     */
	public function newLayout(name:String, portaitX:Float, portraitY:Float, 
		landscapeX:Float, landscapeY:Float): Layout
	{
		var l = new Layout(name, new Position(portaitX, portraitY), new Position(landscapeX, landscapeY));
		l.setOrientation(layoutOrientation, layoutOffset);
		return addLayout(l);
	}

	/**
	 * Registers a layout. Make sure you set Layout.current to portrait or landscape 
	 * to start.
	 */
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

    /**
     * Swaps the current layout with the alternate layout
     * Usually this is because the screen orientation has changed
     */
    public function updateLayouts(): Void
    {
    	for(node in ash.getNodeList(LayoutNode))
    		node.layout.setOrientation(layoutOrientation, layoutOffset);    		
    }

	/**
	 * Generates an automatic entity name, or parses an existing name to replace "#" with 
	 * a unique ID. The latter is useful for naming a class of entities with the same prefix.
	 * For example, "bullet#" will generate bullet0, bullet1, bullet2, etc. The ID is 
	 * guaranteed to be unique among all generated names.
	 * @param	name	An entity name (aka, "a singleton"), prefix pattern (with "#"), or null
	 * @return	The generated/parsed name
	 */
	public function generateEntityName(name:String = "_entity#"): String
	{
		return StringTools.replace(name, "#", Std.string(uniqueId++));
	}

	/**
	 * Creates a new entity and (by default) adds it to the Ash engine. If you do 
	 * not provide a name for the entity, one will be generated. You may a include
	 * "#" symbol in your name it will be replaced with a unique id. You may pass
	 * false for addToAsh to make a "free" entity, which you can add later using
	 * `addEntity`.
	 *
	 * @param	name		The name for the new entity, see `generateEntityName()`
	 * @param	addToAsh	If true, adds the new entity to the Ash engine; otherwise, returns a free entity
	 */
	public function newEntity(?name:String, addToAsh:Bool = true): Entity 
	{
		var entity:Entity = new Entity(generateEntityName(name));
		if(addToAsh)
			addEntity(entity);
		return entity;
	}    

	/**
	 * Removes all components from an entity. The entity can be a free entity.
	 * Throws exception if the string ref could not be looked up.
	 *
	 * @param	ref		An entity object, or the string name of such an object
	 * @returns	The entity emptied
	 */
	public function resetEntity(ref:EntityRef): Entity
	{
		var entity:Entity = ref.toEntity(this);
		for(component in entity.getAll())
			removeComponent(entity, Type.getClass(component));
		return entity;
	}

	/**
	 * Removes the component from the entity. This is essentially the same as Ash's `Entity.remove` method, 
	 * but it returns true/false, throws exceptions instead of returning false if compulsory is set,
	 * and can accept string names for the entity reference.
	 * Throws exception if compulsory and the component was not found in the entity, or the entity lookup failed.
	 *
	 * @param	ref			An entity object, or the string name of such an object
	 * @param	component	The component class to remove; note this is a class reference and not an instance reference
	 * @param	compulsory	If true, throws exception instead of returning false
	 * @returns	True if the component was removed, otherwise false
	 */
	public function removeComponent<T>(ref:EntityRef, component:Class<T>, compulsory:Bool = true): Bool
	{
		var entity:Entity = ref.toEntity(this, compulsory);
		if(entity == null)
			return false;
		if(entity.remove(component) == null)
		{
			if(compulsory)
				throw 'Compulsory component $component could not be removed from $entity';
			else return false;
		}
		return true;
	}

	/** 
	 * Adds the component to the entity. This is essentially the same as Ash's `Entity.add` method, 
	 * but it can accept string names for the entity reference, and tests for null components.
	 * On failure, returns null, or if compulsory throws an exception. This could be because you
	 * passed a string entity reference that failed lookup, or you supplied a null component or
	 * entity.
	 *
	 * @param	ref				An entity object, or the string name of such an object
	 * @param	component		The component instance to add
	 * @param	clazz			To force Ash to treat this component as having a different class, supply that class here (see `ash.core.Entity.add()`); defaults to null
	 * @param	compulsory		If true, throws exception instead of returning false
	 * @returns	The entity the component was added to, or null if entity could not be determined
	 */
	public function addComponent(ref:EntityRef, component:Dynamic, clazz:Class<Dynamic> = null, compulsory:Bool = true): Entity
	{
		var entity:Entity = ref.toEntity(this, compulsory);
		if(entity == null)
			return null;
		if(component == null)
		{
			if(compulsory)
				throw 'Component is null for entity $ref';
		}
		return entity.add(component, clazz);
	}

	/**
	 * Adds multiple components to an entity. 
	 * Throws exception if string entity ref lookup fails.
	 *
	 * @param	ref			An entity object, or the string name of such an object
	 * @param	components	An array of component instances
	 * @returns	The entity to which the components were added
	 */
	public function addComponents(ref:EntityRef, components:Array<Dynamic>): Entity
	{
		var entity:Entity = ref.toEntity(this);
		for(c in components)
			addComponent(entity, c);
		return entity;
	}	

	/**
	 * Returns true if the supplied entity reference is in Ash's engine. If 
	 * the ref is a string, does a lookup in Ash by name. If it's an entity,
	 * verifies the entity is not a free entity.
	 * 
	 * @param	ref		An entity object, or the string name of such an object
	 * @returns	True if the entity exists in the Ash engine, false if it's an name that can't be looked up or a free entity
	 */
	public function hasEntity(ref:EntityRef): Bool
	{
		if(ref == null)
			return false;
		return switch(ref.type)
		{
			case Left(entity): return (ash.getEntityByName(entity.name) == entity);
			case Right(str): return (ash.getEntityByName(str) != null);
		}
	}

	/**
	 * If an entity with this name exists in Ash, returns that entity.
	 * Otherwise this adds a new, empty entity to Ash with this supplied name. 
	 * Use this method when you don't know if the entity has been already 
	 * created, but if hasn't, you want to ensure it does now.
	 * Throws exception if name is invalid or null.
	 *
	 * @param	name	The name of the entity to resolve
	 * @returns	The entity found
	 */
	public function resolveEntity(name:String): Entity
	{
		if(name == null)
			throw "Cannot resolve null name";
		var e = getEntity(name, false);
		if(e != null)
			return e;
		return addEntity(new Entity(name));
	}

	/**
	 * Ensures that the named entity exists and contains the specified component.
	 * If the named entity does not exist, it is created.
	 * If the component is lacking, it is created with the parameters specified.
	 * Regardless, the component is returned. Throws an exception if the ref or component is null.
	 *
	 * @param	ref			An entity object, or the string name of an entity you want to resolve
	 * @param	component	The name of a component class to resolve
	 * @param	args		An array of arguments to be passed to the component if it needs to be constructed
	 * @returns	The resolved component 
	 */
	public function resolveComponent<T>(ref:EntityRef, component:Class<T>, ?args:Array<Dynamic>): T
	{
		if(component == null)
			throw 'Expected non-null component';

		var entity:Entity = ref.toEntity(this, false);
		if(entity == null)
			entity = resolveEntity(ref.toString());

		if(entity.has(component))
			return entity.get(component);
		
		var c = Type.createInstance(component, (args == null ? [] : args));
		entity.add(c);

		return c;
	}	


	/**
	 * Adds an free entity object to Ash. Throws an exception if the entity 
	 * is null or an entity with the same name already exists in Ash.
	 * 
	 * @param	entity		The entity object to add to Ash
	 * @returns	The same entity
	 */
	public function addEntity(entity:Entity): Entity
	{
		if(entity == null)
			throw "Cannot add null entity";
		ash.addEntity(entity);
		return entity;
	}

	/**
	 * Looks up an entity by name, and returns it. If the name could looked up, 
	 * throws an exception if compulsory, otherwise returns null.
	 *
	 * @param	ref		The string name of an entity object to look up
	 * @returns	The entity asked for, f the named entity exists in Ash, otherwise null
	 */
	public function getEntity(name:String, compulsory:Bool = true): Entity
	{
		var entity:Entity = ash.getEntityByName(name);
		if(entity == null && compulsory)
			Log.error('Compulsory entity "$name" not found');
		return entity;
	}

	/**
	 * Returns the component from an entity. The entity can be free, but if you pass the string name
	 * of an entity, it must exist in Ash. Throws exception if compulsory is true and entity name 
	 * lookup fails or component not be found
	 * 
	 * @param	ref				An entity object, or the string name of such an object
	 * @param	compulsory		Determines if an exception is thrown (true) or null is returned (false) upon any failure
	 * @return	The component requested, or null if the component could not be found
	 */
	public function getComponent<T>(ref:EntityRef, component:Class<T>, compulsory:Bool = true): T
	{
		var entity:Entity = ref.toEntity(this, compulsory);
		if(entity == null)
			return null;
		if(compulsory && !entity.has(component))
			Log.error('Compulsory component "$component" not found in "$name"');
		return entity.get(component);
	}

	/**
	 * Returns true if the entity exists and has the indicated component. If you supply
	 * a string, the named entity must exist or it will throw an exception. However, if 
	 * you supply an entity, it can be a free entity. Throws an exception if the string
	 * ref could not be looked up
	 * 
	 * @param	ref				An entity object, or the string name of such an object
	 * @param	component		The class of a component, e.g. `Position`
	 * @returns	True if the entity contains the component indicated; otherwise returns false
	 */
	public function hasComponent<T>(ref:EntityRef, component:Class<T>): Bool
	{
		return (getComponent(ref, component, false) != null);
	}

	/**
	 * Looks up an entity and removes it from Ash.
	 * @param	ref				An entity object, or the string name of such an object
	 * @param	compulsory		If true (default), throws exception if ref does not reference a known Entity in Ash
	 * @return	True if the ref was found and removed; otherwise false
	 */
	public function removeEntity(ref:EntityRef, compulsory:Bool = true): Bool
	{
		var entity:Entity = ref.toEntity(this, compulsory);
		if(entity == null)
			return false;

		ash.removeEntity(entity);
		return true;
	}

	/**
	 * Creates or replaces a new ComponentSet object, indexed by name
	 * Component sets are collections of steps that transform entities.
	 * Commonly, it is a way to add sets of components to entities.
	 * Steps can create new component instances, reuse shared components,
	 * inject components from other sets or entities, execute functions,
	 * or remove components.
	 *
	 * See ComponentSet for details.
	 * @param	name	A unique name for the set.
	 * @returns	The component set
	 */
	public function newComponentSet(name:String): ComponentSet
	{
		var set = new ComponentSet();
		sets.set(name, set);
		return set;
	}

	/**
	 * Adds a set of components to the entity. The ComponentSet is specified by name
	 * and must have been previously defined by newComponentSet().
	 */
	public function addSet(ref:EntityRef, setName:String): Entity
	{
		var entity:Entity = ref.toEntity(this, false);
		var set = getComponentSet(setName);
		if(set == null)
			Log.error("Component set not found:" + setName);
		set.install(entity);
		return entity;
	}

	/**
	 * Returns a component set.
	 */
	public function getComponentSet(name:String): ComponentSet
	{
		var set = sets.get(name);
		if(set == null)
			Log.error("ComponentSet " + name + " not found");
		return set;
	}

	/**
	 * Convenience method, creating new entity and installing component set in one
	 * If a name is not provided, a unique one will be generated using the setName as a prefix.
	 */
	public function newSetEntity(setName:String, ?entityName:String, addToAsh:Bool = true): Entity
	{
		if(entityName == null)
			entityName = '$setName#';
		var e = newEntity(entityName, addToAsh);
		return addSet(e, setName);
	}

	public function getComponentSetKeys(): Iterator<String>
	{
		return sets.keys();
	}
	
	/**
	 * Returns the number of nodes matching the supplied Node class
	 */
	public function countNodes<T:Node<T>>(?nodeClass:Class<T>): Int
	{
		var count:Int = 0;
	 	for(node in ash.getNodeList(nodeClass))
	 		count++;
	 	return count;
	}

	/**
	 * Returns an array of all entities that match the node.
	 *  If no node is provided, returns the full ash entity list.
	 */
	public function getEntities<T:Node<T>>(?nodeClass:Class<T>): Array<Entity>
	{
		var result = new Array<Entity>();

		if(nodeClass == null)
			for(e in ash.entities)
				result.push(e);

		else for(node in ash.getNodeList(nodeClass))
			result.push(node.entity);

	 	return result;
	}

	/**
	 * Returns the number of entities in the Ash system.
	 */
	public function countEntities(): Int
	{
		var count:Int = 0;
		for(entity in ash.entities)
			count++;
	 	return count;
	}	

	/**
	 * Removes all entities that match the node
	 * Returns the number removed
	 */
	public function removeEntities<T:Node<T>>(?nodeClass:Class<T>): Int
	{
		var count:Int = 0;
		var list = ash.getNodeList(nodeClass);
	 	for(node in list)
	 	{
	 		list.remove(node);
	 		count++;
	 	}
	 	return count;
	}

	/**
	 * Generates a new named marker if it doesn't exist.
	 * If a name is not given, a unique marker name is generated and returned.
	 *
	 * Markers are entities with no content, identified by a unique name.
	 * They can be used ad-hoc controls: systems can check for the existence
	 * of a marker as permission to do some behavior. Since markers are
	 * essentially just strings, you are advised to define them in constants.
	 */
	public function newMarker(?name:String): String
	{
		if(name == null)
			name = "_mark" + uniqueId++;
		resolveEntity(generateMarkerName(name));
		return name;
	}

	/**
	 * Returns true if a marker exists (see newMarker)
	 */
	public function hasMarker(name:String): Bool
	{
		var markerName = generateMarkerName(name);
		return hasEntity(markerName);
	}

	/**
	 * Removes the named marker, if it exists.
	 */
	public function removeMarker(name:String): Void
	{
		var markerName:String = generateMarkerName(name);
		removeEntity(markerName, false);
	}

	/**
	 * Internal function for generating a full entity name for a marker
	 */
	private function generateMarkerName(name:String): String
	{
		return '__marker__$name';
	}

	/**
	 * Creates and adds the second entity, making it dependent of the first entity
	 * The parent may be specified by name or by passing the Entity itself
	 * Returns the child entity
	 */
	public function newChildEntity(parentRef:EntityRef, childName:String): Entity
	{
		var childEnt = newEntity(childName);
		addDependent(parentRef, childEnt);
		return childEnt;
	}

	/**
	 * Creates a lifecycle dependency between entities. When the parent entity is 
	 * destroyed, all of its dependent children will be destroyed immediately after.
	 */
	public function addDependent(parentRef:EntityRef, childRef:EntityRef): Void
	{		
		var childEnt:Entity = childRef.toEntity(this);
		if(childEnt == null)
			Log.error("Cannot create dependency); child entity does not exist");

		var parentName:String = parentRef.toString();
		var dependents:Dependents = resolveComponent(parentName, Dependents);
		dependents.add(childEnt.name);
	}

	/**
	 * Destroys all dependents of the entity. Does not affect the entity.
	 */
	public function removeDependents(ref:EntityRef): Void
	{
		var entity:Entity = ref.toEntity(this);
		var dependents:Dependents = entity.get(Dependents);
		if(dependents == null)
			return;

		for(name in dependents.names)
			removeEntity(name, false);

		dependents.clear();
	}

	/**
	 * Callback; forces the cascade removal of dependent entities
	 */
	private function dependentsNodeRemoved(node:DependentsNode): Void
	{
		removeDependents(node.entity);
	}

	/**
	 * Returns the Application component. If it does not exist, it is created.
	 * 
	 * The application is a universal entity storing the current game mode, and 
	 * whether or not this mode has been initialized. The application entity
	 * is protected from removal when transitioning.
	 *
	 * See ModeSystem.
	 */

	public function getApp(): Application
	{
		var e = resolveEntity(APPLICATION);
		if(!e.has(Application))
		{
			e.add(new Application());
			e.add(Transitional.ALWAYS);
		}
		return e.get(Application);
	}

	/**
	 * You can add a Transitional to an entity and specify a kind in it.
	 * This is a classification. You can then use this method to remove all
	 * entities having or lacking specific kind values.
	 */
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

	/**
	 * Queues up a transition to the new mode; causes the stop handler to execute, 
	 * eliminates unprotected entities, then executes the start handler.
	 */
	public function setMode(mode:ApplicationMode): Void
	{
		var app = getApp();
		app.changeMode(mode);
	}

	/**
	 * Queues up a self-transition to the current mode; causes the stop handler to execute, 
	 * eliminates unprotected entities, then executes the start handler.
	 */
	public function restartMode(): Void
	{
		var app:Application = getApp();
		setMode(app.curMode);
	}	

	/**
	 * Adds a function that is called when an application mode is started. See setHandler.
	 */
	public function setStartCallback(callback:FlaxenCallback, ?mode:ApplicationMode): Flaxen
	{
		Log.assertNonNull(modeSystem, "ModeSystem is not available");
		modeSystem.registerStartHandler(callback, mode == null ? Default : mode);
		return this;
	}

	/**
	 * Adds a function that is called when an application mode is stopped. See setHandler
	 */
	public function setStopCallback(callback:FlaxenCallback, ?mode:ApplicationMode): Flaxen
	{
		Log.assertNonNull(modeSystem, "ModeSystem is not available");
		modeSystem.registerStopHandler(callback, mode == null ? Default : mode);
		return this;
	}

	/**
	 * Adds a function that is called regularly only during a specific application mode.
	 * Generally this is intended for handling input, but you could also use it just as
	 * an update function. See UpdateSystem for more information. Also see setHandler.
	 */
	public function setUpdateCallback(callback:FlaxenCallback, ?mode:ApplicationMode): Flaxen
	{
		Log.assertNonNull(updateSystem, "UpdateSystem is not available");
		updateSystem.registerHandler(callback, mode == null ? Default : mode);
		return this;
	}

	/** 
	 * Sets up all mode callbacks in one shot. Create a subclass of FlaxenHandler and
	 * override the functions you want. You cannot "unset" a handler once set.
	 * If a mode is not supplied, registers it as Default, which is the bootstrap mode.
	 * If Always is supplied, the handlers are run in ALL MODES, after the primary handlers
	 * run. For example: setHandler(handler1, Play); setHandler(handler2, Always); 
	 * If you setMode(Play), handler1.start will be called, followed by handler2.start.
	 */
	public function setHandler(handler:FlaxenHandler, ?mode:ApplicationMode): Flaxen
	{
		setStartCallback(handler.start, mode);
		setStopCallback(handler.stop, mode);
		setUpdateCallback(handler.update, mode);
		return this;
	}

	/*
	 * Returns the global audio object. Creates the object if it does not yet exist.
	 * Use it to set global volume, mute, or stop audio after a cutoff.
	 */
	public function getGlobalAudio(): GlobalAudio
	{
		var entity:Entity = resolveEntity(GLOBAL_AUDIO);
	
		if(!entity.has(GlobalAudio))
			entity
				.add(new GlobalAudio())
				.add(Transitional.ALWAYS);

		return entity.get(GlobalAudio);	
	}

	/** 
	 * Stops all currently playing sounds
	 */
	public function stopSounds(): Void
	{
		getGlobalAudio().stop(Timestamp.create());
	}

	/**
	 * Stops a specific sound from playing
	 */
	public function stopSound(file:String): Void
	{
		for(node in ash.getNodeList(SoundNode))
		{
			if(node.sound.file == file)
				node.sound.stop = true;
		}
	}

	/**
	 * Entity hit test, does not currently respect the Scale component
	 * nor the ScaleFactor component. Returns an object with the x/y offset
	 * of the clickpoint and image dimensions, respective to the position. Returns 
	 * null if the position does not fall within the entity.
	 *
	 * @param	ref		An entity object, or the string name of such an object
	 * @param	x		An absolute x position; in screen-space
	 * @param	y		An absolute y position; in screen-space
	 * @returns	An anonymous object {xOffset,yOffset,width,height} indicating the 
	 * 			relative position and the entity dimensions; 
	 * 			or null if x,y does not intersect with the object
	 */
	public function hitTest(ref:EntityRef, x:Float, y:Float): 
		{ xOffset:Float, yOffset:Float, width:Float, height:Float }
	{
		var entity:Entity = ref.toEntity(this, false);
		if(entity == null)
			return null;

		var pos:Position = entity.get(Position);
		var image:Image = entity.get(Image);
		if(image == null && entity.has(Animation))
			image = entity.get(Animation).image;
		if(pos == null || image == null)
			return null;

		var off:Offset = entity.get(Offset);
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

		if(x >= pos.x && x < (pos.x + image.width) &&
			y >= pos.y && y < (pos.y + image.height))
				return { xOffset:x - pos.x, yOffset:y - pos.y, width:image.width, height:image.height };
		else return null;
		
	}

	/**
	 * Given an entity with an image that represents a grid, returns the cell 
	 * coordinates being pointed at by the mouse, or null if the mouse position
	 * lies outside of the image.
	 * 
	 * @param	ref		An entity object, or the string name of such an object
	 * @param	rows	The number of rows in the grid
	 * @param	cols	The number of columns in the grid
	 * @returns	An anonymous object {x,y} indicating the cell pointed at, or null if the entity is not pointed at
	 */
	public function getMouseCell(ref:EntityRef, rows:Int, cols:Int): { x:Int, y:Int }
	{
		var entity:Entity = ref.toEntity(this, false);
		if(entity == null)
			return null;

		var result = hitTest(entity, InputService.mouseX, InputService.mouseY);
		if(result == null)
			return null;

		var cellWidth = result.width / cols;
		var cellHeight = result.height / rows;

		return { x:Std.int(Math.floor(result.xOffset / cellWidth)),
			y:Std.int(Math.floor(result.yOffset / cellHeight)) };
	}

	/**
	 * Rough button (or any item) click checker; does not handle layering or entity ordering
	 * An entity is pressed if the mouse is being clicked, the cursor is within
	 * the rectangular dimensions of the entity, and the entity has full alpha (or as specified).
	 *
	 * @param	ref			An entity object, or the string name of such an object
	 * @param	minAlpha	Ignores clicks if the Alpha of the entity is below this minimum; defaults to full alpha (off)
	 * @returns	True if the entity is being clicked on
	 */
	public function isPressed(ref:EntityRef, minAlpha:Float = 1.0): Bool
	{
		if(!InputService.clicked)
			return false;

		var entity:Entity = ref.toEntity(this, false);
		if(entity == null)
			return false;

		var alpha:Alpha = entity.get(Alpha);
		if(alpha != null && alpha.value < minAlpha)
			return false;
	 			
	 	return hitTest(entity, InputService.mouseX, InputService.mouseY) != null;
	}

	/**
	 * Creates an entity and adds the specified component to it. If name is not supplied,
	 * it will be given a wrapper prefix. By default, the entity is added to Ash.
	 * 
	 * @param	component	The component instance to wrap into an entity.
	 * @param	name		An optional name or pattern; see `newEntity` for naming
	 * @param	addToAsh	If true, adds the new entity to the Ash engine; otherwise, returns a free entity
	 * @returns	The new entity 
	 */
	public function newWrapper(component:Dynamic, ?name:String, addToAsh:Bool = true): Entity
	{
		var e = newEntity((name == null ? "_wrapper#" : name), addToAsh);
		e.add(component);
		return e;
	}

	/**
	 * Creates a new ActionQueue puts it into a new Entity. See `ActionQueue`.
	 * This entity will be destroyed when the queue completes.
	 *
	 * @param	autoStart	If true (default), the queue will run immediately
	 * @param	name		An optional name or pattern; see `newEntity` for naming
	 * @returns	An ActionQueue instance; you can find the enclosing entity with `getEntity(aq.name)`
	 */
	public function newActionQueue(autoStart:Bool = true, ?name:String): ActionQueue
	{
		var aq = new ActionQueue(this, DestroyEntity, autoStart);
		var e = newWrapper(aq, (name == null ? "_actionQueue#" : name));
		aq.name = e.name;
		return aq;
	}

	/**
	 * Creates a new Tween and puts it into a new Entity. See `Tween`.
	 * This entity will be destroyed when the tween completes.
	 *
	 * @param	source		The object/component containing the properties to tween; ex: `ent.get(Position)`
	 * @param	target		An anonymous object identifying the properties and their final values; ex. `{x:100, y:200}`
	 * @param	duration	The duration of the tween in seconds
	 * @param	easing		An optional easing function; see `Easing`; defaults to `Linear`
	 * @param	loop		An optional loop type; see `LoopType`; defaults to None
	 * @param	autoStart	If true (default), the tween will begin immediately
	 * @param	name		An optional name or pattern; see `new Entity` for naming
	 * @return	The Tween instance; you can find the enclosing entity with `getEntity(tween.name)`
	 */
	public function newTween(source:Dynamic, target:Dynamic, duration:Float, ?easing:EasingFunction, 
		?loop:LoopType, ?autoStart:Bool = true, ?name:String): Tween
	{
		var tween = new Tween(source, target, duration, easing, loop, DestroyEntity, autoStart);
		var e = newWrapper(tween, (name == null ? "_tween#" : name));
		tween.name = e.name;
		return tween;
	}

	/**
	 * Creates a new Sound and puts it into a new Entity. See Sound.
	 * This entity will be destroyed when the tween completes.
	 * 
	 * - TODO This has an inconsistent return. Modify Sound to include a name attribute, and return the Sound instance here.
	 *
	 * @param	file	The path to the sound asset; ex. "sound/beep.wav"
	 * @param	loop	If true, the sound loops continuously; defaults to false
	 * @param	volume	From 0 (mute) to 1 (default, full volume)
	 * @param	pan		From -1 (left pan) to 1 (right pan); defaults to 0 (center)
	 * @param	offset	The number of seconds from the start of the sound to skip; defaults to 0
	 * @returns	The enclosing Entity
	 */
	public function newSound(file:String, loop:Bool = false, volume:Float = 1, pan:Float = 0, 
		offset:Float = 0): Entity
	{
		var e = newEntity("sound");
		var sound = new Sound(file, loop, volume, pan, offset);
		sound.onComplete = DestroyEntity;
		e.add(sound);
		return e;
	}
}

/**
 * Node helper to filter on dependents.
 */
private class DependentsNode extends Node<DependentsNode>
{
	public var dependents:Dependents;
}

/**
 * Flaxen divides systems into three groups, which run in sequence.
 * Within any one group, systems are processed in the order they are added.
 */
enum FlaxenSystemGroup { Early; Standard; Late; }

/**
 * In many methods where an Entity is expected you can instead pass a String 
 * that is the name of an Entity in Ash. EntityRef is an abstract type that
 * could be referring to either an Entity or a String. A class may use
 * ref.toEntity() to validate the reference and return a full Entity instance.
 */
abstract EntityRef(Either<Entity, String>)
{
	public var type(get,never):Either<Entity, String>;

	private function new(e:Either<Entity, String>)
		this = e;
	
	@:to public function get_type() return this;

	@:from public static function fromEntity(e:Entity)
		return new EntityRef(Left(e));

	@:from public static function fromString(str:String)
		return new EntityRef(Right(str));

	/**
	 * @returns	The entity's name
	 */
	@:to public function toString(): String
	{
		if(this == null)
		 	return null;
		return switch(type)
		{
			case Left(entity):
				return entity.name;
			case Right(str):
				return str;
		}
	}

	/**
	 * Converts the EntityRef into an Entity. If the EntityRef already 
	 * references an Entity, does not do a lookup to verify the entity
	 * exists in the Ash engine.
	 * 
	 * @param	f			The Flaxen object
	 * @param	compulsory	If true, throws exception instead of returning null
	 * @returns	The Entity object, or null if string lookup fails or ref was null
	 */
	public function toEntity(f:Flaxen, compulsory:Bool = true): Entity
	{
		if(this == null)
		{
			if(compulsory)
				throw "Compulsory entity cannot be null";
		 	return null;
		}

		return switch(type)
		{
			case Left(entity):
				return entity;
			case Right(str):
				return f.getEntity(str, compulsory);
		}
	}
}
