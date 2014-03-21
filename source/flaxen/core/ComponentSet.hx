/**
	A ComponentSet is a list of steps that can be added (installed) into an entity 
	(or ideally more). Most steps are for adding instances of components. This is its 
	primary function, to quickly add components to an entity. Steps can also be used
	to remove components from entities, or execute arbitrary functions that may or may
	not return the instance to be added.

	This set adds some base components to two different entities, and ensures neither
	entity contains an Animation:

	flaxen.newComponentSet("base")
		.add(Origin.center)
		.add(new Offset(10, 10))
		.addClass(Position, [0, 0])
		.remove(Animation);
	flaxen.addSet(entity1, "base");
	flaxen.addSet(entity2, "base");
*/
package flaxen.core;

import ash.core.Entity;

class ComponentSet
{
	private var steps:Array<Dynamic>;

	public function new()
	{
		steps = new Array<Dynamic>();
	}

	// Adds a component instance to the component set. Note that all entities using this set
	// will be sharing the same single instance of this component. See addClass.
	public function add<T>(component:T): ComponentSet
	{
		steps.push(component);
		return this;
	} 

	// Adds a function. This function must accept installing entity as a parameter.
	// The function will be executed when the set is installed into an entity. If the 
	// function returns a component instance, it will be added to the entity. If it
	// returns null, it will be ignored.
	public function addFunction(func:Entity->Dynamic): ComponentSet
	{
		steps.push(func);
		return this;
	}

	// Adds a class and parameters to the set. The class will be instantiated with the
	// supplied paramters every time the set is installed in an entity. This prevents
	// sharing of instances that happens when you call set.add(new MyComponent(A, B, C)).
	// For example: set.addClass(MyComponent, A, B, C);
	public function addClass(clazz:Class<Dynamic>, ?args:Array<Dynamic>): ComponentSet
	{
		if(args == null || args.length == 0)
			steps.push(clazz);
		else 
		{
			var arr = [clazz];
			for(arg in args)
				arr.push(arg);
			steps.push(arr);
		}

		return this;
	}

	// Adds all the steps from one entity into the set. Note that these steps
	// are added immediately, so if you add or remove from the supplied entity at a 
	// later point, these changes will not be reflected in the component set.
	public function addEntity(entity:Entity): ComponentSet
	{
		for(component in entity.getAll())
			steps.push(component);
		return this;
	}

	// Adds a ComponentSet to this set. When the set is installed in an entity,
	// the supplied set will also be installed to the entity. Use this to implement
	// a component set hiearchy of parent/child sets. For instance, a gun is a weapon.
	// You could create a WeaponSet and a GunSet and install them both to your new gun 
	// entity, or instead add the WeaponSet to the GunSet using this method. Then when
	// install GunSet, the entity will also get WeaponSet installed.
	public function addSet(set:ComponentSet): ComponentSet
	{
		steps.push(set);
		return this;
	}

	// Does not add an instance. Instead, when installed, removes the supplied 
	// component from the entity, if it has one.
	public function remove(clazz:Class<Dynamic>): ComponentSet
	{
		return addFunction(function(e:Entity)
		{ 
			e.remove(clazz);
			return null;
		});
	}

	// Does not add an instance. Instead, when installed, removes all steps 
	// from an entity. Completely blanks out an entity. Do this before any add calls.
	// If an array of component classes is supplied, these components will be
	// spared removal
 	public function removeAll(?except:Array<Class<Dynamic>>): ComponentSet
	{
		return addFunction(function(e:Entity)
		{ 
			for(c in e.getAll())
			{
				if(except == null || !Lambda.exists(except, cast Type.getClass(c)))
					e.remove(c);
			}
			return null;
		});
	}

	// Installs the steps into the entity
	public function install(entity:Entity)
	{
		for(component in steps)
		{
			// Install multiple component instances from another set
			if(Std.is(component, ComponentSet))
			{
				var cs:ComponentSet = component;
				cs.install(entity);
			}

			// Install one component instance
			else 
			{
				var instance:Dynamic = component;

				// Handle install-time instantion of steps
				if(Std.is(component, Array))
				{
					var a:Array<Dynamic> = cast component;
					instance = Type.createInstance(a[0], a.slice(1));
				}

				// Handle empty class instances
				else if(Std.is(component, Class))
					instance = Type.createEmptyInstance(component);

				// Handle functions
				else if (Reflect.isFunction(component))
				{
					var f:Entity->Dynamic = cast component;
					instance = f(entity);
					if(instance == null)
						continue;
				}

				entity.add(instance);
			}				
		}
	}

	// TODO This reports "[func]" if it encounters a remove or removeAll, this 
	// could be fixed by adding all steps as independent class objects.
	public function toString(): String
	{
		var str:String = "";
		var sep:String = "";
		for(step in steps)
		{
			var stepStr = step;
			if(Std.is(step, Array))
			{
				var arr:Array<Dynamic> = cast step;
				stepStr = arr[0] + "(" + arr.slice(1).join(", ") + ")";
			}
			else if(Std.is(step, Class))
				stepStr = step + "()";
			else if(Reflect.isFunction(step))
			{
				var f:Entity->Dynamic = cast step;				
				stepStr = "[func]";
			}

			str += sep + stepStr;
			sep = ", ";
		}
		return str;
	}
}
