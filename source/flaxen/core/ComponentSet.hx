/**
	Example:
		flaxen.newComponentSet("thang")
			.add(Position.zero)
			.add(function() { return new Layer(15); });
		flaxen.installComponents(myEntity, "thang")
			.add(new OtherComponent());
*/
package flaxen.core;

import ash.core.Entity;

class ComponentSet
{
	private var components:Array<Dynamic>;

	public function new()
	{
		components = new Array<Dynamic>();
	}

	// Adds a component to the component set. There are several ways to do this. 
	// When this component of the ComponentSet is added to the entity (addToEntity),
	// the following have different effects:
	//
	// 	Add a new empty instance of the class:
	// 		add(ComponentClass)
	//
	//	Add the class instance as supplied:
	// 		add(new ComponentClass())
	//
	//	Add an instance which will be returned by a function taking no parameters:
	// 		add(Class.staticFunction)
	//
	//	Add an instance which will be returned by anonymous function:
	// 		add(function()
	//		{ 
	//			return new ComponentClass(param, param);
	//		})
	//
	//	Adds all components (shared) that exist in another entity:
	// 		add(myEntity);
	//
	//	Add a new instance of the class, including variable parameters, where the first
	//	argument is the class and the rest of the array are arguments:
	// 		add([ComponentClass, arg1, ... argN]);
	public function add(addition:Dynamic): ComponentSet
	{
		if(Std.is(addition, Entity))
		{
			var e:Entity = cast addition;
			for(c in e.getAll())
				components.push(addition);
		}

		else components.push(addition);

		return this;
	} 

	// Removes a component from an entity, if it has one
	public function remove(clazz:Class<Dynamic>): ComponentSet
	{
		return add(new RemoveComponentWrapper(clazz));
	}

	// Installs the components into the entity
	public function addToEntity(entity:Entity)
	{
		for(component in components)
		{
			if(Std.is(component, RemoveComponentWrapper))
			{
				var wrapper:RemoveComponentWrapper = cast component;
				entity.remove(wrapper.clazz);
			}

			else
			{
				var instance:Dynamic = component;

				if(Std.is(component, Array))
				{
					var a:Array<Dynamic> = cast component;
					instance = Type.createInstance(a[0], a.slice(1));
				}

				else if(Std.is(component, Class))
					instance = Type.createEmptyInstance(component);

				else if (Reflect.isFunction(component))
				{
					var f:Void->Dynamic = cast component;
					instance = f();
				}

				entity.add(instance);
			}
				
		}
	}
}

private class RemoveComponentWrapper
{
	public var clazz:Class<Dynamic>;

	public function new(clazz:Class<Dynamic>)
	{
		this.clazz = clazz;
	}
}
