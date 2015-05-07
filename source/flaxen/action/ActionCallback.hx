package flaxen.action;

/**
 * Calls an arbitrary function.
 */
class ActionCallback extends Action
{
	public var func:Void->Void;

	public function new(func:Void->Void)
	{
		super();
		this.func = func;
	}

	override public function execute(): Bool
	{
		func();
		return true;
	}

	override public function toString(): String
	{
		return "ActionCallback";
	}
}