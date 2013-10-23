package flaxen.node;

import ash.core.Node;
import flaxen.component.Repeating;
import flaxen.component.Image;
import flaxen.component.Animation;
import flaxen.component.Position;
import flaxen.component.Grid;
import flaxen.component.Text;
import flaxen.component.Tile;
import flaxen.component.Subdivision;
import flaxen.component.Emitter;

class ImageNode extends Node<ImageNode>
{
	public var position:Position;
	public var image:Image;
}

class AnimationNode extends Node<AnimationNode>
{
	public var position:Position;
	public var animation:Animation;
}

class BackdropNode extends Node<BackdropNode>
{
	public var image:Image;
	public var repeating:Repeating;
}

class GridNode extends Node<GridNode>
{
	public var position:Position;
	public var grid:Grid;
	public var image:Image;
	public var subdivision:Subdivision;
}

class TextNode extends Node<TextNode>
{
	public var position:Position;
	public var text:Text;
}

class EmitterNode extends Node<EmitterNode>
{
	public var position:Position;
	public var text:Emitter;
}