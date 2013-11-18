/*
  TODO Support resizable
*/
  
package flaxen.render;

import flash.text.TextFormatAlign;
import com.haxepunk.graphics.Text;
import com.haxepunk.graphics.Graphiclist;
import com.haxepunk.HXP;
import flaxen.common.TextAlign;
import flaxen.core.Log;

typedef HaxePunkAlignment = #if (flash || js) TextFormatAlign #else String #end;

class ShadowText extends Graphiclist
{
	private var texts:Array<Text>;
	private var font:String;

	public function new(str:String, x:Float = 0, y:Float = 0, size:Int = 14, color:Int = 0xFFFFFF, 
		?font:String, width:Int = 0, height:Int = 0, 
		?alignment:HorizontalTextAlign, wordWrap:Bool = false, scrollFactor:Float = 1, leading:Int = 0, 
		shadowOffset:Int = 2, shadowColor:Int = 0x000000)
	{
		super();
		this.font = (font == null ? HXP.defaultFont : font);
		var align = (alignment == null ? Left : alignment);
		texts = new Array<Text>();
		if(shadowOffset != 0)
			texts.push(makeText(str, shadowColor, size, x + shadowOffset, y+shadowOffset, 
					width, height, scrollFactor, align, wordWrap, leading));
		texts.push(makeText(str, color, size, x, y, width, height, scrollFactor, 
			align, wordWrap, leading));

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
		width:Int, height:Int, scrollFactor:Float, alignment:HorizontalTextAlign, 
		wordWrap:Bool, leading:Int): Text
	{
		var options:TextOptions = cast { color:color, font:font, size:size, 
			resizable:false, align:getHaxePunkAlignment(alignment), wordWrap:wordWrap, 
			leading:leading };
		var t = new Text(str, x, y, width, height, options);
		t.scrollX = t.scrollY = scrollFactor;
		add(t);
		return t;
	}

	public static function getHaxePunkAlignment(alignment:HorizontalTextAlign): HaxePunkAlignment
	{	
		return switch(alignment)
		{
			case Left: #if (flash || js) TextFormatAlign.LEFT #else "left" #end;
			case Right: #if (flash || js) TextFormatAlign.RIGHT #else "right" #end;
			case Center: #if (flash || js) TextFormatAlign.CENTER #else "center" #end;
			case Full: #if (flash || js) TextFormatAlign.JUSTIFY #else "justify" #end;
		}

		Log.warn("ShadowText Unsupported alignment:" + alignment);
		return #if (flash || js) TextFormatAlign.LEFT #else "left" #end;
	}
}