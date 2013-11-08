/*
 * In charge of maintenance of transitions between game modes. 
 *
 * To change modes, use flaxen.getApp().changeMode(NewMode); NewMode is one 
 * of the ApplicationModeTypes listed in Application.hx. For example:
 *
 *   flaxen.getApp().changeMode(Mode("MyMode")); // switch to custom mode
 *   flaxen.getApp().changeMode(Play); // switch to built-in mode
 *
 * When a transition is detected, the stop handler for the current mode is called,
 * unprotected entities are destroyed, and then the start handler for the new mode
 * is called.
 * 
 * Start Handler (registerStartHandler)
 *  
 *   Put your mode initialization in this function. This is where you create 
 *   new entities, for example. Changing flaxen.getApp().nextMode during
 *   this handler will cause an immediate transition to another mode. You might
 *   use this, for example, in the Init handler, to immediately transition
 *   to the Menu mode without delay.
 *
 * Stop Handler (registerStopHandler)
 *  
 *   Before unprotected entities have been removed the stop handler is called. You
 *   could use this to save game state to an external source before the entities are
 *   flushed, for instance.  You can force transition to a different following mode
 *   by setting flaxen.getApp().nextMode to a different mode.
 *
 */

package flaxen.system;

import flaxen.core.Flaxen;
import flaxen.core.FlaxenSystem;
import flaxen.component.Application;
import flaxen.component.Transitional;

class ModeSystem extends FlaxenSystem
{
	private var startHandlers:Map<ApplicationMode, FlaxenHandler>;
	private var stopHandlers:Map<ApplicationMode, FlaxenHandler>;

	public function new(f:Flaxen)
	{ 
		super(f); 
	}

	override public function init()
	{
		startHandlers = new Map<ApplicationMode, FlaxenHandler>();
		stopHandlers = new Map<ApplicationMode, FlaxenHandler>();
	}

	override public function update(time:Float)
	{
		var app:Application = flaxen.getApp();
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
	}

	private function runStopHandler(mode:ApplicationMode): Void
	{
		var handler:FlaxenHandler = stopHandlers.get(mode);
		if(handler != null)
			handler(flaxen);		
	}

	private function runStartHandler(mode:ApplicationMode): Void
	{
		var handler:FlaxenHandler = startHandlers.get(mode);
		if(handler != null)
			handler(flaxen);
	}

	public function registerStartHandler(mode:ApplicationMode, handler:FlaxenHandler): Void
	{
		startHandlers.set(mode, handler);
	}

	public function registerStopHandler(mode:ApplicationMode, handler:FlaxenHandler): Void
	{
		stopHandlers.set(mode, handler);
	}

	// Remove all entities, excepting those that are protected.
	// An entity is protected if it has a Transitional component marked
	// "Always" or if the Transitional mode is the same as the mode we're 
	// transitioning to.
	public function removeUnprotected(mode:ApplicationMode): Void
	{
		for(e in ash.entities)
		{
			if(e.has(Transitional))
			{
				var transitional:Transitional = e.get(Transitional);
				if(transitional.isProtected(mode))
				{
					if(transitional.destroyComponent)
						e.remove(Transitional);
					else 
						transitional.complete = true;					
					continue;
				}
			}

			ash.removeEntity(e);
		}
	}	
}
