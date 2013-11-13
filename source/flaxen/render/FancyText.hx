

package flaxen.render;

import com.haxepunk.graphics.Text;
import com.haxepunk.graphics.Graphiclist;
import com.haxepunk.HXP;
import flash.text.TextFormatAlign;
import flaxen.core.Log;

#if (flash || js)
typedef FTAlign = TextFormatAlign;
#else
typedef FTAlign = String;
#end

// TODO Support resizable

class FancyText extends Graphiclist
{
	private var texts:Array<Text>;
	private var font:String;

	public function new(str:String, x:Float = 0, y:Float = 0, size:Int = 14, color:Int = 0xFFFFFF, 
		?font:String, width:Int = 0, height:Int = 0, 
		alignment:String = "left", wordWrap:Bool = false, scrollFactor:Float = 1, leading:Int = 0, 
		shadowOffset:Int = 2, shadowColor:Int = 0x000000)
	{
		super();
		this.font = (font == null ? HXP.defaultFont : font);
		var ftAlign:FTAlign = stringToFTAlign(alignment);
		texts = new Array<Text>();
		if(shadowOffset != 0)
			texts.push(makeText(str, shadowColor, size, x + shadowOffset, y+shadowOffset, 
					width, height, scrollFactor, ftAlign, wordWrap, leading));
		texts.push(makeText(str, color, size, x, y, width, height, scrollFactor, ftAlign, wordWrap, leading));

		for(t in texts)
			add(t);
	}

	public function setString(str:String): Void
	{
		for(t in texts)
			t.text = str;
	}

	public function getString(): String
	{
		return (texts == null ? "" : texts[0].text);
	}

	public function setAlpha(alpha:Float): Void
	{
		for(t in texts)
			t.alpha = alpha;
	}

	public function getAlpha(): Float
	{
		return texts[0].alpha;
	}

	public function getWidth(): Float
	{
		return texts[0].width + 2;	
	}

	public function setSize(size:Int): Void
	{
		for(t in texts)
			t.size = size;
	}

	private function makeText(str:String, color:Int, size:Int, x:Float, y:Float, 
		width:Int, height:Int, scrollFactor:Float, alignment:FTAlign, wordWrap:Bool, leading:Int): Text
	{
		var options:TextOptions = cast { color:color, font:font, size:size, resizable:false, align:alignment, 
			wordWrap:wordWrap, leading:leading };
		var t = new Text(str, x, y, width, height, options);
		t.scrollX = t.scrollY = scrollFactor;
		add(t);
		return t;
	}

	public static function stringToFTAlign(alignment:String): FTAlign
	{
		#if (flash || js)
			switch(alignment)
			{
				case "left": return flash.text.TextFormatAlign.LEFT;
				case "right": return flash.text.TextFormatAlign.RIGHT;
				case "center": return flash.text.TextFormatAlign.CENTER;
				case "justify": return flash.text.TextFormatAlign.JUSTIFY;
			}

			Log.warn("FancyText Unsupported alignment:" + alignment);
			return flash.text.TextFormatAlign.LEFT;
		#else
			return alignment;
		#end
	}
}