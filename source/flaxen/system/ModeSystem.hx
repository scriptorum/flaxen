package flaxen.system;

import flaxen.component.Application;
import flaxen.component.Transitional;
import flaxen.Flaxen;
import flaxen.FlaxenHandler;
import flaxen.FlaxenSystem;
import flaxen.Log;

/**
 * In charge of maintenance of transitions between game modes. 
 * 
 * To change modes, use flaxen.setMode(NewMode); NewMode is one 
 * of the ApplicationModeTypes listed in Application.hx. For example:
 * 
 *   flaxen.setMode(Mode("MyMode")); // switch to custom mode
 *   flaxen.setMode(Play); // switch to built-in mode
 * 
 * When a transition is detected, the stop handler for the current mode is called,
 * unprotected entities are destroyed, and then the start handler for the new mode
 * is called.
 * 
 * Start Handler - registerStartHandler
 *  
 *   Put your mode initialization in this function. This is where you create 
 *   new entities, for example. Changing flaxen.getApp().nextMode during
 *   this handler will cause an immediate transition to another mode. You might
 *   use this, for example, in the Init handler, to immediately transition
 *   to the Menu mode without delay.
 *
 * Update Handler - registerUpdateHandler
 *   The UpdateSystem invokes a callback every time the app is updated. This 
 *   is intended to provide you with a place to process player inputs, but it 
 *   can do any kind of frequently-called work.
 * 
 * Stop Handler - registerStopHandler
 *  
 *   Before unprotected entities have been removed the stop handler is called. You
 *   could use this to save game state to an external source before the entities are
 *   flushed, for instance.  You can force transition to a different following mode
 *   by setting flaxen.getApp().nextMode to a different mode.
 *
 * If the Always mode is supplied, this mode is executed when starting or stopping ALL modes.
 * The Always handler is called AFTER the main handler is called. Also see `Transitional`.
 */
class ModeSystem extends FlaxenSystem
{
	private var startHandlers:Map<ApplicationMode, ModeCallback>;
	private var stopHandlers:Map<ApplicationMode, ModeCallback>;
	private var updateHandlers:Map<ApplicationMode, ModeCallback>;

	public function new(f:Flaxen)
	{ 
		super(f); 
	}

	override public function init()
	{
		startHandlers = new Map<ApplicationMode, ModeCallback>();
		stopHandlers = new Map<ApplicationMode, ModeCallback>();
		updateHandlers = new Map<ApplicationMode, ModeCallback>();
	}

	override public function update(time:Float)
	{
		var app:Application = f.getApp();

		// Switch modes if time to do so
		while(app.nextMode != null)
		{
			// Stop current mode
			runStopHandler(app.curMode);
			runStopHandler(Always);

			// Stop handler can decline the transition by setting nextMode to null.
			// Or it can prevent unprotected entities from being removed by setting
			// curMode to null.
			if(app.nextMode == null)
				break;

			// Remove all unprotected entities, protect Transitionals for the next mode
			if(app.curMode != null)
				removeUnprotected(app.nextMode);

			// Was current is now previous
			// Was next is now current
			app.prevMode = app.curMode;
			app.curMode = app.nextMode;

			// Run the start handler for the now-current mode
			runStartHandler(app.curMode);
			runStartHandler(Always);

			// Next is now nothing
			app.nextMode = null;
		}

		// Update current mode
		runUpdateHandler(app.curMode);

		// Update any modes marked as "always"
		runUpdateHandler(Always);
	}

	private function runStopHandler(mode:ApplicationMode): Void
	{
		if(mode == null)
			return;
		runModeCallback(stopHandlers.get(mode));
	}

	private function runStartHandler(mode:ApplicationMode): Void
	{
		if(mode == null)
			return;
		runModeCallback(startHandlers.get(mode));
	}

	private function runUpdateHandler(mode:ApplicationMode)
	{
		if(mode == null)
			return;
		runModeCallback(updateHandlers.get(mode));
	}

	/**
	 * Runs the mode system callback. This callback is in a closure which
	 * has access to the `Flaxen` instance specified by `f` or `flaxen`, 
	 * in case you're not using a FlaxenHandler...
	 */
	private function runModeCallback(cb:ModeCallback)
	{
		if(cb != null)
		{
			var f:Flaxen = f;
			var flaxen:Flaxen = f;
			cb();
		}
	}

	public function registerStartHandler(handler:ModeCallback, mode:ApplicationMode): Void
	{
		Log.assertNonNull(handler);
		startHandlers.set(mode == null ? Default : mode, handler);
	}

	public function registerStopHandler(handler:ModeCallback, mode:ApplicationMode): Void
	{
		Log.assertNonNull(handler);
		stopHandlers.set(mode == null ? Default : mode, handler);
	}

	public function registerUpdateHandler(handler:ModeCallback, ?mode:ApplicationMode): Void
	{
		Log.assertNonNull(handler);
		updateHandlers.set(mode == null ? Default : mode, handler);
	}

	public function registerHandler(handler:FlaxenHandler, ?mode:ApplicationMode): Void
	{
		Log.assertNonNull(handler);
		if(mode == null)
			mode = Default;

		registerStartHandler(handler.start, mode);
		registerStopHandler(handler.stop, mode);
		registerUpdateHandler(handler.update, mode);
	}

	/**
	 * Remove all entities, excepting those that are protected.
	 * An entity is protected if it has a Transitional component marked
	 * "Always" or if the Transitional mode is the same as the mode we're 
	 * transitioning to.
	 * 
	 * - TODO Jive this with Flaxen.removeTransitionedEntities();
	 */
	public function removeUnprotected(mode:ApplicationMode): Void
	{
		for(e in ash.entities)
		{
			if(e.has(Transitional))
			{
				var transitional:Transitional = e.get(Transitional);
				if(transitional.isProtected(mode))
				{

					if(transitional.onComplete == DestroyComponent)
						e.remove(Transitional);
					else 
						transitional.complete = true;					
				}
				continue;
			}

			ash.removeEntity(e);
		}
	}	
}
