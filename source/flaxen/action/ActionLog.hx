package flaxen.action;

/**
 * Logs a message.
 */
class ActionLog extends Action
{
	public var message:String;

	public function new(message:String)
	{
		super();
		this.message = message;
	}

	override public function execute(): Bool
	{
		flaxen.Log.log(message);
		return true;
	}

	override public function toString(): String
	{
		return "ActionLog (message:" + message + ")";
	}
}
