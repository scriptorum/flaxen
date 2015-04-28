package flaxen.component;

import ash.core.Entity;
import flaxen.core.Flaxen;
import flaxen.component.Timestamp;
import flaxen.common.Completable;

/**
 * An action queue is a chain of steps that modify Ash in sequence. For 
 * example, you can tween an entity to some point, wait for it to complete 
 * tweening, add a component to that entity and then kick off a callback:
 * 
 * ```
 * f.newActionQueue()
 *  	.waitForWrap(new Tween(myEntity.get(Position), { x:50, y:100 }, 3.0, null, null, DestroyEntity))
 *  	.addComponent(myEntity, new ReadyToFire())
 *  	.call(function() { levelMgr.load(nextLevel); });
 * ```
 *
 * - NOTE: ActionQueues cannot be shared between entities.
 * - TODO: Add description and give usage examples, add examples
 * - TODO: Move actions to action folder? Right now it clutters up the Component API section.
 * - CONSIDER: Could the AQ retain a copy of the last entity/component/object it worked on,
 *   and then recall that entity with a special construct?
 */
class ActionQueue implements Completable
{
	/** The total number of action queues created */
	public static var created:Int = 0;

	/** The Flaxen object; not required for all actions, but it is for most of them. */
	private var flaxen:Flaxen;

	/** The primary/main queue of actions */	
	private var queue:QueueTips = { first:null, last:null };

	/** The priority queue of actions; see `add()` */
	private var priorityQueue:QueueTips = { first:null, last:null };

	/** What to do after the action queue completes */
	public var onComplete:OnComplete;

	/** This is set to true when the queue becomes empty */
	public var complete:Bool = false;

	/** The name is primarily intended for logging, but you can also set it to the 
	holding entity's name; in fact, that's what `Flaxen.newActionQueue` does */
	public var name:String;

	/** The action queue is only processed when running is true; you can set this false 
		to pause the queue; you can pass false for autoStart to delay executation. */
	public var running:Bool = false;
	
	/** 
	 * Creates a new ActionQueue.
	 * @param The Flaxen object
	 * @param onComplete What to do after the queue completes
	 * @param autoStart If true (default) runs the queue immediately; if false, you may run the queue manually by setting `running`
	 * @param The name of the ActionQueue; see `name`
	 */
	public function new(?f:Flaxen, ?onComplete:OnComplete, autoStart:Bool = true, ?name:String)
	{
		this.flaxen = f;
		this.onComplete = (onComplete == null ? None : onComplete);
		this.name = (name == null ? "__actionQueue"  + Std.string(++created) : name);

		this.running = autoStart;
	}

	/**
	 * Adds an array of actions at once.
	 * @param actions The array
	 */
	public function addActions(actions:Array<Action>)
	{
		for(action in actions)
			add(action);
	}

	/**
	 * Adds an action to the queue.
	 *
	 * The priority flag is intended to allow a callback action to modify the 
	 * queue while its still being processed. To do this, pass true for 
	 * priority as the last parameter. Priority actions are kept in a 
	 * secondary queue, and will be added to front of the main queue when 
	 * the callback completes.
	 *
	 * @param action An action (command) object to add to the queue
	 * @param priority Set true if this is a priority action
	 * @returns This ActionQueue object
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

	@:dox(hide) private function verifyFlaxen()
	{
		if(flaxen == null)
			throw "Flaxen must be defined in the constructor to use some added actions";
	}

	/**
	 * Delays an amount of time before continuing the action queue.
	 * @param seconds The number seconds to wait
	 * @param priority Set true if this is a priority action (see `add()`)
	 * @returns This ActionQueue object
	 */
	public function wait(seconds:Float, priority:Bool = false): ActionQueue
	{
		return add(new ActionDelay(seconds), priority);
	}

	/**
	 * Logs a message to the console.
	 * @param message The string to log
	 * @param priority Set true if this is a priority action (see `add()`)
	 * @returns This ActionQueue object
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
	 * @returns This ActionQueue object
	 */
	public function addComponent(entityRef:EntityRef, component:Dynamic, priority:Bool = false): ActionQueue
	{
		var entity = entityRef.toEntity(flaxen);
		return add(new ActionAddComponent(entity, component), priority);
	}

	/**
	 * Removes a component from an entity.
	 * @param entity The entity with the component
	 * @param component The component to be removed
	 * @param priority Set true if this is a priority action; see `add()`
	 * @returns This ActionQueue object
	 */
	public function removeComponent(entityRef:EntityRef, component:Class<Dynamic>, priority:Bool = false): ActionQueue
	{
		var entity = entityRef.toEntity(flaxen);
		return add(new ActionRemoveComponent(entity, component), priority);
	}

	/**
	 * Adds an entity to Ash that hasn't been added yet. 
	 * See `newEntity(..., false)` in Flaxen or `new Entity()` in Ash.
	 * @param entity An entity to be added
	 * @param priority Set true if this is a priority action (see `add()`)
	 * @returns This ActionQueue object
	 */
	public function addEntity(entityRef:EntityRef, priority:Bool = false): ActionQueue
	{
		verifyFlaxen();
		var entity = entityRef.toEntity(flaxen);
		return add(new ActionAddEntity(flaxen, entity), priority);
	}

	/**
	 * Removes an entity from Ash.
	 * @param entity An entity object to be removed, or the string name of such an entity
	 * @param priority Set true if this is a priority action (see `add()`)
	 */
	public function removeEntity(entityRef:EntityRef, priority:Bool = false): ActionQueue
	{
		verifyFlaxen();
		var entity = entityRef.toEntity(flaxen);
		return add(new ActionRemoveEntity(flaxen, entity), priority);
	}

	/**
	 * Sets the property of an object to a value. As in, `object.property = value;`.
	 * @param object An object with a matching property
	 * @param property A string representing the name of the property
	 * @param value The value to set the property to
	 * @param priority Set true if this is a priority action (see `add()`)
	 * @returns This ActionQueue object
	 */
	public function setProperty(object:Dynamic, property:String, value:Dynamic, priority:Bool = false): ActionQueue
	{
		return add(new ActionSetProperty(object, property, value), priority);
	}

	/**
	 * Waits for the value of an object's property to reach a certain value.
	 * @param object An object with a matching property
	 * @param property A string representing the name of the property
	 * @param value The value to wait for
	 * @param priority Set true if this is a priority action (see `add()`)
	 * @returns This ActionQueue object
	 */
	public function waitForProperty(object:Dynamic, property:String, value:Dynamic, priority:Bool = false): ActionQueue
	{
		return add(new ActionWaitForProperty(object, property, value), priority);
	}

	/**
	 * Calls a function that accepts no parameters and returns nothing.
	 * @param func An anonymous function in the form of Void->Void
	 * @param priority Set true if this is a priority action (see `add()`)
	 * @returns This ActionQueue object
	 */
	public function call(func:Void->Void, priority:Bool = false): ActionQueue
	{
		return add(new ActionCallback(func), priority);
	}

	/**
	 * Calls a function repeatedly, that accepts no parameters and returns a boolean value,
	 * until that function returns true. This works sort of like a thread.
	 * @param func An anonymous function in the form of Void->Bool
	 * @param priority Set true if this is a priority action (see `add()`)
	 * @returns This ActionQueue object
	 */
	public function waitForCall(func:Void->Bool, priority:Bool = false): ActionQueue // AKA waitForTrue(func)
	{
		return add(new ActionThread(func), priority);
	}

	/**
	 * Wraps a component into a new entity.
	 * Creates a new entity with an unique name, adds it to ash, and adds the component to the entity.
	 * @param component The component to "wrap" into a new entity
	 * @param priority Set true if this is a priority action (see `add()`)
	 * @returns This ActionQueue object
	 */
	public function wrap(component:Dynamic, priority:Bool): ActionQueue
	{
		verifyFlaxen();
		return add(new ActionWrap(flaxen, component), priority);
	}

	/**
	 * Wraps a `Completable` component into a new entity.
	 * Creates a new entity with an unique name, adds it to ash, and adds the component to the entity.
	 * Waits until the component's complete property is true.
	 * This is useful for adding new Tweens and Sounds, for example, other perhaps another ActionQueue.
	 * @param component A Completable component to wrap into a new entity and wait for
	 * @param priority Set true if this is a priority action (see `add()`)
	 * @returns This ActionQueue object
	 */
	public function waitForWrap(completable:Completable, priority:Bool): ActionQueue
	{
		verifyFlaxen();
		add(new ActionWrap(flaxen, completable), priority);
		return add(new ActionWaitForComplete(completable), priority);

	/**
	 * Waits the `complete` property of a component to turn true.
	 * @param component A Completable component
	 * @param priority Set true if this is a priority action (see `add()`)
	 * @returns This ActionQueue object
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

/**
 * A superclass for an Action definition. Generally you don't need to mess 
 * with Action objects directly. The convenience methods in `ActionQueue` 
 * will create these actions for you. However if you wanted to add your own 
 * custom Action, this is what you would subclass.
 */
class Action
{
	public var next:Action;

	private function new()
	{
	}

	/**
	 * The execute method should return true if the action is complete. If it 
	 * is still processing or waiting for something, return false. This should
	 * generally be true unless this is a waitForXXX kind of action.
	 */
	public function execute(): Bool
	{
		return true;
	}

	public function toString(): String
	{
		return "Action";
	}
}

/**
 * Waits duration seconds.
 */
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

/**
 * Adds the component to the specified entity.
 */
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

/**
 * Removes the component from the specified entity.
 */
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

/**
 * Adds the specified free entity to Ash.
 */
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

/**
 * Removes the specified entity from Ash.
 */
class ActionRemoveEntity extends Action
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
		flaxen.removeEntity(entity);
		return true;
	}

	override public function toString(): String
	{
		return 'ActionRemoveEntity (Entity:$entity)';
	}
}

/**
 * Waits for the specified property of the specified object to turn the 
 * specified value. Specifically.
 */
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

/**
 * Sets the property of an object to a specific value.
 */
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

/**
 * Calls an arbitrary function.
 */
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
 * thread indicates it's finished.
 */
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

/**
 * Logs a message.
 */
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

/**
 * Wraps a component into new entity and adds that entity to Ash.
 */
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

/**
 * Waits for the complete property of an object to be true.
 */
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

/**
 * Defines an object for storing the first and last actions in a queue.
 */
typedef QueueTips = { first:Action, last:Action }

