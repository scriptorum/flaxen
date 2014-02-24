package flaxen.component;

class Rotation
{
	public var angle:Float;

	public function new(angle:Float)
	{
		this.angle = angle;
	}

	public function clone(): Rotation
	{
		return new Rotation(angle);
	}

	public function matches(o:Rotation): Bool
	{
		if(o == null)
			return false;
		return (o.angle == angle);
	}

	public static function safeClone(o:Rotation): Rotation
	{
		return (o == null ? null : o.clone());
	}

	public static function match(o1:Rotation, o2:Rotation): Bool
	{
		if(o1 == o2)
			return true;
		if(o1 == null)
			return false;
		return (o1.matches(o2));
	}

	public static function random(): Rotation
	{
		return new Rotation(Math.random() * 360);
	}

	public static function zero(): Rotation
	{
		return new Rotation(0);
	}

	public static function full(): Rotation
	{
		return new Rotation(360);
	}

}