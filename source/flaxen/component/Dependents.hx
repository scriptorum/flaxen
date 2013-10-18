package flaxen.component;

class Dependents
{
	public var names:Array<String>; // dependent entity names

	public function new()
	{
		clear();
	}

	public function add(entityName:String): Void
	{
		names.push(entityName);
	}

	public function remove(entityName:String): Void
	{
		names.remove(entityName);
	}

	public function clear(): Void
	{
		this.names = new Array<String>();
	}
}