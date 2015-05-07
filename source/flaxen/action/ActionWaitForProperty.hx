package flaxen.action;

/**
 * Waits for the specified property of the specified object to turn the 
 * specified value. Specifically.
 */
class ActionWaitForProperty extends Action
{
	public var object:Dynamic;
	public var property:String;
	public var value:Dynamic;

	public function new(object:Dynamic, property:String, value:Dynamic)
	{
		super();
		this.object = object;
		this.property = property;
		this.value = value;
	}

	override public function execute(): Bool
	{
		return (Reflect.getProperty(object, property) == value);
	}

	override public function toString(): String
	{
		return "ActionWaitForProperty (object:" + object + " property:" + property + " value:" + value + ")";
	}
}