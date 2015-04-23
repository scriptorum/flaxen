/**
 * *NOTE: ActionQueues cannot be shared between entities.*
 *
 * - TODO: Add description and give usage examples
 * - TODO: Move actions to action folder, right now it clutters up the Component API section.
*/
package flaxen.component;

import ash.core.Entity;
import flaxen.core.Flaxen;
import flaxen.component.Timestamp;

typedef QueueTips = { first:Action, last:Action }

class ActionQueue
{
	public static var created:Int = 0;

	public var f:Flaxen;
	public var queue:QueueTips = { first:null, last:null };
	public var priorityQueue:QueueTips = { first:null, last:null };
	public var destroyEntity:Bool; // When queue is empty, destroy its entity
	public var destroyComponent:Bool; // When queue is empty, destroy this component
	public var complete:Bool = false; // True when queue goes empty
	public var name:String; // optional object name for logging
	public var running:Bool = true;
	
	public function new(f:Flaxen, destroyEntity = false, destroyComponent = false, 
		autoStart:Bool = true, ?name:String)
	{
		this.f = f;
		this.destroyEntity = destroyEntity;
		this.destroyComponent = destroyComponent;
		this.name = (name == null ? "__actionQueue"  + Std.string(++created) : name);

		this.running = autoStart;
	}

	public function addActions(actions:Array<Action>)
	{
		for(action in actions)
			add(action);
	}

	/**
	 * The priority flag is intended to allow a callback action to modify the queue
	 * while its still being processed. Priority actions are kept in a secondary 
	 * queue, and added to front of the main queue when the callback completes.
	 */
	public function add(action:Action, priority:Bool = false): ActionQueue
	{
		var q = (priority ? priorityQueue : queue);

		if(q.first == null)
			q.first = q.last = action;
		else
		{
			q.last.next = action;
			q.last = action;
		}

		return this;
	}

	
	// Convenience adders
	// DOCUMENT THESE

	public function wait(seconds:Float, priority:Bool = false): ActionQueue
	{
		return add(new ActionDelay(seconds), priority);
	}
	public function log(message:String, priority:Bool = false): ActionQueue
	{
		return add(new ActionLog(message), priority);
	}
	public function addComponent(entity:Entity, component:Dynamic, priority:Bool = false): ActionQueue
	{
		return add(new ActionAddComponent(entity, component), priority);
	}
	public function removeComponent(entity:Entity, component:Class<Dynamic>, priority:Bool = false): ActionQueue
	{
		return add(new ActionRemoveComponent(entity, component), priority);
	}
	public function addEntity(entity:Entity, priority:Bool = false): ActionQueue
	{
		return add(new ActionAddEntity(f, entity), priority);
	}
	public function removeEntity(entity:Entity, priority:Bool = false): ActionQueue
	{
		return add(new ActionRemoveEntity(f, entity), priority);
	}
	public function removeNamedEntity(entityName:String, priority:Bool = false): ActionQueue
	{
		return add(new ActionRemoveNamedEntity(f, entityName), priority);
	}
	public function setProperty(object:Dynamic, property:String, value:Dynamic, priority:Bool = false): ActionQueue
	{
		return add(new ActionSetProperty(object, property, value), priority);
	}
	public function waitForProperty(object:Dynamic, property:String, value:Dynamic, priority:Bool = false): ActionQueue
	{
		return add(new ActionWaitForProperty(object, property, value), priority);
	}
	public function call(func:Void->Void, priority:Bool = false): ActionQueue
	{
		return add(new ActionCallback(func), priority);
	}
	public function waitForCall(func:Void->Bool, priority:Bool = false): ActionQueue // AKA waitForTrue(func)
	{
		return add(new ActionThread(func), priority);
	}

	/**
	 * Executes the next action(s) and returns true if the action queue is empty
	 * When actions are completed, they are removed from the queue and the next
	 * action is executed. An action can hold up the queue by returning false
	 * for its execute method, in which case it will be called again later.
	 * See ActionSystem.
	 */
	public function execute(): Bool 
	{
		if(!running)
			return false;

		// Move priority actions to the front of the primary queue
		if(priorityQueue.first != null)
		{
			priorityQueue.last.next = queue.first;
			queue.first = priorityQueue.first;
			queue.last = priorityQueue.last;
			priorityQueue.first = priorityQueue.last = null;
		}

		while(queue.first != null)
		{
			// Execute next action
			if(queue.first.execute() == false)
			{
				complete = false;				
				return false; // action is busy
			}

			// Move to next action
			queue.first = queue.first.next;
			if(queue.first == null)
				queue.last = null;
		}

		complete = (queue.first == null);
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
	public var flaxen:Flaxen;

	public function new(flaxen:Flaxen, entity:Entity)
	{
		super();
		this.flaxen = flaxen;
		this.entity = entity;
	}

	override public function execute(): Bool
	{
		flaxen.addEntity(entity);
		return true;
	}

	override public function toString(): String
	{
		return "ActionAddEntity (entity:" + entity.name + ")";
	}
}

class ActionRemoveNamedEntity extends Action
{
	public var entityName:String;
	public var flaxen:Flaxen;

	public function new(flaxen:Flaxen, entityName:String)
	{
		super();
		this.flaxen = flaxen;
		this.entityName = entityName;
	}

	override public function execute(): Bool
	{
		var entity = flaxen.getEntity(entityName);
		flaxen.removeEntity(entity);
		return true;
	}

	override public function toString(): String
	{
		return "ActionRemoveNamedEntity (entity:" + entityName + ")";
	}
}

class ActionRemoveEntity extends ActionRemoveNamedEntity
{
	public function new(flaxen:Flaxen, entity:Entity)
	{
		super(flaxen, entity.name);
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

class ActionSetProperty extends Action
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
		Reflect.setProperty(object, property, value);
		return true;
	}

	override public function toString(): String
	{
		return "ActionSetProperty (object:" + object + " property:" + property + " value:" + value + ")";
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
	/**
	 * var aq = this;
	 */
		// var f = this.f;
		func();
		return true;
	}

	override public function toString(): String
	{
		return "ActionCallback";
	}
}

	/**
	 * This is similar to ActionCallback, except your function must return false if it's still processing, 
	 * or true when it's complete. Use this to execute a thread; the action queue will hold up until your
	 */
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