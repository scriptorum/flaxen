// BitmapText
// Also see the the work of solar:
//  http://dl.dropboxusercontent.com/u/28629176/gamedev/crappyretrogame/hw_bmptext/BitmapText.hx
//  http://forum.haxepunk.com/index.php?topic=334.0
//
// TODO:
//  * Add caching of rects so you don't have to rescan font bitmap every time you add new text
//
// USAGE:
//    image - The bitmap font image. This should be a graphic with a one-line string,
//			  containing all the characters of the charSet, with at least one vertical
//			  line of blank space between each character.
//	    x/y - The registration point for the text (i.e., the upper left corner for
// 			  Left justification and baseline = 0).
//	 width/ - If nonzero, specifies the maximum dimensions of the text box. Width is 
//   height   required if wordWrap is enabled. If zero, the dimensions are adjusted to 
//			  fit the text.
//    align - Specifies left/center/right alignment and whether to use line word-wordWrapping.
//			  If word-wrapping, width/height must be supplied non-zero. Left alignment
// 			  uses a registration mark in the upper left corner of the text box. 
//            Center/Right change the registration point to the upper-middle/upper-right 
//            of the box.
//     text - The text message to put on the screen. This message can be changed with 
// 			  setText(). The text can have \n characters in it to indicate multiple lines.
// baseline - Defines the baseline offset. Normally the registration point is at the top of the
//		      text box. A positive baseline alters the Y value downward, generally
//            to align it with the baseline of the text on the first line.
//	leading - Horizontal padding in between lines. Can be positive or negative.
//  kerning - Vertical padding in between characters. Can be positive or negative.
//  charSet - The list of characters found in the bitmap font image from left to right.
//            Omit space.
//   emChar - Defines the em character, which should be the widest character in the charSet.
//            Usually this is the letter M. This field is only used to calculate the width
//            of a space caracter (one third of the em character's width).
//


package flaxen.render;

import flaxen.util.StringUtil;
import flaxen.common.TextAlign;
import flash.display.BitmapData;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import com.haxepunk.HXP;
import com.haxepunk.RenderMode;
import com.haxepunk.graphics.Image;
import com.haxepunk.graphics.atlas.TextureAtlas;
import com.haxepunk.graphics.atlas.AtlasRegion;

class BitmapText extends Image
{
	// Supply your own charset to indicate the characters in your fontBitmap text image and their order
	public static var ASCII_CHAR_SET:String = 
		"!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
	public static var SPACE_EM_DIVISOR:Int = 3; // Space is 1/3rd width of the "em" character

	private var emChar:String; // defines the em character, usually M
	private var charSet:String; // characters that map to the bitmap font
	private var kerning:Int; // extra +/- space between characters
	private var leading:Int; // extra +/- space between lines
	private var contentWidth:Int = 0;
	private var contentHeight:Int = 0;
	private var fixedWidth:Bool;
	private var fixedHeight:Bool;
	private var wordWrap:Bool = false;
	private var spaceWidth:Int = 10; // If no emChar provided, this is just a crappy default
	private var text:String;
	private var lines:Array<String>;
	private var lineWidths:Array<Int>;
	private var align:TextAlign;
	private var baseline:Int; 
	private var fontBitmap:BitmapData; // font fontBitmap
	private var content:BitmapData; // content fontBitmap
	private var glyphs:Map<String,Rectangle>;

	public function new(image:Dynamic, x:Int = 0, y:Int = 0, width:Int = 0, height:Int = 0, 
		?text:String, ?align:TextAlign, wordWrap:Bool = false, baseline:Int = 0, 
		leading:Int = 0, kerning:Int = 0, ?charSet:String, emChar:String = "M")
	{
		this.emChar = emChar;
		this.charSet = (charSet == null ? ASCII_CHAR_SET : charSet);
		this.kerning = kerning;
		this.leading = leading;
		this.baseline = baseline;
		this.wordWrap = wordWrap;
		this.text = (text == null ? "" : text);
		this.align = (align == null ? Left : align);

		if(width < 0 || height < 0)
			throw "Text dimensions must be positive or zero";
		contentWidth = width;
		contentHeight = height;
		fixedWidth = width > 0;
		fixedHeight = height > 0;
		if(wordWrap && !fixedWidth)
			throw "Word Wrap requires a positive width";
		this.x = x;
		this.y = y;

		_blit = !HXP.renderMode.has(RenderMode.HARDWARE);
		glyphs = new Map<String,Rectangle>();
		fontBitmap = (Std.is(image, BitmapData) ? image : HXP.getBitmap(image));
		if(fontBitmap == null)
			throw "Cannot parse null fontBitmap";

		updateGlyphs();
		setTextSuper(text, false);

		super(content);
	}

	public function setText(text:String): BitmapText
	{
		return setTextSuper(text, true);
	}

	private function setTextSuper(text:String, updateSuper:Bool): BitmapText
	{
		this.text = text;
		lines = new Array<String>();
		lineWidths = new Array<Int>();
		if(!fixedWidth) contentWidth = 0;	

		for(line in StringUtil.split(text, "\n").iterator())
		{
			if(wordWrap) // wordWrap lines
			{
				for(subLine in applyWordWrap(line))
					addLine(subLine);
			}
			else addLine(line);
		}

		if(!fixedHeight)
			contentHeight = lines.length * fontBitmap.height + 
				(lines.length > 0 ? (lines.length - 1) * (fontBitmap.height + leading) : 0);

		trace("FixedHeight:" + (fixedHeight ? "Y" :"N") + " contentHeight:" + contentHeight);

		updateContent();

		if(updateSuper)
		{
	    	setBitmapSource(content);
	    	updateBuffer();
		}

		return this;
	}

	private inline function addLine(line:String)
	{
		this.lines.push(line);
		var lineWidth = getTextWidth(line);
		if(!fixedWidth && lineWidth > contentWidth)
			contentWidth = lineWidth;
		lineWidths.push(lineWidth); // needed for calculating right/center offset
	}

	public function applyWordWrap(text:String): Array<String>
	{
		var lineWidth = 0;
		var line:String = "";
		var lines = new Array<String>();
		for(word in StringUtil.split(text, " ").iterator())
		{	
			var wordWidth = getTextWidth(word);
			if(lineWidth == 0)  // first word of text
			{
				line = word;
				lineWidth = wordWidth;
			}
			else if(lineWidth + spaceWidth + wordWidth > contentWidth) // wordWrap line
			{
				lines.push(line);
				line = word;
				lineWidth = wordWidth;
			}
			else // Add word to line, no word wrap
			{
				line += " " + word;
				lineWidth += spaceWidth + wordWidth;
			}
		}
		lines.push(line);
		return lines;
	}

	public function getTextWidth(text:String): Int
	{
		var width = 0;
		var addKerning = false;
		for(ch in text.split(""))
		{
			width += getCharWidth(ch);			
			if(addKerning)
				width += kerning;
			else addKerning = true;
		}
		return width;
	}

	// Gets the width of the specific character, does not include kerning
	public function getCharWidth(ch:String): Int
	{
		if(ch == " ")
			return spaceWidth;

		var glyph:Rectangle = getGlyph(ch);
		if(glyph == null)
		{
			#if flaxenDebug
				trace("Glyph " + ch + " not found");
			#end
			return 0;
		}

		return Std.int(glyph.width);
	}

	public function getGlyph(ch:String): Rectangle
	{
		return glyphs.get(ch);
	}

	public function updateGlyphs()
	{
		var seekingCharStart:Bool = true;
		var startX:Int = 0; // start of letter
		var x:Int = 0;
		for(ch in charSet.split(""))
		{	
			while(x < fontBitmap.width)
			{
				var blankLine:Bool = true;
				for(y in 0...fontBitmap.height)
				{
					var pix = fontBitmap.getPixel32(x,y);
					if((pix >> 24) != 0)
					{
						blankLine = false;
						break;						
					}
				}

				if(seekingCharStart)
				{
					if(!blankLine)
					{
						startX = x;
						seekingCharStart = false;
					}
				}
				else if(blankLine)
				{
					seekingCharStart = true;
					var glyphWidth = x - startX;
					glyphs.set(ch, new Rectangle(startX, 0, glyphWidth, fontBitmap.height));

					if(ch == emChar)
						spaceWidth = Std.int(Math.max(1, glyphWidth / SPACE_EM_DIVISOR));

					break; // Move to next character
				}

				x++;
			}
		}
	}	

	// Draw text onto content buffer which gets passed to Image
    public function updateContent()
    {
    	if(contentWidth < 1) contentWidth = 1;
    	if(contentHeight < 1) contentHeight = 1;

    	// TODO clear old bitmap if size hasn't changed
    	trace("Creating new bitmap with dimensions:" + contentWidth + "x" + contentHeight);
    	content = HXP.createBitmap(contentWidth, contentHeight, true);

    	HXP.point.x = 0;
    	HXP.point.y = 0;    
    	for(line in lines)
    	{
    		for(ch in line.split(""))
    		{
    			if(ch == " ")
    			{
    				HXP.point.x += spaceWidth + kerning;
    				continue;
    			}

    			var glyph:Rectangle = getGlyph(ch);
    			content.copyPixels(fontBitmap, glyph, HXP.point);
    			HXP.point.x += glyph.width + kerning;
    		}
    		HXP.point.x = 0;
    		HXP.point.y += fontBitmap.height + leading;
    	}
    }

    public override function render(target:BitmapData, point:Point, camera:Point)
    {
    	// Adjust registration point for center/right alignment and baseline offset
    	if(align == Center)
    		point.x -= contentWidth / 2;
    	else if(align == Right)
    		point.x -= contentHeight;
    	this.y -= baseline;

    	super.render(target, point, camera);
    }
}