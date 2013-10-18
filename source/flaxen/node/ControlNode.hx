package flaxen.node;

import ash.core.Node;

import flaxen.component.Control;

class FireControlNode extends Node<FireControlNode>
{
	public var control:FireControl;
}

class MenuControlNode extends Node<MenuControlNode>
{
	public var control:MenuControl;
}

class CreditsControlNode extends Node<CreditsControlNode>
{
	public var control:CreditsControl;
}

class ProfileControlNode extends Node<ProfileControlNode>
{
	public var control:ProfileControl;
}

class LevelEndControlNode extends Node<LevelEndControlNode>
{
	public var control:LevelEndControl;
}

class EditorControlNode extends Node<EditorControlNode>
{
	public var control:EditorControl;
}

class EditControlNode extends Node<EditControlNode>
{
	public var control:EditControl;
}

class PopupControlNode extends Node<PopupControlNode>
{
	public var control:PopupControl;
}
