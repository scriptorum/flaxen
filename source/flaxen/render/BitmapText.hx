/**
	BitmapText

	TODO:
	 - Add HorizontalTextAlign.Full support
	 - Move glyph creation and style characteristics to BitmapFont class. Allow 
	   user to pass that in for the font in addition to path/BitmapData.

	HaxePunk Example:
		var t = "I'm typing a really long line! ";
		var e = new com.haxepunk.Entity(320, 240);
		e.graphic = new flaxen.render.BitmapText("art/impact20yellow.png", 0, 0,
			"AAABBBCCC Hi there!" + t + t + t + t + t + t + t + t + t + t, 	
			640, 480, true, Center, Center, -4, -2);
		com.haxepunk.HXP.scene.add(e);

	ALSO SEE:
	 - Solar has also put together his own bitmap text class you might like:
	 	http://dl.dropboxusercontent.com/u/28629176/gamedev/crappyretrogame/hw_bmptext/BitmapText.hx
	 	http://forum.haxepunk.com/index.php?topic=334.0
*/

package flaxen.render;

import flaxen.util.StringUtil;
import flaxen.core.Log;
import flaxen.common.TextAlign;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import com.haxepunk.RenderMode;
import com.haxepunk.graphics.Image;
import com.haxepunk.graphics.atlas.Atlas;

class BitmapText extends Image
{
	// Supply your own charset to indicate the characters in your fontBitmap text image and their order
	public static inline var ASCII_CHAR_SET:String = 
		"!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
	private static inline var SPACE_EM_DIVISOR:Int = 3; // Space is 1/3rd width of the "em" character
	private static inline var SPACE_CHAR:String = " ";
	private static inline var FLASH8_DIM_LIMIT:Int = 2880; // Flash 8 w/h
	private static inline var FLASH_DIM_LIMIT:Int = 8191; // Flash 9 or later w/h
	private static inline var FLASH_SIZE_LIMIT:Int = 16777215; // Flash 9 or later total size
	private static inline var FLASH_SAFE_DIM:Int = 4096; // Flash 9 or later total w/h
	private static var fontCache:Map<BitmapData, Map<String, Rectangle>>; // font cache

	private var space:Dynamic; // defines the em character, usually M; could also be width in px
	private var charSet:String; // characters that map to the bitmap font
	private var kerning:Int; // extra +/- space between characters
	private var leading:Int; // extra +/- space between lines
	private var contentWidth:Int; // The final size of the text box
	private var contentHeight:Int;
	private var maxWidth:Int; // The max size of the text box (or 0 for no limit)
	private var maxHeight:Int;
	private var wordWrap:Bool = false;
	private var spaceWidth:Int = 0; // Width of space char, or all chars if monospace
	private var monospace:Bool;
	private var text:String;
	private var lines:Array<String>;
	private var lineWidths:Array<Int>;
	private var halign:HorizontalTextAlign;
	private var valign:VerticalTextAlign;
	private var baseline:Int; 
	private var fontBitmap:BitmapData; // font fontBitmap
	private var content:BitmapData; // content fontBitmap
	private var glyphs:Map<String,Rectangle>;

/**
	Creates a new BitmapText object.
	@param image The bitmap font image. This should be a graphic with a one-line string, 
		containing all the characters of the charSet, with at least one vertical line of 
		blank space between each character.
	@param x,y The registration point for the text (i.e., the upper left corner for Left 
		justification and baseline = 0).
	@param width,height If nonzero, specifies the maximum dimensions of the text box. 
		Clips text that exceeds max. If zero, the dimensions are adjusted to fit the text.
	@param halign Specifies horizontal alignment and registration point. Defaults to Left.
	@param valign Specifies vertical alignment and registration point. Defaults to Top. 
		Baseline requires positive baseline.
	@param wordWrap Specifies whether to wrap long lines to fit into the text box. 
		Requires non-zero width.
	@param text The text message to show. This message can be changed with setText(). 
		Newline (\n) characters in the text causes a line break.
	@param baseline Defines the baseline offset. Only used if valign is set to Baseline. 
		A positive value B sets the vertical registration point to B pixels up from the 
		bottom of the text box. This is really the "descender height."
	@param leading Horizontal padding in between lines. Can be zero, positive, or negative.
	@param kerning Vertical padding in BETWEEN characters. Can be zero, positive, or negative.
		In a monospaced font, kerning is added to ALL characters.
	@param space Defines the widest (em) character or space width. Either supply an integer
		width, or supply a character. If a character is supplied, the space width will be one 
		third of the width of that character (the em character). Defaults to M which is 
		generally the widest character. If M is not in the charSet, you should change this.
		If monospace is true, all characters are forced into this width.
	@param monospace If true, uses the space width as the same width for all characters.
		If using horitonzal centering, chars will only line up vertically if the line lengths
		are all even or all odd.
	@param charSet The list of characters found in the bitmap font image from left to right. 
		Omit the "space" character.
*/
	public function new(image:Dynamic, x:Int = 0, y:Int = 0, ?text:String, 
		width:Int = 0, height:Int = 0, wordWrap:Bool = false, 
		?halign:HorizontalTextAlign, ?valign:VerticalTextAlign, 
		leading:Int = 0, kerning:Int = 0, baseline:Int = 0, 
		space:Dynamic = "M", monospace:Bool = false, ?charSet:String)
	{
		fontBitmap = (Std.is(image, BitmapData) ? image : com.haxepunk.HXP.getBitmap(image));
		if(fontBitmap == null)
			Log.error("Cannot parse null fontBitmap");

		this.text = (text == null ? "" : text);

		if(width < 0 || height < 0)
			Log.error("Text dimensions must be positive or zero");
		maxWidth = width;
		maxHeight = height;
		this.wordWrap = wordWrap;
		this.halign = (halign == null ? Left : halign);
		this.valign = (valign == null ? Top : valign);

		if(wordWrap && width == 0)
			Log.error("Word Wrap requires a positive width");
		if(valign == Baseline && baseline < 0)
			Log.error("Baseline cannot be negative");
		if(valign == Baseline && baseline == 0)
			Log.warn("Baseline ineffective; should be a positive value");

		this.space = space;
		if(Std.is(space, Int))
			spaceWidth = cast space;
		this.monospace = monospace;
		this.charSet = (charSet == null ? ASCII_CHAR_SET : charSet);
		this.kerning = kerning;
		this.leading = leading;
		this.baseline = baseline;

		updateGlyphs();
		setTextInternal(text, false);

		super(content); // Can't call super until we've created the content bitmap

		this.x = x; // Can't set position until super is called
		this.y = y;
	}

	public function setText(text:String): BitmapText
	{
		return setTextInternal(text, true);
	}

	private function setTextInternal(text:String, updateSuper:Bool): BitmapText
	{
		this.text = (text == null ? "" : text);
		lines = new Array<String>();
		lineWidths = new Array<Int>();
		contentWidth = 0;	

		for(line in StringUtil.split(text, "\n").iterator())
		{
			if(wordWrap) // wordWrap lines
			{
				for(subLine in applyWordWrap(line))
					addLine(subLine);
			}
			else addLine(line);
		}

		// Determine content height
		contentHeight = lines.length * fontBitmap.height + 
			(lines.length > 1 ? (lines.length - 1) * leading : 0);

		// Enforce size constraints
		if(maxWidth > 0 && maxWidth < contentWidth)
			contentWidth = maxWidth;
		if(maxHeight > 0 && maxHeight < contentHeight)
			contentHeight = maxHeight;

		// Recreate content bitmap
		updateContent();

		// If post-constructor, force parent Image to update as well
		if(updateSuper)
		{
			if (blit)
	    	{
	    		_sourceRect = content.rect;
	    		_source = content;
	    		createBuffer();
	    		updateBuffer();
	    	}
	    	else
	    	{
	    		_region = Atlas.loadImageAsRegion(content);
	    		_sourceRect = new Rectangle(0, 0, _region.width, _region.height);
	    	}
		}

		return this;
	}

	private inline function addLine(line:String)
	{
		this.lines.push(line);
		var lineWidth = getTextWidth(line);
		lineWidths.push(lineWidth); // needed for calculating right/center offset

		// Determine content width
		if(lineWidth > contentWidth)
			contentWidth = lineWidth;
	}

	public function applyWordWrap(text:String): Array<String>
	{
		var lineWidth = 0;
		var line:String = "";
		var lines = new Array<String>();
		for(word in StringUtil.split(text, SPACE_CHAR).iterator())
		{	
			var wordWidth = getTextWidth(word);
			if(lineWidth == 0)  // first word of text
			{
				line = word;
				lineWidth = wordWidth;
			}
			else if(lineWidth + spaceWidth + wordWidth > maxWidth) // wordWrap line
			{
				lines.push(line);
				line = word;
				lineWidth = wordWidth;
			}
			else // Add word to line, no word wrap
			{
				line += SPACE_CHAR + word;
				lineWidth += spaceWidth + wordWidth;
			}
		}
		lines.push(line);
		return lines;
	}

	// Gets the kerned width of a single line of text
	// Does not properly handle newlines
	public function getTextWidth(text:String): Int
	{
		var width = 0;
		var charIndex:Int = 1;
		for(ch in StringUtil.split(text,"").iterator())
		{
			width += getCharWidth(ch);
			if(ch == SPACE_CHAR)
				charIndex = 0;
			if(charIndex++ >= 2) // skip kerning for spaces and the first character of each word
				width += kerning;
		}
		return width;
	}

	// Gets the width of the specific character, does not include kerning
	public function getCharWidth(ch:String): Int
	{
		if(ch == SPACE_CHAR || monospace)
			return spaceWidth;

		var glyph:Rectangle = getGlyph(ch);
		if(glyph == null)
		{
			Log.warn("Glyph '" + ch + "'' not found (code:" + ch.charCodeAt(0) + ")");
			return 0;
		}

		return Std.int(glyph.width);
	}

	public function getGlyph(ch:String): Rectangle
	{
		return glyphs.get(ch);
	}

	// Scan bitmap font image to determine size and position of each glyph/character
	private function updateGlyphs()
	{
		// Initialize font cache
		if(fontCache == null)
			fontCache = new Map<BitmapData, Map<String, Rectangle>>();

		// Look for fontBitmap in font cache
		else glyphs = fontCache.get(fontBitmap); 

		// New font cache or glyphs not found in cache, generate new font glyphs
		if(glyphs == null)
		{
			// Create new set of character glyphs and add to font cache
			glyphs = new Map<String,Rectangle>();
			fontCache.set(fontBitmap, glyphs);

			// Populate glyphs with 
			var seekingCharStart:Bool = true;
			var startX:Int = 0; // start of letter
			var x:Int = 0;
			var glyphsExpected:Int = charSet.length;
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

					else if(blankLine || x == (fontBitmap.width - 1))
					{
						seekingCharStart = true;
						var glyphWidth = x - startX; // Glyph width without kerning
						glyphs.set(ch, new Rectangle(startX, 0, glyphWidth, fontBitmap.height));
						glyphsExpected--;
						break; // Move to next character
					}

					x++;
				}
			}

			// Throw warnings for wrong number of glyphs
			if(glyphsExpected != 0)
				Log.warn("Gylphs are missing; expected " + glyphsExpected + " more glyphs in the bitmap.");

			// Store glyphs in font cache
			fontCache.set(fontBitmap, glyphs);
		}

		// Determine space width if none was specified
		if(Std.is(space, String))
		{
			var w = getCharWidth(space);
			spaceWidth = (monospace ? w : Std.int(Math.max(1, w / SPACE_EM_DIVISOR)));
		}

		if(spaceWidth <= 0)
			Log.error("Error determining space width");

		// When monospaced, apply kerning to ALL characters
		if(monospace)
		{
			spaceWidth += kerning;
			kerning = 0;
		}
	}	

	// Draw text onto content buffer which gets passed to Image
    private function updateContent()
    {
    	if(contentWidth < 1) contentWidth = 1;
    	if(contentHeight < 1) contentHeight = 1;

    	// Limit bitmap dimensions based on Flash size limitations
    	#if flash
	        #if flash8
	        	if(contentWidth > FLASH8_DIM_LIMIT) contentWidth = FLASH8_DIM_LIMIT;
	        	if(contentHeight > FLASH8_DIM_LIMIT) contentHeight = FLASH8_DIM_LIMIT;
	        #else
	        	// TODO Check size limit first; if failed, calc longest dimension, 
	        	// reduce that to FLASH_DIM_LIMIT and scale other dim so that size
	        	// stays under FLASH_SIZE_LIMIT
	        	if(contentWidth > FLASH_DIM_LIMIT) contentWidth = FLASH_DIM_LIMIT;
	        	if(contentHeight > FLASH_DIM_LIMIT) contentHeight = FLASH_DIM_LIMIT;
	        	if(contentWidth * contentHeight > FLASH_SIZE_LIMIT) 
		        	contentWidth = contentHeight = FLASH_SAFE_DIM;
	        #end
		#end


    	// TODO erase old bitmap if size hasn't changed, instead of constructing a new one
    	content = com.haxepunk.HXP.createBitmap(contentWidth, contentHeight, true);

    	com.haxepunk.HXP.point.y = 0;
    	for(i in 0...lines.length)
    	{
    		com.haxepunk.HXP.point.x = switch(halign)
    		{
    			case Right: contentWidth - lineWidths[i];
    			case Center: (contentWidth - lineWidths[i]) / 2;
    			default: 0;
    		};

    		var charIndex:Int = 1;
    		for(ch in lines[i].split(""))
    		{
    			if(ch == SPACE_CHAR)
    			{
    				com.haxepunk.HXP.point.x += spaceWidth; // Do not add kerning to spaces
    				charIndex = 1;
    			}
    			else
    			{
    				if(charIndex++ >= 2)
    					com.haxepunk.HXP.point.x += kerning;

	    			var glyph:Rectangle = getGlyph(ch);
	    			if(glyph != null)
	    			{
	    				content.copyPixels(fontBitmap, glyph, com.haxepunk.HXP.point, null, null, true);
    					com.haxepunk.HXP.point.x += (monospace ? spaceWidth : glyph.width);
    				}
    			}
    		}

    		com.haxepunk.HXP.point.y += fontBitmap.height + leading;
    	}
    }

	override public function renderAtlas(layer:Int, point:Point, camera:Point)
	{
    	super.renderAtlas(layer, adjustPoint(point), camera);
	}

    override public function render(target:BitmapData, point:Point, camera:Point)
    {
    	super.render(target, adjustPoint(point), camera);
    }

    // Adjust the render point based on the alignment and scaling of the text box
    private function adjustPoint(point:Point): Point
    {
    	// Adjust horizontal registration point
    	if(halign == Center)
    		point.x -= contentWidth * scaleX / 2;
    	else if(halign == Right)
    		point.x -= contentWidth * scaleX; 

    	// Adjust vertical registration point
    	if(valign == Center)
    		point.y -= contentHeight * scaleY / 2;
    	else if(valign == Bottom)
    		point.y -= contentHeight * scaleY;
    	else if(valign == Baseline)
    		point.y -= (contentHeight - baseline) * scaleY;

    	return point;
    }
}