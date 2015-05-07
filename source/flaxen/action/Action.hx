package flaxen.action;

/**
 * A superclass for an Action definition. Generally you don't need to mess 
 * with Action objects directly. The convenience methods in `ActionQueue` 
 * will create these actions for you. However if you wanted to add your own 
 * custom Action, this is what you would subclass.
 */
class Action
{
	public var next:Action;

	private function new()
	{
	}

	/**
	 * The execute method should return true if the action is complete. If it 
	 * is still processing or waiting for something, return false. This should
	 * generally be true unless this is a waitForXXX kind of action.
	 */
	public function execute(): Bool
	{
		return true;
	}

	public function toString(): String
	{
		return "Action";
	}
}