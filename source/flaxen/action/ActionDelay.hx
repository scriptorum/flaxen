package flaxen.action;

import flaxen.component.Timestamp;

/**
 * Waits duration seconds.
 */
class ActionDelay extends Action
{
	public var duration:Float;

	public function new(duration:Float) // in seconds
	{
		super();
		this.duration = duration;
	}

	private var time:Float = -1;
	override public function execute(): Bool
	{
		if(time == -1)
		{
			time = Timestamp.now();
			return false;
		}

		return (Timestamp.now() - time) >= duration * 1000;
	}

	override public function toString(): String
	{
		return "ActionDelay (duration:" + duration + ")";
	}
}