package flaxen.system;

import ash.core.Node;
import com.haxepunk.HXP;
import flaxen.core.Flaxen;
import flaxen.core.FlaxenSystem;
import flaxen.render.ImageView;
import flaxen.render.AnimationView;
import flaxen.render.BackdropView;
import flaxen.render.GridView;
import flaxen.render.TextView;
import flaxen.render.BitmapTextView;
import flaxen.render.EmitterView;
import flaxen.render.View;

import flaxen.node.ViewNode;
import flaxen.node.DisplayNode;

import flaxen.component.Display;

class RenderingSystem extends FlaxenSystem
{
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
		HXP.scene.remove(node.display.view);
	}

	override public function update(_)
	{
		updateViews(BackdropNode, BackdropView);
		updateViews(GridNode, GridView);
		updateViews(ImageNode, ImageView);
		updateViews(AnimationNode, AnimationView);
		updateViews(TextNode, TextView);
		updateViews(BitmapTextNode, BitmapTextView);
		updateViews(EmitterNode, EmitterView);
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
	 		{
	 			var view:View = Type.createInstance(viewClass, [entity]);
				HXP.scene.add(view);
				display = new Display(view);
				entity.add(display);
				// trace("Adding a display node to entity " + entity.name);
	 		}
	 		else display = entity.get(Display);

	 		// Update the view
	 		display.view.nodeUpdate();

	 		// Damn view blew up the whole entity!
	 		if(display.destroyEntity)
	 			ash.removeEntity(entity);
		}
	}	
}