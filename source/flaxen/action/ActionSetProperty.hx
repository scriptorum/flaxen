package flaxen.action;

/**
 * Sets the property of an object to a specific value.
 */
class ActionSetProperty extends Action
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
		Reflect.setProperty(object, property, value);
		return true;
	}

	override public function toString(): String
	{
		return "ActionSetProperty (object:" + object + " property:" + property + " value:" + value + ")";
	}
}
