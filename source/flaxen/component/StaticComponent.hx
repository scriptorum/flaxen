/**
	Extend this class to create a singleton/static component. Although it doesn't look it,
	this is a component with a private constructor and a single static instance. Therefore, this:

		class Hungry extends StaticComponent {}

	is the same as writing:

		class Hungry
		{
	        public static function instance:Hungry = new Hungry();
	        private function new() { }	
		}

	See Macro.buildSingleton() for how this modifies a class defined using @:build. 
	Because it's @:autoBuild, buildSingleton() then will act upon any class that extends 
	THIS class, which is very convenient.

	This class is also useful for building Controls, which are components that - by their existence - 
	permit systems to run. For example, add a CanFireWeapon.instance to an Entity, and the FireSystem
	can call flaxen.hasControl(CanFireWeapon) to determine whether or not to process.
		
*/

package flaxen.component;

@:autoBuild(flaxen.util.Macro.buildSingleton()) class StaticComponent
{
    // public static function instance:StaticComponent = new StaticComponent();
    // private function new() { }	
}
