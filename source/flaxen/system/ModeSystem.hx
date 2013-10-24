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

class ModeSystem extends FlaxenSystem
{
	private var startHandlers:Map<ApplicationMode, FlaxenHandler>;
	private var stopHandlers:Map<ApplicationMode, FlaxenHandler>;

	override public function init()
	{
		startHandlers = new Map<ApplicationMode, FlaxenHandler>();
		stopHandlers = new Map<ApplicationMode, FlaxenHandler>();
	}

	override public function update(time:Float)
	{
		var app:Application = flaxen.getApp();
		while(app.nextMode != app.currentMode)
		{
			var stopHandler:FlaxenHandler = stopHandlers.get(app.currentMode);
			if(stopHandler != null)
				stopHandler(flaxen);

			if(app.currentMode != null)
				flaxen.transitionTo(app.nextMode);

			app.currentMode = app.nextMode;

			var startHandler:FlaxenHandler = startHandlers.get(app.currentMode);
			if(startHandler != null)
				startHandler(flaxen);
		}
	}

	public function registerStartHandler(mode:ApplicationMode, handler:FlaxenHandler): Void
	{
		startHandlers.set(mode, handler);
	}

	public function registerStopHandler(mode:ApplicationMode, handler:FlaxenHandler): Void
	{
		stopHandlers.set(mode, handler);
	}
}
