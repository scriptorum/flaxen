package flaxen.component;

enum TextAlign
{ 
	center; 
	justify;
	left; 
	right;
}

class TextStyle 
{
	public var color:Int;
	public var size:Int;
	public var font:String;
	public var alignment:TextAlign;
	public var wordWrap:Bool;
	public var shadowColor:Int = 0x000000;
	public var shadowOffset:Int = 2;
	public var leading:Int = 0;
	public var changed:Bool = true; // must set to true to recognize changed style options

	public function new(color:Int, size:Int, font:String, ?alignment:TextAlign, wordWrap:Bool = false)
	{
		this.color = color;
		this.size = size;
		this.font = font;
		this.alignment = (alignment == null ?  TextAlign.left : alignment);
		this.wordWrap = wordWrap;
	}
}

class Text
{
	public var message:String;
	public var style:TextStyle;

	public function new(message:String, style:TextStyle = null)
	{
		this.message = message;
		this.style = style;
	}
}