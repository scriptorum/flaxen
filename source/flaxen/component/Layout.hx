package flaxen.component;

// A layout can be used in addition to position to establish the 0,0 point
// Changing a layout would then move (as a group) all entities using that layout.
// Master Layout represents the position of the main.
class Layout
{
	public var name:String;
	public var current:Position;
	public var portrait:Position;
	public var landscape:Position;
	public function new(name:String, portrait:Position, landscape:Position)
	{
		this.name = name;
		this.current = this.portrait = portrait;
		this.landscape = landscape;
	}

	// You must call setOrientation
	public function setOrientation(portraitOrientation:Bool, layoutOffset:Position)
	{
		current = (portraitOrientation ? portrait : landscape);
		if(layoutOffset != null)
			current = current.clone().add(layoutOffset.x, layoutOffset.y);
	}
}