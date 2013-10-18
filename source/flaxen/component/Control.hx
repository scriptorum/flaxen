package flaxen.component;

class Control
{
	public function new()
	{
	}
}

class FireControl extends Control // Can fire barrel
{
	public static var instance:Control = new FireControl();
}

class ProfileControl extends Control // Can display profile stats
{
	public static var instance:Control = new ProfileControl();
}

class MenuControl extends Control // Can click new/continue
{
	public static var instance:Control = new MenuControl();
}

class CreditsControl extends Control 
{
	public static var instance:Control = new CreditsControl();
}

class LevelEndControl extends Control // Can click continue/replay
{
	public static var instance:Control = new LevelEndControl();
}

class EditorControl extends Control // Can toggle editor mode
{
	public static var instance:Control = new EditorControl();
}

class EditControl extends Control // Can edit level
{
	public static var instance:Control = new EditControl();
}

class PopupControl extends Control // Can edit level
{
	public static var instance:Control = new PopupControl();
}

class GameEndControl extends Control // Can edit level
{
	public static var instance:Control = new GameEndControl();
}

class LevelEndingControl extends Control // Can edit level
{
	public static var instance:Control = new LevelEndingControl();
}

class RocketingControl extends Control // Can edit level
{
	public static var instance:Control = new RocketingControl();
}


