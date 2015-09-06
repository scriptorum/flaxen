package flaxen.component;

import flaxen.render.view.View;

/**
 * Contains a View, which wraps a "HaxePunk entity," which you can manipulate
 * through this component's view field. This component is not immediately
 * available - it will be added once the entity is processed by the
 * RenderingSystem.
 *
 * ```
 *	// Create an entity that will spawn a HaxePunk Image
 *	var ashEntity = newEntity()
 *	 	.add(new Image("art/flaxen.png"))
 *	 	.add(Position.zero());
 *
 * 	// After the RenderingSystem has processed the entity, you can manipulate it:
 *	if(ashEntity.has(Display))
 *	{
 *		var hpEntity:com.haxepunk.Entity = cast ashEntity.get(Display).view;
 *		var image:com.haxepunk.graphics.Image = hpEntity.graphics;
 *		// Do something custom with HaxePunk entity or image.
 *	}
 *
 * ```
 */
class Display
{
	public var updateId:Int = -1;
	
	@nodump // prevent recursing into with LogUtil.dump
	public var view:View;

	/**
	 * INTERNAL METHOD
	 * Set to true to destroy this entity ASAP.
	 * This should not be set directly by the user.
	 */
	public var destroyEntity:Bool = false;

	public function new(view:View, updateId:Int = -1)
	{
		recycle(view, updateId);
	}

	public function recycle(view:View, updateId:Int = -1)
	{
		this.updateId = updateId;
		this.view = view;
		this.destroyEntity = false;
	}
}
