// Also see the the work of solar:
//  http://dl.dropboxusercontent.com/u/28629176/gamedev/crappyretrogame/hw_bmptext/BitmapText.hx
//  http://forum.haxepunk.com/index.php?topic=334.0

package flaxen.render;

import flaxen.util.StringUtil;
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

enum BitmapTextJustify { Left; Center; Right; }

class BitmapText extends Image
{
	// Supply your own charset to indicate the characters in your fontBitmap text image and their order
	public static var ASCII_CHAR_SET:String = 
		"!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
	public static var SPACE_EM_DIVISOR:Int = 3;

	// TODO Add a cache of atlases and rect sources created here so we don't 
	// Have to regenerate them each time
	//	private static var atlasCache:Map<BitmapData, Map<String,Rectangle>>;

	private var emChar:String; // M character, used to calculate space width
	private var charSet:String;
	private var kerning:Int;
	private var leading:Int;
	private var wrapWidth:Int;
	private var contentWidth:Int = 0;
	private var contentHeight:Int = 0;
	private var spaceWidth:Int = 10; // If no emChar provided, this is just a crappy default
	private var text:String;
	private var lines:Array<String>;
	private var lineWidths:Array<Int>;
	private var align:BitmapTextJustify;
	private var fontBitmap:BitmapData; // font fontBitmap
	private var content:BitmapData; // content fontBitmap
	private var glyphs:Map<String,Rectangle>;

	public function new(image:Dynamic, x:Int = 0, y:Int = 0, ?align:BitmapTextJustify, 
		?text:String, wrapWidth:Int = 0, leading:Int = 0, kerning:Int = 0, 
		?charSet:String, emChar:String = "M")
	{
		this.emChar = emChar;
		this.charSet = (charSet == null ? ASCII_CHAR_SET : charSet);
		this.kerning = kerning;
		this.leading = leading;
		this.wrapWidth = wrapWidth;
		this.text = (text == null ? "" : text);
		this.align = align;
		this.y = y;
		this.x = x;

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
		contentWidth = 0;

		for(line in StringUtil.split(text, "\n").iterator())
		{
			if(wrapWidth > 0) // wrap lines
			{
				for(subLine in wrapText(line))
					addLine(subLine);
			}
			else addLine(line);
		}

		contentHeight = lines.length * fontBitmap.height + 
			(lines.length > 0 ? (lines.length - 1) * (fontBitmap.height + leading) : 0);

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
		if(lineWidth > contentWidth)
		contentWidth = lineWidth;
		lineWidths.push(lineWidth); // needed for calculating right/center offset
	}

	public function wrapText(text:String): Array<String>
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
			else if(lineWidth + spaceWidth + wordWidth > wrapWidth) // wrap line
			{
				lines.push(line);
				line = word;
				lineWidth = wordWidth;
			}
			else // Add word to line, no wrap
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
}