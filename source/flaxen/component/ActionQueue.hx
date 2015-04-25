package flaxen.component;

import ash.core.Entity;
import flaxen.core.Flaxen;
import flaxen.component.Timestamp;
import flaxen.common.Completable;

/**
 * An action queue is a chain of steps that modify Ash in sequence. For 
 * example, you can tween an entity to some point, wait for it to complete 
 * tweening, add a marker to that entity and then kick off a callback.
 *
 * - NOTE: ActionQueues cannot be shared between entities.
 * - TODO: Add description and give usage examples, add examples
 * - TODO: Move actions to action folder? Right now it clutters up the Component API section.
*/
class ActionQueue implements Completable
{
	public static var created:Int = 0;

	public var flaxen:Flaxen;
	public var queue:QueueTips = { first:null, last:null };
	public var priorityQueue:QueueTips = { first:null, last:null };
	public var onComplete:OnComplete;
	public var complete:Bool = false; // True when queue goes empty
	public var name:String; // optional object name for logging
	public var running:Bool = true;
	
	public function new(?f:Flaxen, ?onComplete:OnComplete, autoStart:Bool = true, ?name:String)
	{
		this.flaxen = f;
		this.onComplete = (onComplete == null ? None : onComplete);
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

	private function verifyFlaxen()
	{
		if(flaxen == null)
			throw "Flaxen must be defined in the constructor to use some added actions";
	}

	/**
	 * Delays an amount of time before continuing the action queue.
	 * @param seconds The number seconds to wait
	 * @param priority Set true if this is a priority action (see `add()`)
	 */
	public function wait(seconds:Float, priority:Bool = false): ActionQueue
	{
		return add(new ActionDelay(seconds), priority);
	}

	/**
	 * Logs a message to the console.
	 * @param message The string to log
	 * @param priority Set true if this is a priority action (see `add()`)
	 */
	public function log(message:String, priority:Bool = false): ActionQueue
	{
		return add(new ActionLog(message), priority);
	}

	/**
	 * Adds a component to an existing entity
	 * @param entity The existing entity to receive the component
	 * @param component The component to be added
	 * @param priority Set true if this is a priority action (see `add()`)
	 */
	public function addComponent(entity:Entity, component:Dynamic, priority:Bool = false): ActionQueue
	{
		return add(new ActionAddComponent(entity, component), priority);
	}

	/**
	 * Removes a component from an entity.
	 * @param entity The entity with the component
	 * @param component The component to be removed
	 * @param priority Set true if this is a priority action; see `add()`
	 */
	public function removeComponent(entity:Entity, component:Class<Dynamic>, priority:Bool = false): ActionQueue
	{
		return add(new ActionRemoveComponent(entity, component), priority);
	}

	/**
	 * Adds an entity to Ash that hasn't been added yet. 
	 * See `newEntity(..., false)` in Flaxen or `new Entity()` in Ash.
	 * @param entity An entity to be added
	 * @param priority Set true if this is a priority action (see `add()`)
	 */
	public function addEntity(entity:Entity, priority:Bool = false): ActionQueue
	{
		verifyFlaxen();
		return add(new ActionAddEntity(flaxen, entity), priority);
	}

	/**
	 * Removes an entity from Ash.
	 * @param entity An entity object to be removed, or the string name of such an entity
	 * @param priority Set true if this is a priority action (see `add()`)
	 */
	public function removeEntity(entity:EntityRef, priority:Bool = false): ActionQueue
	{
		verifyFlaxen();
		return add(new ActionRemoveEntity(flaxen, entity), priority);
	}

	/**
	 *
	 */
	public function setProperty(object:Dynamic, property:String, value:Dynamic, priority:Bool = false): ActionQueue
	{
		return add(new ActionSetProperty(object, property, value), priority);
	}

	/**
	 *
	 */
	public function waitForProperty(object:Dynamic, property:String, value:Dynamic, priority:Bool = false): ActionQueue
	{
		return add(new ActionWaitForProperty(object, property, value), priority);
	}

	/**
	 *
	 */
	public function call(func:Void->Void, priority:Bool = false): ActionQueue
	{
		return add(new ActionCallback(func), priority);
	}

	/**
	 *
	 */
	public function waitForCall(func:Void->Bool, priority:Bool = false): ActionQueue // AKA waitForTrue(func)
	{
		return add(new ActionThread(func), priority);
	}

	/**
	 *
	 */
	public function wrap(component:Dynamic, priority:Bool): ActionQueue
	{
		verifyFlaxen();
		return add(new ActionWrap(flaxen, component), priority);
	}

	/**
	 *
	 */
	public function waitForWrap(completable:Completable, priority:Bool): ActionQueue
	{
		verifyFlaxen();
		add(new ActionWrap(flaxen, completable), priority);
		return add(new ActionWaitForComplete(completable), priority);

	/**
	 *
	 */
	}
	public function waitForComplete(completable:Completable, priority:Bool): ActionQueue
	{
		return add(new ActionWaitForComplete(completable), priority);
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
		entity.remove(component); // remove quietly
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

class ActionRemoveEntity extends Action
{
	public var ref:EntityRef;
	public var flaxen:Flaxen;

	public function new(flaxen:Flaxen, ref:EntityRef)
	{
		super();
		this.flaxen = flaxen;
		this.ref = ref;
	}

	override public function execute(): Bool
	{
		flaxen.removeEntity(ref);
		return true;
	}

	override public function toString(): String
	{
		return 'ActionRemoveEntity (Entity:$ref)';
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

class ActionWrap extends Action
{
	public var component:Dynamic;
	public var flaxen:Flaxen;

	public function new(flaxen:Flaxen, component:Dynamic)
	{
		super();
		this.flaxen = flaxen;
		this.component = component;
	}

	override public function execute(): Bool
	{
		flaxen.newWrapper(component);
		return true;
	}

	override public function toString(): String
	{
		return 'ActionWrap (component:$component)';
	}
}

class ActionWaitForComplete extends Action
{
	public var completable:Completable;

	public function new(completable:Completable)
	{
		super();
		this.completable = completable;
	}

	override public function execute(): Bool
	{
		return completable.complete;
	}

	override public function toString(): String
	{
		return 'ActionWaitForComplete (completable:$completable)';
	}
}

typedef QueueTips = { first:Action, last:Action }

