package flaxen.component;

import ash.core.Entity;
import flaxen.Flaxen;
import flaxen.common.Completable;
import flaxen.action.*;

/**
 * In an entity-component-system, systems represent the behavior. Systems
 * examine the state of the game via the entities and their components, and
 * react to it, by adding/removing entities and modifying components. This in
 * turn can trigger another reaction, which triggers another. While systems
 * can be used for complicated chain of actions and reactions, sometimes it
 * can make the design needlessly complicated.
 * 
 * An alternative way to encode a series of actions is through an action
 * queue. ActionQueue is a chain of steps that modifies the game state in
 * sequence. Consider a dead enemy that you want to fade to white, leaving a
 * puff of smoke and removing the corpse. You overlay the corpse with an all
 * white corpseFx entity and give it an Alpha of 0 (transparent). You fade in
 * corpseFX, remove the original corpse, invoke a particle effect, wait for
 * that effect to complete, and then clean up by removing the corpseFX entity.
 * 
 * ```
 * f.newActionQueue()
 *     .waitForWrap(new Tween(corpseFX.get(Alpha), { value:1.0 }, 1.0, null, null, DestroyEntity));
 *     .removeEntity(corpse)
 *     .addComponent(corpseFX, smokeEmitter)
 *     .waitForComplete(smokeEmitter)
 *     .removeEntity(corpseFX);
 * ```
 *
 * This could be done with systems instead, and in many cases it should. Systems require
 * more boilerplate and time to implement, so for one-off effects often an ActionQueue
 * is preferable.
 *
 * For an action queue to be processed, you must use ActionSystem, the ActionQueue instance
 * must be added to an entity, the entity must be added to Ash, and either autoStart
 * must be true on creation, or running set to true after creation. 
 *
 * - NOTE: ActionQueues cannot be shared between entities.
 * - CONSIDER: Could the AQ retain a copy of the last entity/component/object it worked on,
 *   and then recall that entity with a special construct?
 */
class ActionQueue implements Completable
{
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

	/** The name is primarily intended for the holding entity's name, which can be
		helpful in some cases; `Flaxen.newActionQueue` sets this automatically;
		can be null if not defined */
	public var name:String;

	/** The action queue is only being processed when running is true; you can set
		this false to pause the processing; you can pass false for autoStart to 
		delay execution */
	public var running:Bool = false;
	
	/** 
	 * Creates a new ActionQueue.
	 * 
	 * @param The Flaxen object
	 * @param onComplete What to do after the queue completes
	 * @param autoStart If true (default) runs the queue automatically; if false, you may run the queue manually by setting `running`
	 * @param The name of the ActionQueue; see `name`
	 */
	public function new(?f:Flaxen, ?onComplete:OnComplete, autoStart:Bool = true, ?name:String)
	{
		this.flaxen = f;
		this.onComplete = (onComplete == null ? None : onComplete);
		this.name = name;
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

		complete = false; // If new actions are added, we can't be complete

		return this;
	}

	@:dox(hide) private function verifyFlaxen()
	{
		if(flaxen == null)
			throw "Flaxen must be defined in the constructor to use some added actions";
	}

	/**
	 * Immediately sets `onComplete`.
	 * @param	OnComplete	What to do after the action queue completes
	 * @returns This ActionQueue object
	 */
	public function setOnComplete(onComplete:OnComplete): ActionQueue
	{
		this.onComplete = onComplete;
		return this;
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
	 * During testing I've found at times to have an action that waits one 
	 * frame before resuming. This achieves that.
	 * @returns This ActionQueue object
	 */
	public function waitOnce(priority:Bool = false): ActionQueue
	{
		var flip:Bool = false;
		return add(new ActionThread(function() { if(flip) return true; flip = true; return false; }));
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
	 *
	 * @param	func		An anonymous function in the form of Void->Void
	 * @param	priority	Set true if this is a priority action (see `add()`)
	 * @returns	This ActionQueue object
	 */
	public function call(func:Void->Void, priority:Bool = false): ActionQueue
	{
		return add(new ActionCallback(func), priority);
	}

	/**
	 * Calls a function repeatedly, that accepts no parameters and returns a boolean value,
	 * until that function returns true. This works sort of like a thread.
	 *
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
	 *
	 * @param component The component to "wrap" into a new entity
	 * @param name An optional name or pattern the the wrapping entity; see `Flaxen.newEntity`
	 * @param priority Set true if this is a priority action (see `add()`)
	 * @returns This ActionQueue object
	 */
	public function wrap(component:Dynamic, name:String = null, priority:Bool = false): ActionQueue
	{
		verifyFlaxen();
		return add(new ActionWrap(flaxen, component, name), priority);
	}

	/**
	 * Wraps a `Completable` component into a new entity.
	 * Creates a new entity with an unique name, adds it to Ash, and adds the component to the entity.
	 * Waits until the component's `complete` property to become true.
	 * This is useful for adding new Tweens and Sounds, for instance, or perhaps a nested ActionQueue.
	 *
	 * @param component A Completable component to wrap into a new entity and wait for
	 * @param name An optional name or pattern the the wrapping entity; see `Flaxen.newEntity`
	 * @param priority Set true if this is a priority action (see `add()`)
	 * @returns This ActionQueue object
	 */
	public function waitForWrap(completable:Completable, name:String = null, priority:Bool = false): ActionQueue
	{
		verifyFlaxen();
		add(new ActionWrap(flaxen, completable, name), priority);
		return add(new ActionWaitForComplete(completable), priority);

	/**
	 * Waits the `complete` property of a component to turn true.
	 * @param component A Completable component
	 * @param priority Set true if this is a priority action (see `add()`)
	 * @returns This ActionQueue object
	 */
	}
	public function waitForComplete(completable:Completable, priority:Bool = false): ActionQueue
	{
		return add(new ActionWaitForComplete(completable), priority);
	}

	/**
	 * Executes the next action(s) and returns true if the action queue is empty
	 * When actions are completed, they are removed from the queue and the next
	 * action is executed. An action can hold up the queue by returning false
	 * for its execute method, in which case it will be called again later.
	 * See ActionSystem.
	 *
	 * @returns True if the all actions have been processed; if false, call execute again to process actions further.
	 */
	public function execute(): Bool 
	{
		if(!running)
			return complete;

		while(priorityQueue.first != null || queue.first != null)
		{
			var q = (priorityQueue.first == null ? queue : priorityQueue);

			// Execute next action
			if(q.first.execute() == false)
				break;

			// Move to next action
			q.first = q.first.next;
			if(q.first == null)
				q.last = null;
		}

		complete = (queue.first == null && priorityQueue.first == null);
		return complete;
	}

	/**
	 * Pauses the action queue.
	 * Call `resume` to continue.
	 */
	public function pause()
	{
		this.running = false;
	}

	/**
	 * Resumes a paused action queue.
	 */
	public function resume()
	{
		this.running = true;
	}
}

/**
 * Defines an object for storing the first and last actions in a queue.
 */
@:dox(hide) typedef QueueTips = { first:Action, last:Action }

