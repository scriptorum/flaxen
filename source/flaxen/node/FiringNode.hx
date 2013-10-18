package flaxen.node;

import ash.core.Node;

import flaxen.component.Tube;
import flaxen.component.Firing;
import flaxen.component.Rotation;

class FiringNode extends Node<FiringNode>
{
	public var tube:Tube;
	public var firing:Firing;
	public var rotation:Rotation;
}
