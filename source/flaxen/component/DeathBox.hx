package flaxen.component;

import openfl.geom.Rectangle;

/**
 * A death box is an area on the screen for automatically removing entities
 * that either stray out of or into specified areas. This is a very basic
 * collision box implementation. Only the registration point of the entity
 * will be checked against the box. You may share this component between 
 * several entities, and you may dynamically alter the death box.
 *
 * - TODO: Add OnComplete handler?
 * - TODO: Refit class to handle proper hitbox collisions, jive this with HP's collision model
 *
 * This component is processed by the `flaxen.system.DeathBoxSystem`.
 */
class DeathBox
{
	/**
	 * The bounding area of this deathbox.
	 */
	public var rect:Rectangle;

	/**
	 * Whether death occurs inside this box, or outside this box.
	 */
	public var deathInside:Bool;

	/**
	 * Constructor.
	 * @param rect he bounding area of this deathbox
	 * @param deathInside Whether death occurs inside this box (default), or outside this box.
	 */
	public function new(rect:Rectangle, deathInside:Bool = true)
	{
		this.rect = rect;
		this.deathInside = deathInside;
	}
}