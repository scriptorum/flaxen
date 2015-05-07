package flaxen.action;

import flaxen.common.Completable;

/**
 * Waits for the complete property of an object to be true.
 */
class ActionWaitForComplete extends Action
{
	public var completable:Completable;

	public function new(completable:Completable)
	{
		super();
		this.completable = completable;
	}

	override public function execute(): Bool
	{
		return completable.complete;
	}

	override public function toString(): String
	{
		return 'ActionWaitForComplete (completable:$completable)';
	}
}