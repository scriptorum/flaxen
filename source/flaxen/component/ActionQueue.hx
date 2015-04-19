/**
	NOTE
	 - ActionQueues cannot be shared between entities.

	TODO
	 - Add description and give usage examples
	 - change add to addAction
	 - change addCallback to call
	 - change addThread to thread
	 - do not require engine as parameter to add/removeEntity, instead supply that to constructor
	 - add an addTween() for better tween integration
*/
package flaxen.component;

import ash.core.Entity;
import ash.core.Engine;
import flaxen.component.Timestamp;

class ActionQueue
{
	public static var created:Int = 0;

	public var first:Action;
	public var last:Action;
	public var destroyEntity:Bool; // When queue is empty, destroy its entity
	public var destroyComponent:Bool; // When queue is empty, destroy this component
	public var complete:Bool = false; // True when queue goes empty
	public var name:String; // optional object name for logging
	public var running:Bool = true;

	public static function create(destroyEntity = false, destroyComponent = false, ?name:String,
		autoStart:Bool = true): ActionQueue
	{
		return new ActionQueue(destroyEntity, destroyComponent, name, autoStart);
	}
	
	public function new(destroyEntity = false, destroyComponent = false, ?name:String,
		autoStart:Bool = true)
	{
		this.destroyEntity = destroyEntity;
		this.destroyComponent = destroyComponent;
		this.name = (name == null ? "fActionQueue"  + Std.string(++created) : name);
		this.running = autoStart;
	}

	public function addActions(actions:Array<Action>)
	{
		for(action in actions)
			add(action);
	}

	public function add(action:Action): ActionQueue
	{
		if(first == null)
			first = last = action;
		else
		{
			last.next = action;
			last = action;
		}

		return this;
	}

	// Convenience adders
	public function delay(duration:Float): ActionQueue
	{
		return(add(new ActionDelay(duration)));
	}
	public function log(message:String): ActionQueue
	{
		return(add(new ActionLog(message)));
	}
	public function addComponent(entity:Entity, component:Dynamic): ActionQueue
	{
		return(add(new ActionAddComponent(entity, component)));
	}
	public function removeComponent(entity:Entity, component:Class<Dynamic>): ActionQueue
	{
		return(add(new ActionRemoveComponent(entity, component)));
	}
	public function addEntity(engine:Engine, entity:Entity): ActionQueue
	{
		return(add(new ActionAddEntity(engine, entity)));
	}
	public function removeEntityByName(engine:Engine, entityName:String): ActionQueue
	{
		return(add(new ActionRemoveEntityByName(engine, entityName)));
	}
	public function removeEntity(engine:Engine, entity:Entity): ActionQueue
	{
		return(add(new ActionRemoveEntity(engine, entity)));
	}
	public function waitForProperty(object:Dynamic, property:String, value:Dynamic): ActionQueue
	{
		return(add(new ActionWaitForProperty(object, property, value)));
	}
	public function addCallback(func:Void->Void): ActionQueue
	{
		return(add(new ActionCallback(func)));
	}
	public function addThread(func:Void->Bool): ActionQueue // AKA waitForTrue(func)
	{
		return(add(new ActionThread(func)));
	}

	// Executes the next action(s) and returns true if the action queue is empty
	// When actions are completed, they are removed from the queue and the next
	// action is executed. An action can hold up the queue by returning false
	// for its execute method, in which case it will be called again later.
	// See ActionSystem.
	public function execute(): Bool 
	{
		if(!running)
			return false;

		while(first != null)
		{
			// Execute next action
			if(first.execute() == false)
			{
				complete = false;				
				return false; // action is busy
			}

			// Move to next action
			first = first.next;
			if(first == null)
				last = null;
		}

		complete = (first == null);
		return true;
	}

	public function pause()
	{
		this.running = false;
	}

	public function resume()
	{
		this.running = true;
	}
}

class Action
{
	public var next:Action;

	private function new()
	{
	}

	public function execute(): Bool // return true if execution complete, otherwise poll again
	{
		return true;
	}

	public function toString(): String
	{
		return "Action";
	}
}

class ActionDelay extends Action
{
	public var duration:Float;

	public function new(duration:Float) // in seconds
	{
		super();
		this.duration = duration;
	}

	private var time:Float = -1;
	override public function execute(): Bool
	{
		if(time == -1)
		{
			time = Timestamp.now();
			return false;
		}

		return (Timestamp.now() - time) >= duration * 1000;
	}

	override public function toString(): String
	{
		return "ActionDelay (duration:" + duration + ")";
	}
}

class ActionAddComponent extends Action
{
	public var component:Dynamic;
	public var entity:Entity;

	public function new(entity:Entity, component:Dynamic)
	{
		super();
		this.entity = entity;
		this.component = component;
	}

	override public function execute(): Bool
	{
		entity.add(component);
		return true;
	}

	override public function toString(): String
	{
		return "ActionAddComponent (entity:" + entity.name + " component:"+ component + ")";
	}
}

class ActionRemoveComponent extends Action
{
	public var component:Class<Dynamic>;
	public var entity:Entity;

	public function new(entity:Entity, component:Class<Dynamic>)
	{
		super();
		this.entity = entity;
		this.component = component;
	}

	override public function execute(): Bool
	{
		entity.remove(component);
		return true;
	}

	override public function toString(): String
	{
		return "ActionRemoveComponent (entity:" + entity.name + " component:"+ component + ")";
	}
}

class ActionAddEntity extends Action
{
	public var entity:Entity;
	public var engine:Engine;

	public function new(engine:Engine, entity:Entity)
	{
		super();
		this.engine = engine;
		this.entity = entity;
	}

	override public function execute(): Bool
	{
		engine.addEntity(entity);
		return true;
	}

	override public function toString(): String
	{
		return "ActionAddEntity (entity:" + entity.name + ")";
	}
}

class ActionRemoveEntityByName extends Action
{
	public var entityName:String;
	public var engine:Engine;

	public function new(engine:Engine, entityName:String)
	{
		super();
		this.engine = engine;
		this.entityName = entityName;
	}

	override public function execute(): Bool
	{
		var entity = engine.getEntityByName(entityName);
		engine.removeEntity(entity);
		return true;
	}

	override public function toString(): String
	{
		return "ActionRemoveEntityByName (entity:" + entityName + ")";
	}
}

class ActionRemoveEntity extends ActionRemoveEntityByName
{
	public function new(engine:Engine, entity:Entity)
	{
		super(engine, entity.name);
	}

	override public function toString(): String
	{
		return "ActionRemoveEntity (entity:" + entityName + ")";
	}
}

class ActionWaitForProperty extends Action
{
	public var object:Dynamic;
	public var property:String;
	public var value:Dynamic;

	public function new(object:Dynamic, property:String, value:Dynamic)
	{
		super();
		this.object = object;
		this.property = property;
		this.value = value;
	}

	override public function execute(): Bool
	{
		return (Reflect.getProperty(object, property) == value);
	}

	override public function toString(): String
	{
		return "ActionWaitForProperty (object:" + object + " property:" + property + " value:" + value + ")";
	}
}

// Use this to execute any arbitrary code.
class ActionCallback extends Action
{
	public var func:Void->Void;

	public function new(func:Void->Void)
	{
		super();
		this.func = func;
	}

	override public function execute(): Bool
	{
		func();
		return true;
	}

	override public function toString(): String
	{
		return "ActionCallback";
	}
}

// This is similar to ActionCallback, except your function must return false if it's still processing, 
// or true when it's complete. Use this to execute a thread; the action queue will hold up until your
// thread indicates it's finished.
class ActionThread extends Action
{
	public var func:Void->Bool;

	public function new(func:Void->Bool)
	{
		super();
		this.func = func;
	}

	override public function execute(): Bool
	{
		return func();
	}

	override public function toString(): String
	{
		return "ActionThread";
	}
}

class ActionLog extends Action
{
	public var message:String;

	public function new(message:String)
	{
		super();
		this.message = message;
	}

	override public function execute(): Bool
	{
		flaxen.core.Log.log(message);
		return true;
	}

	override public function toString(): String
	{
		return "ActionLog (message:" + message + ")";
	}
}