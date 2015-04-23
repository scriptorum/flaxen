package flaxen.component;

import flaxen.common.TextAlign;

/**
 * For BitmapText supply an Image component as well; Size component may also be used to 
 * clip text box dimensions and do word wrapping. The presentation of the text can be
 * customized with a TextStyle component.
 */
class Text
{
	public var message:String;

	public function new(message:String)
	{
		this.message = message;
	}
}

/**
 * Customizes the appearance of a Text component. For convenience, create a new TextStyle
 * using createTTF() for a regular TTF text (no Image), and createBitmap() for BitmapText (with Image).
 */
class TextStyle 
{
	/**
	 * These options work only for TTF Text
	 */
	public var font:String;
	public var color:Int = 0xFFFFFF; 
	public var size:Int = 14;
	public var shadowColor:Int = 0x000000;
	public var shadowOffset:Int = 2;

	/**
	 * These options work only for Bitmap Text
	 */
	public var valign:VerticalTextAlign;
	public var baseline:Int;
	public var kerning:Int;
	public var charSet:String; 
	public var space:Dynamic;
	public var monospace:Bool;

	/**
	 * These options work for both BitmapText and TTF Text
	 */
	public var halign:HorizontalTextAlign;
	public var leading:Int = 0;
	public var wordWrap:Bool; // requires a Size component
	public var changed:Bool = true; // must set to true to recognize changed style options

	public function new()
	{		
	}

	/**
	 * Convenience method for creating a new TextStyle for regular Text
	 */
	public static function createTTF(color:Int = 0xFFFFFF, size:Int = 14, ?font:String, 
		?halign:HorizontalTextAlign, wordWrap:Bool = false, leading:Int = 0)
	{
		var style = new TextStyle();
		style.color = color;
		style.size = size;
		style.font = font;
		style.halign = (halign == null ?  HorizontalTextAlign.Left : halign);
		style.wordWrap = wordWrap;
		style.leading = leading;
		return style;
	}

	/**
	 * Convenience method for creating a new TextStyle for BitmapText
	 * TODO Swap params
	 */
	public static function createBitmap(wordWrap:Bool = false, 
		?halign:HorizontalTextAlign, ?valign:VerticalTextAlign, 
		leading:Int = 0, kerning:Int = 0, baseline:Int = 0,
		?space:Dynamic, monospace:Bool = false, ?charSet:String)
	{
		var style = new TextStyle();
		style.halign = (halign == null ?  HorizontalTextAlign.Left : halign);
		style.valign = (valign == null ?  VerticalTextAlign.Top : valign);
		style.wordWrap = wordWrap;
		style.leading = leading;
		style.kerning = kerning;
		style.baseline = baseline;
		style.space = space;
		style.monospace = monospace;
		style.charSet = charSet;
		return style;
	}

}
