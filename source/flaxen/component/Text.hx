package flaxen.component;

import flaxen.common.TextAlign;

class TextStyle 
{
	// These options work only for TTF Text
	public var color:Int; 
	public var size:Int;
	public var font:String;
	public var shadowColor:Int = 0x000000;
	public var shadowOffset:Int = 2;

	// These options work only for Bitmap Text
	public var baseline:Int;
	public var kerning:Int;
	public var charSet:String; 
	public var emChar:String;

	// These options work for both BitmapText and TTF Text
	public var align:TextAlign;
	public var leading:Int = 0;
	public var wordWrap:Bool; // requires a Size component
	public var changed:Bool = true; // must set to true to recognize changed style options

	public function new()
	{		
	}

	public static function create(color:Int = 0xFFFFFF, size:Int = 14, ?font:String, 
		?align:TextAlign, wordWrap:Bool = false, leading:Int = 0)
	{
		var style = new TextStyle();
		style.color = color;
		style.size = size;
		style.font = font;
		style.align = (align == null ?  TextAlign.Left : align);
		style.wordWrap = wordWrap;
		style.leading = leading;
		return style;
	}

	public static function createBitmap(?align:TextAlign, wordWrap:Bool = false, 
		leading:Int = 0, kerning:Int = 0, baseline:Int = 0,
		?charSet:String, emChar:String = "M")
	{
		var style = new TextStyle();
		style.align = (align == null ?  TextAlign.Left : align);
		style.wordWrap = wordWrap;
		style.leading = leading;
		style.kerning = kerning;
		style.baseline = baseline;
		style.charSet = charSet;
		style.emChar = emChar;
		return style;
	}

}

// For BitmapText supply an Image component as well; Size component may also be used to 
// fix text box dimensions or do word wrapping
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