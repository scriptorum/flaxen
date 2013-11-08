package flaxen.component;

import com.haxepunk.HXP;

enum TextAlign
{ 
	center; 
	justify;
	left; 
	right;
}

class TextStyle 
{
	// These options work only for TTF Text
	public var color:Int; 
	public var size:Int;
	public var font:String;
	public var shadowColor:Int = 0x000000;
	public var shadowOffset:Int = 2;
	public var leading:Int = 0;
	public var wordWrap:Bool; // requires a Size component TODO:Support BitmapText

	// These options work only for Bitmap Text
	public var charSize:Size; // size of each character

	// These options work for both BitmapText and TTF Text
	public var alignment:TextAlign;
	public var changed:Bool = true; // must set to true to recognize changed style options

	public function new()
	{		
	}

	public static function create(color:Int = 0xFFFFFF, size:Int = 14, ?font:String, 
		?alignment:TextAlign, wordWrap:Bool = false)
	{
		var style = new TextStyle();
		style.color = color;
		style.size = size;
		style.font = (font == null ? HXP.defaultFont : font);
		style.alignment = (alignment == null ?  TextAlign.left : alignment);
		style.wordWrap = wordWrap;
		return style;
	}

	public static function createBitmap(charSize:Size, ?alignment:TextAlign, wordWrap:Bool = false)
	{
		var style = new TextStyle();
		style.alignment = (alignment == null ?  TextAlign.left : alignment);
		style.wordWrap = wordWrap;
		style.charSize = charSize;
		return style;
	}

}

// For BitmapText supply an Image component as well
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