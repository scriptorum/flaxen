
package flaxen.system;

import flaxen.core.Flaxen;
import flaxen.core.FlaxenSystem;
import flaxen.core.FlaxenHandler;
import flaxen.component.Application;

//
// The job of the input system should be to identify markers or controls that indicate
// what the player is allowed to manipulate at any given moment, and translate that
// to specific intents. An intent could be adding a bullet to the screen, or it could
// be more literally an Intent component/entity, which another system uses to add the
// bullet. The benefit of using Intent components is it decouples the input from the
// results, and enables you to do things like take over user actions, or replay
// movements from a file, etc.
//
class InputSystem extends FlaxenSystem
{
	private var handlers:Map<ApplicationMode, FlaxenCallback>;

	public function new(f:Flaxen)
	{ 
		super(f); 
	}

	override public function init()
	{
		handlers = new Map<ApplicationMode, FlaxenCallback>();
	}

	override public function update(_)
	{
		var app:Application = flaxen.getApp();
		updateHandler(app.curMode);
		updateHandler(Always);
	}

	private function updateHandler(mode:ApplicationMode)
	{
		if(mode == null)
			return;

		var handler:FlaxenCallback = handlers.get(mode);
		if(handler != null)
			handler(flaxen);
	}

	public function registerHandler(mode:ApplicationMode, handler:FlaxenCallback): Void
	{
		if(mode == null)
			return;

		handlers.set(mode, handler);
	}
}
