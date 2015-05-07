package flaxen.action;

/**
 * This is similar to ActionCallback, except your function must return false if it's still processing, 
 * or true when it's complete. Use this to execute a thread; the action queue will hold up until your
 * thread indicates it's finished.
 */
class ActionThread extends Action
{
	public var func:Void->Bool;

	public function new(func:Void->Bool)
	{
		super();
		this.func = func;
	}

	override public function execute(): Bool
	{
		return func();
	}

	override public function toString(): String
	{
		return "ActionThread";
	}
}