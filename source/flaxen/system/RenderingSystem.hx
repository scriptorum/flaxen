package flaxen.system;

import ash.core.Entity;
import ash.core.Node;
import flaxen.component.Display;
import flaxen.core.Flaxen;
import flaxen.core.FlaxenSystem;
import flaxen.node.DisplayNode;
import flaxen.node.ViewNode;
import flaxen.render.view.AnimationView;
import flaxen.render.view.BackdropView;
import flaxen.render.view.BitmapTextView;
import flaxen.render.view.EmitterView;
import flaxen.render.view.GridView;
import flaxen.render.view.ImageView;
import flaxen.render.view.TextView;
import flaxen.render.view.View;

class RenderingSystem extends FlaxenSystem
{
	private var updateId:Int = 0;

	public function new(f:Flaxen)
	{ 
		super(f); 
	}

	override public function init()
	{
		ash.getNodeList(DisplayNode).nodeRemoved.add(displayNodeRemoved);
	}

	private function displayNodeRemoved(node:DisplayNode): Void
	{
		removeView(node.display.view);
	}

	private function removeView(view:View)
	{
		view.destroy();
		com.haxepunk.HXP.scene.remove(view);
	}

	override public function update(_)
	{
		updateId++;
		updateViews(BackdropNode, BackdropView);
		updateViews(GridNode, GridView);
		updateViews(BitmapTextNode, BitmapTextView); 
		updateViews(AnimationNode, AnimationView);
		updateViews(TextNode, TextView);
		updateViews(EmitterNode, EmitterView);
		updateViews(ImageNode, ImageView); // ImageNode is a superset node, and must go after the subsets
	}

	private function updateViews<TNode:Node<TNode>>(nodeClass:Class<TNode>, viewClass:Class<View>)
	{
		// Loop through all nodes for this node class
	 	for(node in ash.getNodeList(nodeClass))
	 	{
	 		var entity = node.entity;

			// Create view if it does not exist
			var display:Display;
	 		if(!entity.has(Display))
	 			display = createView(entity, viewClass);

	 		// View exists, alias it
	 		else display = entity.get(Display);

	 		// View was already updated via a superset node, just skip it. 
	 		// This prevents duplicate updates, but it also prevents 
	 		// ImageView from taking control from a subset ImageNode.
	 		if(display.updateId == updateId)
	 			continue;

	 		// Recreate Display if the View classes do not match. This can happen if you switch
	 		// an Animation component with a Tile component. Any entity with an Image will be
	 		// in an ImageNode, it's a superset - this means some entities (like Animations) will
	 		// belong to two view nodes. When Animation is removed, the Display node remains, containing
	 		// the wrong view. This and the updateId checking remedies the conundrum.
	 		if(!Std.is(display.view, viewClass))
	 		{
	 			entity.remove(Display);
	 			display = createView(entity, viewClass, display);
	 		}

	 		// Just a regular update
	 		else display.updateId = updateId;

	 		// Update the view
	 		display.view.nodeUpdate();

	 		// Damn view blew up the whole entity!
	 		if(display.destroyEntity)
	 			ash.removeEntity(entity);
		}
	}	

	// Create a new View and wrap it in a Display component
	private function createView(entity:Entity, viewClass:Class<View>, ?display:Display): Display
	{
		var view:View = Type.createInstance(viewClass, [entity]);
		com.haxepunk.HXP.scene.add(view);

		if(display == null)
		{
			display = new Display(view, updateId);
			entity.add(display);
		}
		else 
			display.recycle(view, updateId); // reuse display object

		return display;
	}
}