package flaxen.component;

/*
 * Marks an entity's components as unchanging.
 *
 * This is primarily intended as an optimization for the RenderingSystem. 
 * This system checks all relevant components to see if they've changed,
 * and updates the view if they have. An immutable entity will skip this
 * check, saving some CPU time.
 *
 * The immutability can be temporarily bypassed by calling change(), which
 * tells the RenderingSystem to check the entity for changes on its next pass.
 * After doing so, the system restores immutability.
 *
 * Add Immutable to an entity that won't change - at least not often. Whenever
 * you do modify any of its components, ensure your changes are recognized by
 * calling this:
 * 
 * 		entity.get(Immutable).change();
 *
 * Immutable does not prevent other systems from processing the entity. That is,
 * if you have a movement system, it will still move.
 */

class Immutable
{
	public var changed:Bool;

	public function new() 
	{
		changed = true;
	}

	public function change()
	{
		changed = true;
	}

	public function restore()
	{
		changed = false;
	}
}
