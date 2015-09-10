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
 *     public var f:Flaxen;
 *     public static function main()
 *     {
 * 		    f = new Flaxen();
 * 		    f.newActionQueue()
 * 			    .waitForProperty(f.getApp(), "ready", true)
 * 			    .call(ready);
 *     }
 *
 *     public function ready()
 *     {
 *         // Setup here...
 *         var entity:Entity = f.newEntity("player"); 
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
	/**
	 * Creates a new Flaxen instance. If subclassed, this should be called 
	 * by super() in your subclass constructor. Flaxen can be configured
	 * with several arguments, or by use of a `FlaxenOptions` object.
	 * You can leave width/height as 0 to have the HaxePunk buffer match
	 * the window dimensions.
	 * 
	 * @param	optionsOrWidth	Either a `FlaxenOptions` object (which invalidates the rest of the parameters) or the desired screen width
	 * @param	height			The desired screen width
	 * @param	fps				The desired frame rate, in frames-per-second; defaults to 60
	 * @param	fixed			Supply false for a variable framestep (the default), or true for a fixed framestep
	 * @param	smoothing		Supply true for pixel smoothing which is slower but smoother
	 * @param	earlySystems	Override the default early systems (`ModeSystem`)
	 * @param	lateSystems		Override the default late systems (`ActionSystem`, `TweenSystem`, `RenderingSystem`, `AudioSystem`)
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
			var pe = resolveEntity(profilerName);
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

	/**
	 * Initialization function called by HaxePunk. This is called after
	 * the HaxePunk Engine has completed initializing itself, but it has
	 * not yet initialized the Scene (which this kicks off).
	 */
	@:dox(hide) override public function init()
	{
		#if console
			com.haxepunk.HXP.console.enable();
		#end

		com.haxepunk.HXP.scene = new FlaxenScene(this); // hook Ash into HaxePunk
		InputService.init();
	}	

	/**
	 * Override this to start your game. This method is called by `FlaxenScene`
	 * when the Scene has initialized and is ready for user configuration.
	 * (That's you. You're the user.)
	 */
	public function ready()
	{
		// OVERRIDE ME!
	} 

	/**
	 * Adds a bunch of FlaxenSystems at once to the system group specified.
	 *
	 * @param	systems		An array of `FlaxenSystem` instances
	 * @param	group		The `FlaxenSystemGroup` to add these systems to, defaults to `Standard`
	 */
	public function addSystems(systems:Array<Dynamic>, ?group:FlaxenSystemGroup)
	{
		if(systems == null)
			return;

		for(sys in systems)
		{
			if(Std.is(sys, FlaxenSystem))
				addSystem(sys, group);
			else if(Std.is(sys, Class))
				addSystem(Type.createInstance(sys, [this]), group);
			else Log.error("Systems array must contain FlaxenSystem classes or instances");
		}
	}

	/**
     * Systems operate in the order that they are added to their `FlaxenSystemGroup`.
     * Early systems process first, then user systems, then standard systems.
     * Unless you have a good reason, you probably want to leave it in the Standard group.
     * You can add your own or predefined systems this way.
     * 
     * - TODO: Revisit system groups. I did it this way because I wasn't certain that
     *   Ash would process Systems with the same priority in the order they were added.
     *   If I verify this is the case, I can change this to a more robust priority model.
     *
     * @param	system	The `FlaxenSystem` to add
     * @param	group	The `FlaxenSystemGroup` to add the system to, defaults to `Standard`
     * @returns Flaxen
     */
    public function addSystem(system:FlaxenSystem, ?group:FlaxenSystemGroup): Flaxen
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

    	return this;
    }

    /**
     * Removes a system, based on Class name.
     *
     * To remove a specific system instance, use `ash.removeSystem`.
     * 
     * @param	clazz	The name of the system, e.g., `MovementSystem`
     * @returns Flaxen
     */
    public function removeSystemByClass<TSystem:ash.core.System>(clazz:Class<TSystem>): Flaxen
    {
    	ash.removeSystem(ash.getSystem(clazz));
    	return this;
    }

    /**
     * Internal priority setter. This ensures every system has a unique priority
     * in Ash. I know this isn't how priority is intended, but I like to be sure
     * that the systems are executed in an exact order.
     *
     * @param	group	The `FlaxenSystemGroup` whose priority id has changed
     * @returns The next priority
     */
    @:dox(hide) private function nextPriority(?group:FlaxenSystemGroup): Int
    {
		return switch(group)
		{
			case Early: coreSystemId++; 
			case Standard: userSystemId++;
			case Late: standardSystemId++; 
			case Custom(priority): return priority;
		}
    }

    /**
     * You can override this to supply a different resizing algorithm.
     */
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

	/**
	 * Same as the default HaxePunk resize handler
	 * The screen is stretched out to fill the stage
	 */
    public function fullScaleResize()
    {
        super.resize();
    }

    /**
     * An alternate resizing algorithm. The screen is not scaled.
     */
    public function nonScalingResize()
    {
        com.haxepunk.HXP.screen.scaleX = com.haxepunk.HXP.screen.scaleY = 1;
    	if(com.haxepunk.HXP.width == 0 || com.haxepunk.HXP.height == 0)
	        com.haxepunk.HXP.resize(com.haxepunk.HXP.stage.stageWidth, com.haxepunk.HXP.stage.stageHeight);
    }

    /**
     * Performs a *fluid resize*, which means it determines the optimal layout (tall/wide) based on the
     * screen dimensions. It applies scaling as needed to fit the application onto the stage, and
     * updates all layouts with their changed properties.
     */
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

    /**
     * Determines the `baseWidth` and `baseHeight` properties, taking into consideration
     * the effective orientation and the actual orientation. Updates HaxePunk's buffers
     * as necessary.
     */
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
     * Creates or replaces a new `Layout`, indexed by name. A layout is simply an set of offsets
     * that are applied (during rendering) to all entities that have that `Layout` component.
     * When the device orientation changes, the `RenderingSystem` chooses the offsets for the
     * mathing orientation in the Layout object.
     * 
     * In other words, if you add a Layout to an entity which also has a Position, that Position 
     * will be interpreted as relative to the Layout.
     *
     * @param	name		The name of the `Layout`
     * @param	landscapeX	The X position of the upper left corner of layout when in landscape
     * @param	landscapeY	The Y position of the upper left corner of layout when in landscape
     * @param	portraitX	The X position of the upper left corner of layout when in portrait
     * @param	portraitY	The Y position of the upper left corner of layout when in portrait
     * @returns	The `Layout` created
     */
	public function newLayout(name:String, portaitX:Float, portraitY:Float, 
		landscapeX:Float, landscapeY:Float): Layout
	{
		var l = new Layout(name, new Position(portaitX, portraitY), new Position(landscapeX, landscapeY));
		l.setOrientation(layoutOrientation, layoutOffset);
		return addLayout(l);
	}

	/**
	 * Registers a new layout. Make sure you set Layout.current to portrait or landscape 
	 * to start.
	 *
	 * @param	name	The name of the `Layout`
	 * @returns	The `Layout` object supplied, right back atcha
	 */
    public function addLayout(layout:Layout): Layout
    {
	 	layouts.set (layout.name, layout);
    	return layout;
    }

    /**
     * Returns the `Layout` defined by the supplied name, or throws an exception if it 
     * could not be found.
     *
     * @param	name	The name of the `Layout`
     * @returns	The matching Layout object
     */
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
	 * Creates a new entity and (by default) adds it to the Ash engine. 
	 * 
	 * If you do not provide a name for the entity, a unique name will be 
	 * generated. (See `ash.core.Entity.name`.) 
	 *
	 * You may a include the "#" symbol in your name and it will be replaced 
	 * with the number of entities that were previously created by this method.
	 * This pattern naming is useful for debugging; e.g., "ball#" will generate 
	 * entities named ball0, ball1, ball2, etc.
	 *
	 * You may pass false for addToAsh to make a "free" entity, which you can 
	 * add later using `addEntity`.
	 *
	 * @param	name		A name or name pattern for the new entity (optional)
	 * @param	addToAsh	If true, adds the new entity to the Ash engine; otherwise, returns a free entity
	 */
	public function newEntity(?name:String, addToAsh:Bool = true): Entity 
	{
		// Provide default name
		if(name == null)
			name = entityPrefix + "#";

		// Process # pattern
		name = StringTools.replace(name, "#", Std.string(numEntities));

		// Crete entity, and probably add it to ash
		var entity:Entity = new Entity(name);
		if(addToAsh)
			addEntity(entity);

		// increment total number of entities this method has created
		++numEntities; 

		// Return the entity instance; refer to entity.name to determine the unique name generated
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
	 * Returns true if the supplied entity reference is in Ash's engine. It
	 * does a lookup in Ash by the name supplied (if the ref is a string) or
	 * the entity's name (if the ref is an entity). This will also return false
	 * if the entity is a "free entity".
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
			Log.error("Cannot resolve null name");
		var e = getEntity(name, false);
		if(e != null)
			return e;
		return newEntity(name);
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
			Log.error("Cannot add null entity");
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
	 *
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
	 * See `ComponentSet` for details.
	 *
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
	 * Installs/adds a set of components to the entity. The `ComponentSet` is specified by name
	 * and must have been previously defined by `newComponentSet()`.
	 *
	 * @param	ref			An entity object, or the string name of such an object
	 * @param 	setName		The name of a `ComponentSet`, previously defined by `newComponentSet`.	
	 * @returns	The Entity manipulated
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
	 * Returns a component set. Throws an exception if the set cannot be found.
	 *
	 * @param 	setName		The name of a `ComponentSet`, previously defined by `newComponentSet`.	
	 * @returns	The component set found
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
	 *
	 * @param 	setName			The name of a `ComponentSet`, previously defined by `newComponentSet`.	
	 * @param 	entityName		An optional name or pattern to assign to the new entity; see `newEntity`
	 * @returns	The entity created
	 */
	public function newSetEntity(setName:String, ?entityName:String, addToAsh:Bool = true): Entity
	{
		if(entityName == null)
			entityName = '$setName#';
		var e = newEntity(entityName, addToAsh);
		return addSet(e, setName);
	}

	/**
	 * Iterates over the component set names. For debugging.
	 *
	 * @returns	A String iterator of component set names.
	 */
	public function getComponentSetKeys(): Iterator<String>
	{
		return sets.keys();
	}
	
	/**
	 * Counts the nodes that match the supplied Node class
	 *
	 * @param	nodeClass	A class that extends Node<T>, see `ash.core.Node<TNode>`
	 * @returns	The total number of entites matched by the node
	 */
	public function countNodes<T:Node<T>>(nodeClass:Class<T>): Int
	{
		var count:Int = 0;
	 	for(node in ash.getNodeList(nodeClass))
	 		count++;
	 	return count;
	}

	/**
	 * Returns an array of all entities that match the supplied node.
	 *
	 * @param	nodeClass	A class that extends Node<T>, see `ash.core.Node<TNode>`
	 * @returns	An array of all entities matched by the node
	 */
	public function getEntities<T:Node<T>>(nodeClass:Class<T>): Array<Entity>
	{
		var result = new Array<Entity>();
		for(node in ash.getNodeList(nodeClass))
			result.push(node.entity);
	 	return result;
	}

	/**
	 * When expecting exactly one node, this returns the one entity matching the supplied node.
	 *
	 * @param	nodeClass	A class that extends Node<T>, see `ash.core.Node<TNode>`
	 * @param	compulsory	If true, throws exception if no entities found or more than one found
	 * @returns	The matching entity, or any matching entity (arbtirary) if multiple match, or null if none match
	 */
	public function getOneEntity<T:Node<T>>(nodeClass:Class<T>, compulsory:Bool = true): Entity
	{
		var e:Entity = null;
		for(node in ash.getNodeList(nodeClass))
		{
			if(e != null && compulsory)
				throw 'Found more than one entity matching node $nodeClass';
			e = node.entity;
		}

		if(e == null && compulsory)
			throw 'Found no one entities matching node $nodeClass';

		return e;
	}

	/**
	 * Returns an array of ALL entities in Ash.
	 *
	 * @returns	An array of all entities.
	 */
	public function getAllEntities(): Array<Entity>
	{
		var result = new Array<Entity>();
		for(e in ash.entities)
			result.push(e);
	 	return result;
	}

	/**
	 * Counts all of the entities in the Ash system.
	 *
	 * @returns	The total number of entites in the Ash engine
	 */
	public function countEntities(): Int
	{
		var count:Int = 0;
		for(entity in ash.entities)
			count++;
	 	return count;
	}	

	/**
	 * Removes all entities that match the supplied node.
	 *
	 * @param	nodeClass	A class that extends Node<T>, see `ash.core.Node<TNode>`
	 * @return	The number of entities removed
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
	 * Generates a new named marker, if it doesn't already exist.
	 *
	 * Markers are entities with no content, identified by a unique name.
	 * They can be used ad-hoc controls: systems can check for the existence
	 * of a marker as permission to do some behavior. Since markers are
	 * essentially just strings, you are advised to define them in constants.
	 *
	 * All marker entities instances are distinguishable from other entities 
	 * because they start with a marker prefix (see `markerToEntityPrefix`).
	 *
	 * - TODO: For processing options, add a static Marker instance to these entities.
	 *
	 * @param	name	An optional marker name; if one is not supplied, a name will be generated for you
	 * @returns	The marker name; if you did not supply a name, or if your name included a #, this is the actual name generated
	 */
	public function newMarker(?name:String): String
	{
		if(name == null)
			name = markerPrefix + "#";
		var e = resolveEntity(markerToEntityPrefix + name);
		return e.name;
	}

	/**
	 * Toggles the existence of the named marker.
	 * Removes the marker if it already exists. Creates the marker if it doesn't.
	 *
	 * @param	name	The marker name
	 * @returns	True if the marker NOW exists otherwise false
	 */
	public function toggleMarker(name:String): Bool
	{
		if(hasMarker(name))
		{
			removeMarker(name);
			return false;
		}
		newMarker(name);
		return true;
	}

	/**
	 * Returns true if a marker exists. See `newMarker`.
	 *
	 * @param	name	The marker name
	 * @returns	True if the marker exists otherwise false
	 */
	public function hasMarker(name:String): Bool
	{
		return hasEntity(markerToEntityPrefix + name);
	}

	/**
	 * Removes the named marker, if it exists. See `newMarker`.
	 *
	 * @param	name	The marker name
	 */
	public function removeMarker(name:String): Void
	{
		removeEntity(markerToEntityPrefix + name, false);
	}

	/**
	 * Creates a child entity and makes it dependent on the parent entity
	 * The parent may be specified by name or by passing the Entity itself.
	 *
	 * @param	parentRef	An entity object representing the parent, or the string name of such an object
	 * @param	childName	The name of the child, or a naming pattern; see `newEntity` for naming
	 * @returns The new child entity
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
	 *
	 * @param	parentRef	An entity object representing the parent, or the string name of such an object
	 * @param	childRef	An entity object representing the dependent, or the string name of such an object
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
	 * Destroys all dependents of the entity. Does not remove the entity itself,
	 * just its dependents.
	 *
	 * @param	ref		An entity object, or the string name of such an object
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
	 * Reports the number of dependents of an entity.
	 *
	 * @param	ref		An entity object, or the string name of such an object
	 */
	public function countDependents(ref:EntityRef): Int
	{
		var entity:Entity = ref.toEntity(this);
		var dependents:Dependents = entity.get(Dependents);
		if(dependents == null)
			return 0;
		return dependents.count();
	}

	/**
	 * Callback; forces the cascade removal of dependent entities.
	 * This is an internal method.
	 */
	@:dox(hide) private function dependentsNodeRemoved(node:DependentsNode): Void
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
	 * See `ModeSystem`.
	 */
	public function getApp(): Application
	{
		var e = resolveEntity(applicationName);
		if(!e.has(Application))
		{
			e.add(new Application());
			e.add(Transitional.ALWAYS);
		}
		return e.get(Application);
	}

	/**
	 * You can add a `Transitional` to an entity and specify a kind in it.
	 * This is a classification. You can then use this method to remove all
	 * entities having or lacking specific kind values.
	 * ```
	 * var trans = new Transitional(Play, "fx");
	 * e.add(trans);
	 * removeTransitionedEntities("fx"); // remove all fx entities
	 * ```
	 *
	 * @param	matching	The name of the kind of entity you want to remove
	 * @param	excluding	The name of the kind of entity to exclude from this removal
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
	 * Queues up a transition to the new mode; causes the current mode's stop handler 
	 * to execute, eliminates unprotected entities, then executes new mode's start handler.
	 * See `ModeSystem`.
	 *
	 * @param	mode	The `ApplicationMode` to transition to
	 */
	public function setMode(mode:ApplicationMode): Void
	{
		var app = getApp();
		app.changeMode(mode);
	}

	/**
	 * Queues up a self-transition to the current mode; causes the stop handler to execute, 
	 * eliminates unprotected entities, then executes the start handler. See `setMode`.
	 */
	public function restartMode(): Void
	{
		var app:Application = getApp();
		setMode(app.curMode);
	}	

	/**
	 * Adds a function that is called when an application mode is started.
	 * Also see `setHandler`.
	 *
	 * @param	callback	A function that accepts Flaxen and returns nothing
	 * @param	mode		An optional `ApplicationMode` that determines when this callback runs
	 * @returns	The Flaxen instance
	 */
	public function setStartCallback(callback:ModeCallback, ?mode:ApplicationMode): Flaxen
	{
		Log.assertNonNull(modeSystem, "ModeSystem is not available");
		modeSystem.registerStartHandler(callback, mode == null ? Default : mode);
		return this;
	}

	/**
	 * Adds a function that is called when an application mode is stopped. 
	 * Also see `setHandler`.
	 *
	 * @param	callback	A function that accepts Flaxen and returns nothing
	 * @param	mode		An optional `ApplicationMode` that determines when this callback runs
	 * @returns	The Flaxen instance
	 */
	public function setStopCallback(callback:ModeCallback, ?mode:ApplicationMode): Flaxen
	{
		Log.assertNonNull(modeSystem, "ModeSystem is not available");
		modeSystem.registerStopHandler(callback, mode == null ? Default : mode);
		return this;
	}

	/**
	 * Adds a function that is called regularly only during a specific application mode.
	 * Generally this is intended for handling input, but you could also use it just as
	 * an update function. See UpdateSystem for more information. Also see `setHandler`.
	 *
	 * @param	callback	A function that accepts Flaxen and returns nothing
	 * @param	mode		An optional `ApplicationMode` that determines when this callback runs
	 * @returns	The Flaxen instance
	 */
	public function setUpdateCallback(callback:ModeCallback, ?mode:ApplicationMode): Flaxen
	{
		Log.assertNonNull(modeSystem, "ModeSystem is not available");
		modeSystem.registerUpdateHandler(callback, mode == null ? Default : mode);
		return this;
	}

	/** 
	 * Sets up all mode callbacks in one shot. Create a subclass of `FlaxenHandler` and
	 * override the functions you want. You cannot "unset" a handler once set.
	 * If a mode is not supplied, the mode defaults to `Default`, which is the mode
	 * that runs when the application bootstraps.
	 * If the mode is `Always`, the handlers are run in *all modes*, after the primary handlers
	 * run.
	 * See `ModeSystem`.
	 *
	 * In this example, when Play mode is entered, handler1.start() will be called, 
	 * followed by handler2.start():
	 * ```
	 * setHandler(handler1, Play); 
	 * setHandler(handler2, Always); 
	 * ```
	 *
	 * @param	handler		A `FlaxenHandler` instance, this is a class you create
	 * @param	mode		An optional `ApplicationMode` that determines when these callbacks runs
	 * @returns	The Flaxen instance
	 */
	public function setHandler(handler:FlaxenHandler, ?mode:ApplicationMode): Flaxen
	{
		Log.assertNonNull(modeSystem, "ModeSystem is not available");
		modeSystem.registerHandler(handler, (mode == null ? Default : mode));
		return this;
	}

	/**
	 * Returns the global audio object. Creates the object if it does not yet exist.
	 * Use it to set global volume, mute, or stop audio after a cutoff.
	 *
	 * @returns		The `GlobalAudio` object
	 */
	public function getGlobalAudio(): GlobalAudio
	{
		var entity:Entity = resolveEntity(globalAudioName);
	
		if(!entity.has(GlobalAudio))
			entity
				.add(new GlobalAudio())
				.add(Transitional.ALWAYS);

		return entity.get(GlobalAudio);	
	}

	/** 
	 * Stops all currently playing sounds. 
	 * Sounds are not stopped until the `AudioSystem` processes them. 
	 */
	public function stopSounds(): Void
	{
		getGlobalAudio().stop(Timestamp.create());
	}

	/**
	 * Stops all instances of a specific sound from playing, based on the path to the sound.
	 * If you want to stop a single instance, maintain a reference to the `Sound` entity (or
	 * component) and set the component's stop property to true.
	 * 
	 * @param	file	The path to the sound asset; ex. "sound/beep.wav"
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
		var e = newEntity((name == null ? wrapperPrefix + "#" : name), addToAsh);
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
		var e = newWrapper(aq, (name == null ? actionQueuePrefix + "#" : name));
		aq.name = e.name;
		return aq;
	}

	/**
	 * Creates a new Tween and puts it into a new Entity. See `Tween`.
	 * This entity will be destroyed when the tween completes. The returned tween
	 * must be configured with what to tween using `Tween.addTarget` or `Tween.to` calls. 
	 * For example, newTween(10).to(position, "x", 10);
	 *
	 * @param	duration	The duration of the tween in seconds
	 * @param	easing		An optional easing function; see `Easing`; defaults to `Linear`
	 * @param	loop		An optional loop type; see `LoopType`; defaults to None
	 * @param	autoStart	If true (default), the tween will begin immediately
	 * @param	name		An optional name or pattern; see `new Entity` for naming
	 * @return	The Tween instance; you can find the enclosing entity with `getEntity(tween.name)`
	 */
	public function newTween(duration:Float, ?easing:EasingFunction, ?loop:LoopType, 
		autoStart:Bool = true, ?name:String): Tween
	{
		var tween = new Tween(duration, easing, loop, DestroyEntity, true, name);
		var e = newWrapper(tween, (name == null ? tweenPrefix + "#" : name));
		tween.name = e.name;
		return tween;
	}

	/**
	 * Creates a new Sound and puts it into a new Entity. See Sound.
	 * This entity will be destroyed when the tween completes.
	 * 
	 * @param	file	The path to the sound asset; ex. "sound/beep.wav"
	 * @param	loop	If true, the sound loops continuously; defaults to false
	 * @param	volume	From 0 (mute) to 1 (default, full volume)
	 * @param	pan		From -1 (left pan) to 1 (right pan); defaults to 0 (center)
	 * @param	offset	The number of seconds from the start of the sound to skip; defaults to 0
	 * @param	name		An optional name or pattern; see `new Entity` for naming
	 * @returns	The soundinstance; you can find the enclosing entity with `getEntity(sound.name)`
	 */
	public function newSound(file:String, loop:Bool = false, volume:Float = 1, pan:Float = 0, 
		offset:Float = 0, ?name:String): Sound
	{
		var sound = new Sound(file, loop, volume, pan, offset, DestroyEntity, name);
		var e:Entity = newWrapper(sound, (name == null ? soundPrefix + "#" : name));
		sound.name = name;
		return sound;
	}

	/** The name of the entity holding the ProfileStats component */
	public static inline var profilerName:String = "_profiler";

	/** The name of the entity holding the GlobalAudio component */
	public static inline var globalAudioName:String = "_globalAudio";

	/** The entity name holding the Application component */
	public static inline var applicationName:String = "_application";

	/** The prefix put before marker names when converting to entity names */ 
	public static inline var markerToEntityPrefix:String = "_marker:";

	/** The prefix put before automatically named new entities */
	public static inline var entityPrefix:String = "_entity";

	/** The prefix put before automatically named wrapped entities */
	public static inline var wrapperPrefix:String = "_wrapper";

	/** The prefix put before automatically named entities holding action queues */
	public static inline var actionQueuePrefix:String = "_actionQueue";

	/** The prefix put before automatically named entities holding tweens */
	public static inline var tweenPrefix:String = "_tween";

	/** The prefix put before automatically named entities holding sounds */
	public static inline var soundPrefix:String = "_sound";

	/** The prefix put before automatically named markers */
	public static inline var markerPrefix:String = "_marker";

	@:dox(hide) private var coreSystemId:Int = -20000;
	@:dox(hide) private var userSystemId:Int = 0;
	@:dox(hide) private var standardSystemId:Int = 20000;
	@:dox(hide) private var numEntities:Int = 0; // number of entities created by `newEntity`
	@:dox(hide) private var modeSystem:ModeSystem;
	@:dox(hide) private var layouts:Map<String, Layout>;
	@:dox(hide) private var sets:Map<String, ComponentSet>;	

	/** The Ash engine; access this for direct manipulation of entities in Ash; READ-ONLY */
	public var ash:ash.core.Engine;

	/** The base screen width; READ-ONLY */
	public var baseWidth:Int;

	/** The base screen height; READ-ONLY */
	public var baseHeight:Int;

	/** The current layout orientation; READ-ONLY */
	public var layoutOrientation:Orientation;

	/** The current layout offset; READ-ONLY */
	public var layoutOffset:Position;

	/** The options Flaxen was initialized with; READ-ONLY */
	public var options:FlaxenOptions;	
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
enum FlaxenSystemGroup { Early; Standard; Late; Custom(priority:Int); }

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
	 * Returns the name of this entity. May return null if the ref is null.
	 *
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
	 * Converts the EntityRef into an Entity. If the EntityRef references 
	 * an Entity, does not do a lookup to verify the entity exists in the 
	 * Ash engine (i.e., it may be a free entity).
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
				Log.error("Compulsory entity cannot be null");
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
