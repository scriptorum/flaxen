/**
 * The UpdateSystem invokes a callback every time the app is updated. This is intended to 
 * provide you with a place to process player inputs, but it can do any kind of update work.
 * 
 * For inputs, you should use markers or controls to indicate what inputs are allowed at
 * any given moment, and then respond to the inputs appropriately. Three schools of thought:
 * 
 * 1. The simplistic response is to make changes to the to entities right there [e.g., add a 
 *    bullet to the screen]. This is quickest to implement and traditional, but it doesn't
 *    take much advantage of entity component system design. Use CanXXXX controls or markers to
 *    determine what a player is allowed to do at any moment [e.g., CanFire or CanJump].
 * 2. A first level indirection is to add intents, entities that contain components [e.g., add
 *    a Spawner("bullet"), Rotation, and Position to an entity] to be processed by another 
 *    system [e.g, the SpawnerSystem processes Spawner entities and adds the bullet with a 
 *    puff of smoke, at the position indicated, firing the direction indicated]. This decouples
 *    the input from the outcome, which makes it easy for multiple game objects to have 
 *    multiple effects. [e.g., both players and AI robots can fire now.]
 * 3. For deeper indirection, you could also add a literal Intent subclass [e.g., create an
 *    entity with a FireWeaponIntent(x,y)], which another system responds to
 *    [e.g., WeaponFireSystem]. This decouples the input from the results, and enables you 
 *    to do things like take over user actions, or replay movements from a file, etc.
 * 
 * If the Always mode is supplied, this mode is executed when updating ALL modes. The Always 
 * handler is called AFTER the main handler is called.
 * 
 * - TODO: Add explanation of handlers and application modes to the wiki, because this is not very helpful.
 */

package flaxen.system;

import flaxen.component.Application;
import flaxen.Flaxen;
import flaxen.FlaxenHandler;
import flaxen.FlaxenSystem;
import flaxen.Log;
import flaxen.system.ProfileSystem; // Needed for stats

class UpdateSystem extends FlaxenSystem
{
	private var handlers:Map<ApplicationMode, FlaxenCallback>;
	private var stats:ProfileStats;

	public function new(f:Flaxen)
	{ 
		super(f); 
	}

	override public function init()
	{
		handlers = new Map<ApplicationMode, FlaxenCallback>();

		#if profiler
		stats = f.resolveEntity(Flaxen.PROFILER).get(ProfileStats);
		#end
	}

	override public function update(_)
	{
		var app:Application = f.getApp();
		updateHandler(app.curMode);
		updateHandler(Always);
	}

	private function updateHandler(mode:ApplicationMode)
	{
		Log.assertNonNull(mode);
		var handler:FlaxenCallback = handlers.get(mode);
		if(handler != null)
		{

	// #if profiler
	// 	var profile = stats.getOrCreate("UpdateHandler:" + mode);
	// 	profile.open();
	// #end

			handler(f);			

	// #if profiler
	// 	profile.close();
	// #end
		}
	}

	public function registerHandler(handler:FlaxenCallback, ?mode:ApplicationMode): Void
	{
		Log.assertNonNull(handler);
		handlers.set(mode == null ? Default : mode, handler);
	}
}
