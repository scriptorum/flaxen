/**
	Controls are a way to activate and deactivate systems or aspects of systems.
	Use a Control subclass in order to use Flaxen's control functions (newControl,
	removeControl, hasControl). You'll need to define the Control class before using
	it. There's nothing special about the Control interface, but Flaxen will keep
	all controls in a single special entity, ensuring there aren't duplicate controls
	around. As an alternative, you could create markers (see Flaxen marker functions),
	or just create your own custom components au naturale.
	
	For example, if you want a player to be able to jump, you create a JumpControl
	class and pass an instance of it to flaxen.newControl(). During update or in a
	separate system, you check for the SPACEBAR, and if that is triggered you only
	jump if flaxen.hasControl(JumpControl) returns true. Therefore to prevent 
	jumping when traveling through mud, you would flaxen.removeControl(JumpControl)
	and reinstate this ability after exiting the mud.
 */

package flaxen.component;

// To create a custom control, create a custom class and implement this interface
interface Control
{
}

// However, you'll more likely want to create a standard static control.
// Extending this class will create such a control, whose static instance can 
// be referenced using the .instance static variable. Although it doesn't look it,
// extending this class will create a component with a private constructor and a single 
// static instance. See Macro for more information.
@:autoBuild(flaxen.util.Macro.buildSingleton()) class StaticControl implements Control
{
    // public static function instance:StaticControl = new StaticControl();
    // private function new() { }	
}
