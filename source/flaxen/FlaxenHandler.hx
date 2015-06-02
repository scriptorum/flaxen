package flaxen;

typedef ModeCallback = Void -> Void; // can access f/flaxen variable in closure

class FlaxenHandler
{
	public var f:Flaxen;
	public var flaxen:Flaxen;

	public function new(flaxen:Flaxen)
	{
		this.f = this.flaxen = flaxen;
	}

	public function start()
	{
	}

	public function stop()
	{
	}
	
	public function update()
	{
	}
}