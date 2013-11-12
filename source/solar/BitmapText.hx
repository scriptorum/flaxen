// BitmapText.hx
// solar
// http://dl.dropboxusercontent.com/u/28629176/gamedev/crappyretrogame/hw_bmptext/BitmapText.hx
// http://forum.haxepunk.com/index.php?topic=334.0

package solar;

import flash.display.BitmapData;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import com.haxepunk.HXP;
import com.haxepunk.RenderMode;
import com.haxepunk.graphics.Canvas;
import com.haxepunk.graphics.atlas.TileAtlas;

class BitmapText extends Canvas
{
	// render objects
	private var _set:BitmapData;
	private var _letterRect:Array<Rectangle>;
	private var _font:TileAtlas;
	
	// width and height of a letter
	private var _letterWidth:Int;
	private var _letterHeight:Int;
	// gap between letters
	private var _lineGap:Int = 0;
	private var _letterGap:Int = 0;
	// first charcode
	private var _charCode:Int;
	// stuff
	private var _align:Int = 0; // 0 - left, 1 - center, 2 - right
	
	// string to display, broken up into lines
	private var _text:String;
	private var _textLines:Array<String>;
	private var _manualWidth:Int;
	private var _autoWidth:Int;
	
	public function new(font:Dynamic, letterWidth:Int, letterHeight:Int,  charCode:Int = 32)
	{
		// load the font
		setFont(font, letterWidth, letterHeight, charCode);
		
		// we'll change this later to reflect the new size of the text box
		super(_letterWidth, _letterHeight);
	}
	
	public function setFont(font:Dynamic, letterWidth:Int, letterHeight:Int, charCode:Int = 32)
	{
		_letterWidth = letterWidth;
		_letterHeight = letterHeight;
		_charCode = charCode;
		
		// load the font
		if(Std.is(font, TileAtlas))
		{
			_blit = false;
			_font = cast(font, TileAtlas);
		}
		else if (HXP.renderMode.has(RenderMode.HARDWARE))
		{
			_blit = false;
			_font = new TileAtlas(font, _letterWidth, _letterHeight);
		}
		else
		{
			if (Std.is(font, BitmapData))
			{
				_blit = true;
				_set = font;
			}
			else
			{
				_blit = true;
				_set = HXP.getBitmap(font);
			}
			
			// reset array
			_letterRect = [];
			
			// build font glyphs
			var pos:Point = new Point(0, 0);
			var charCode:Int = 0;
			
			while(pos.y < _set.height)
			{
				while(pos.x < _set.width)
				{
					_letterRect[charCode] = new Rectangle(pos.x, pos.y, _letterWidth, _letterHeight);
			
					pos.x += _letterWidth;
					charCode++;
				}
				pos.y += _letterHeight;
				pos.x = 0;
			}
		}
		
		// failure to load
		if (_set == null && _font == null)
			throw "Invalid font glyphs provided.";
	}
	
	public function setLetterGap(letterGap:Int)
	{
		_letterGap = letterGap;
		
		if(_blit)
			updateBuffer();
	}
	
	public function setLineGap(lineGap:Int)
	{
		_lineGap = lineGap;
		
		if(_blit)
			updateBuffer();
	}
	
	public function setAlign(align:String)
	{
		switch(align)
		{
			case 'left':
				_align = 0;
			case 'center':
				_align = 1;
			case 'right':
				_align = 2;
		}
		
		if(_blit)
			updateBuffer();
	}
	
	public function setText(text:String, align:String = '')
	{
		trace("Setting text:" + text);
		_text = text;
		_textLines = _text.split("\n");
		_autoWidth = 0;
		
		switch(align)
		{
			case 'left':
				_align = 0;
			case 'center':
				_align = 1;
			case 'right':
				_align = 2;
		}
		
		updateLongestLine();
		
		if(_blit)
			updateBuffer();
	}
	
	public function setTextFromArray(text:Array<String>)
	{
		_textLines = text;
		
		_text = text[0];
		for(i in 1...text.length)
		{
			_text = _text + "\n" + text[i];
		}
		
		updateLongestLine();
		
		if(_blit)
			updateBuffer();
	}
	
	private function updateBuffer()
	{
		if(_textLines == null)
			_textLines = new Array<String>();

		// this is all pretty much copied wholesale from the canvas constructor
		_buffers = new Array<BitmapData>();

		_width = _autoWidth;
		_height = _textLines.length * (_letterHeight + _lineGap);
		_refWidth = Math.ceil(_width / _maxWidth);
		_refHeight = Math.ceil(_height / _maxHeight);
		_ref = HXP.createBitmap(_refWidth, _refHeight);
		var x:Int = 0, y:Int = 0, w:Int, h:Int, i:Int = 0,
			ww:Int = _width % _maxWidth,
			hh:Int = _height % _maxHeight;
		if (ww == 0) ww = _maxWidth;
		if (hh == 0) hh = _maxHeight;
		while (y < _refHeight)
		{
			h = y < _refHeight - 1 ? _maxHeight : hh;
			while (x < _refWidth)
			{
				w = x < _refWidth - 1 ? _maxWidth : ww;
				_ref.setPixel(x, y, i);
				_buffers[i] = HXP.createBitmap(w, h, true);
				i ++; x ++;
			}
			x = 0; y ++;
		}
		
		// draw the letters into the new, empty buffer
		var y:Int = 0;
		var x:Int = 0;
		while(y < _textLines.length)
		{
			while(x < _textLines[y].length)
			{
				//var wx = x * (_letterWidth + _letterGap);
				var wx:Int = 0;
				
				switch(_align)
				{
					// center
					case 1:
						wx = Std.int((_autoWidth - getLineWidth(y)) * 0.5) + (x * (_letterWidth + _letterGap));
					// right
					case 2:
						wx = Std.int(_autoWidth - getLineWidth(y)) + (x * (_letterWidth + _letterGap));
					// left/default
					default:
						wx = Std.int(x * (_letterWidth + _letterGap));
				}
				
				var wy = y * (_letterHeight + _lineGap);
				
				draw(wx, wy, _set, getCharRect(_textLines[y].charCodeAt(x)) );
				x++;
			}
			x = 0;
			y++;
		}
	}
	
	public override function render(target:BitmapData, point:Point, camera:Point)
	{

		if(_blit)
			super.render(target, point, camera);
		else
		{
			// determine drawing location
			_point.x = point.x + x - camera.x * scrollX;
			_point.y = point.y + y - camera.y * scrollY;
			
			var scalex:Float = HXP.screen.fullScaleX;
			var scaley:Float = HXP.screen.fullScaleY;
			
			var r = HXP.getRed(color) / 255;
			var g = HXP.getGreen(color) / 255;
			var b = HXP.getBlue(color) / 255;
			
			var y = 0;
			var x = 0;
			var wx;
			var wy;
			// loop through each line
			while(y < _textLines.length)
			{
				// loop through the string in each line
				while(x < _textLines[y].length)
				{
					switch(_align)
					{
						// center
						case 1:
							wx = _point.x + ((_autoWidth - getLineWidth(y)) * 0.5) + (x * (_letterWidth + _letterGap));
						// right
						case 2:
							wx = _point.x + (_autoWidth - getLineWidth(y)) + (x * (_letterWidth + _letterGap));
						// left/default
						default:
							wx = (_point.x + (x * (_letterWidth + _letterGap)));
					}
					
					wx *= scalex;
					wy = (_point.y + (y * (_letterHeight + _lineGap))) * scaley;
					
					_font.prepareTile( getCharCode(_textLines[y].charCodeAt(x)) , wx, wy, layer, scalex, scaley, 0, r, g, b, alpha );
					x++;
				}
				x = 0;
				y++;
			}
			
		}
	}
	
	private inline function updateLongestLine()
	{
		// find the line with the longest length and use it as the width
		for(i in 0..._textLines.length)
		{
			if(_autoWidth < getLineWidth(i))
				_autoWidth = getLineWidth(i);
		}
	}
	
	private inline function getLineWidth(i:Int)
	{
		if(i >= 0 && i < _textLines.length)
			return _textLines[i].length * (_letterWidth + _letterGap);
		else
			return 0;
	}
	
	private inline function getCharCode(charCode:Int)
	{
		return charCode - _charCode;
	}
	
	private inline function getCharRect(charCode:Int)
	{
		if(charCode - _charCode > 0)
			return _letterRect[charCode - _charCode];
		else
			return new Rectangle(0, 0, 0, 0);
	}
}