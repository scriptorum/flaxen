package flaxen.system;

import ash.core.Node;
import com.haxepunk.utils.Key;
import com.haxepunk.HXP;
import flaxen.core.FlaxenSystem;

//
// The job of the input system should be to identify markers or controls that indicate
// what the player is allowed to manipulate at any given moment, and translate that
// to specific intents. An intent could be adding a bullet to the screen, or it could
// be more literally an Intent component/entity, which another system uses to add the
// bullet. The benefit of using Intent components is it decouples the input from the
// results, and enables you to do things like take over user actions, or replay
// movements from a file, etc.
//
// TODO Come up with a generic input system that I can hook into outside of Flaxen.
class InputSystem extends FlaxenSystem
{
	override public function update(_)
	{
		// Check for control or marker enabling this system
		// Check InputService.pressed to see if button is pressed
	}
}
