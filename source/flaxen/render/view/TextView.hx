/*
  TODO:
    - Change the registration point to work just like in BitmapText, so when 
      so for center alignment you specify the center point. 
    - Add valign support
    - Add HorizontalTextAlign.Full support
*/
package flaxen.render.view;

import flaxen.component.Text;
import flaxen.component.Alpha;
import flaxen.component.Size;
import flaxen.render.ShadowText;
import flash.text.TextFormatAlign;
import com.haxepunk.HXP;

class TextView extends View
{
	private var curWidth:Int = 0;
	private var curHeight:Int = 0;
	private var curScaleX:Float = 1.0;
	private var curScaleY:Float = 1.0;
	private var curScale:Float = 1.0;
	private var curMessage:String;
	private var curStyle:TextStyle;
	private var display:ShadowText;

	override public function begin()
	{
		nodeUpdate();
	}

	// Create or update text object
	private function setText(forceNew:Bool)
	{
		// Create new text
		if(graphic == null || forceNew || curStyle.changed)
		{
			// TODO Support ScrollFactor
			graphic = display = new ShadowText(curMessage, 0, 0, Std.int(curStyle.size * curScale), 
				curStyle.color, (curStyle.font == null ? HXP.defaultFont : curStyle.font), 
				Std.int(curWidth * curScale), Std.int(curHeight * curScale), 
				curStyle.halign, curStyle.wordWrap, 1, curStyle.leading,
				curStyle.shadowOffset, curStyle.shadowColor);
			curStyle.changed = false;			
		}

		// Update text message
		else display.setString(curMessage);
	}

	override public function nodeUpdate()
	{
		super.nodeUpdate();

		if(hasComponent(Text))
		{
			var text:Text = getComponent(Text);
			var updateDisplay = false;
			var forceNew = false;

			// Check for new/changed style, or provide reasonable default
			if(hasComponent(TextStyle)) 
			{
				var style = getComponent(TextStyle);
				if(style != curStyle || style.changed)
				{
					curStyle = style;
					updateDisplay = true;
				}

			}
			else if(curStyle == null)
			{
				curStyle = TextStyle.createTTF();
				updateDisplay = true;
			}

			// Check for text area dimensions change
			if(hasComponent(Size))
			{
				var size:Size = getComponent(Size);
				var sw = Math.round(size.width);
				var sh = Math.round(size.height);
				if(sw != curWidth || sh != curHeight)
				{
					curWidth = sw;
					curHeight = sh;
					updateDisplay = true;
					forceNew = true;
				}
			}
			else curWidth = curHeight = 0;

			// Check for text message change
			if(text.message != curMessage)
			{
				curMessage = text.message;
				updateDisplay = true;
			}
			else curMessage = ""; // TODO Should this be removed?

			// HACK Because HaxePunk does not properly scale text on CPP targets
			#if !flash
				if(curScaleX != HXP.screen.fullScaleX || curScaleY != HXP.screen.fullScaleY)
				{
					curScaleX = HXP.screen.fullScaleX;
					curScaleY = HXP.screen.fullScaleY;
					curScale = (curScaleX + curScaleY) / 2;
					updateDisplay = true;
					forceNew = true;
				}
			#end

			// If any changes, update text object
			if(updateDisplay)
				setText(forceNew);

			// Update alpha/transparency
			if(hasComponent(Alpha))
			{
				var alpha:Float = getComponent(Alpha).value;
				if(alpha != display.getAlpha())
					display.setAlpha(alpha);
			}
		}
		else if(display != null)
		{
			display = null;
			return;
		}
	}
}