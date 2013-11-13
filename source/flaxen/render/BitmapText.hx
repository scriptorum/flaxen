/*
	BitmapText
	Also see the the work of solar:
	 http://dl.dropboxusercontent.com/u/28629176/gamedev/crappyretrogame/hw_bmptext/BitmapText.hx
	 http://forum.haxepunk.com/index.php?topic=334.0

	TODO:
	 * Add caching of rects so you don't have to rescan font bitmap every time you add new text
	 * Add HorizontalTextAlign.Full support


	CONSTRUCTOR:
		image -	The bitmap font image. This should be a graphic with a one-line string,
			  	containing all the characters of the charSet, with at least one vertical
				line of blank space between each character.
		  x/y - The registration point for the text (i.e., the upper left corner for
				Left justification and baseline = 0).
 width/height - If nonzero, specifies the maximum dimensions of the text box. Clips text
 				that exceeds max. If zero, the dimensions are adjusted to fit the text.
	   halign - Specifies horizontal alignment and registration point. Defaults to Left.
	   valign - Specifies vertical alignment and registration point. Defaults to Top. 
	   			Baseline requires positive baseline.
	 wordWrap - Specifies whether to wrap long lines to fit into the text box. Requires 
	 			non-zero width.
	     text - The text message to show. This message can be changed with setText(). 
	     		Newline (\n) characters in the text causes a line break.
	 baseline - Defines the baseline offset. Only used if valign is set to Baseline. 
				A positive value B sets the vertical registration point to B pixels up 
				from the bottom of the text box. This is really the "descender height."
	  leading - Horizontal padding in between lines. Can be zero, positive, or negative.
	  kerning - Vertical padding in between characters. Can be zero, positive, or negative.
	  charSet - The list of characters found in the bitmap font image from left to right.
				You should not include the "space" character.
	   emChar -	Defines the em character, which should be the widest character in the charSet.
				Usually this is the letter M. This field is only used to calculate the width
				of a space caracter (one third of the em character's width).
*/

package flaxen.render;

import flaxen.util.StringUtil;
import flaxen.core.Log;
import flaxen.common.TextAlign;
import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import com.haxepunk.HXP;
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

	private var emChar:String; // defines the em character, usually M
	private var charSet:String; // characters that map to the bitmap font
	private var kerning:Int; // extra +/- space between characters
	private var leading:Int; // extra +/- space between lines
	private var contentWidth:Int; // The final size of the text box
	private var contentHeight:Int;
	private var maxWidth:Int; // The max size of the text box (or 0 for no limit)
	private var maxHeight:Int;
	private var wordWrap:Bool = false;
	private var spaceWidth:Int = 10; // If no emChar provided, this is just a crappy default
	private var text:String;
	private var lines:Array<String>;
	private var lineWidths:Array<Int>;
	private var halign:HorizontalTextAlign;
	private var valign:VerticalTextAlign;
	private var baseline:Int; 
	private var fontBitmap:BitmapData; // font fontBitmap
	private var content:BitmapData; // content fontBitmap
	private var glyphs:Map<String,Rectangle>;

	public function new(image:Dynamic, x:Int = 0, y:Int = 0, ?text:String, 
		width:Int = 0, height:Int = 0, wordWrap:Bool = false, 
		?halign:HorizontalTextAlign, ?valign:VerticalTextAlign, 
		leading:Int = 0, kerning:Int = 0, baseline:Int = 0, 
		?charSet:String, emChar:String = "M")
	{
		glyphs = new Map<String,Rectangle>();
		fontBitmap = (Std.is(image, BitmapData) ? image : HXP.getBitmap(image));
		if(fontBitmap == null)
			throw "Cannot parse null fontBitmap";

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

		this.emChar = emChar;
		this.charSet = (charSet == null ? ASCII_CHAR_SET : charSet);
		this.kerning = kerning;
		this.leading = leading;
		this.baseline = baseline;

		updateGlyphs();
		setTextSuper(text, false);

		super(content); // Can't call super until we've created the content bitmap

		this.x = x; // Can't set position until super is called
		this.y = y;
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
			if (_blit)
	    	{
	    		createBuffer();
	    		setBitmapSource(content);
	    		updateBuffer();
	    	}
	    	else
				setAtlasRegion(Atlas.loadImageAsRegion(content));
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
		if(ch == SPACE_CHAR)
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
					var glyphWidth = x - startX; // Glyph width without kerning
					glyphs.set(ch, new Rectangle(startX, 0, glyphWidth, fontBitmap.height));

					// Determine space width ... no kerning for space
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

    	// TODO clear old bitmap if size hasn't changed
    	content = HXP.createBitmap(contentWidth, contentHeight, true);

    	HXP.point.y = 0;
    	for(i in 0...lines.length)
    	{
    		HXP.point.x = switch(halign)
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
    				HXP.point.x += spaceWidth; // Do not add kerning to spaces
    				charIndex = 1;
    			}
    			else
    			{
    				if(charIndex++ >= 2)
    					HXP.point.x += kerning;

	    			// TODO This doesn't appear to support source alpha, hurting negative
	    			// leading and kerning. Descenders just disappear.
	    			var glyph:Rectangle = getGlyph(ch);
	    			if(glyph != null)
	    			{
	    				content.copyPixels(fontBitmap, glyph, HXP.point, null, null, true);
    					HXP.point.x += glyph.width;
    				}
    			}
    		}

    		HXP.point.y += fontBitmap.height + leading;
    	}
    }

    public override function render(target:BitmapData, point:Point, camera:Point)
    {
    	// Adjust horizontal registration point
    	if(halign == Center)
    		point.x -= contentWidth / 2;
    	else if(halign == Right)
    		point.x -= contentWidth; 

    	// Adjust vertical registration point
    	if(valign == Center)
    		point.y -= contentHeight / 2;
    	else if(valign == Bottom)
    		point.y -= contentHeight;
    	else if(valign == Baseline)
    		point.y -= (contentHeight - baseline);

    	// Pthbthth
    	super.render(target, point, camera);
    }
}