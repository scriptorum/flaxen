package flaxen.render;

import flaxen.component.Text;
import flaxen.component.Alpha;
import flaxen.component.Size;
import flaxen.component.Image;
import flaxen.render.BitmapText;
import flash.text.TextFormatAlign;
import com.haxepunk.HXP;

class BitmapTextView extends View
{
	private var curWidth:Int = 0;
	private var curHeight:Int = 0;
	private var curMessage:String;
	private var curStyle:TextStyle;
	private var display:BitmapText;

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
			var img:Image = getComponent(Image);
			graphic = display = new BitmapText(img.path, 0, 0, Left, curMessage, 
				curStyle.leading); // curStyle.kerning
			// display.setAlign(Std.string(curStyle.alignment));
			// display.setLineGap(curStyle.leading);
			curStyle.changed = false;			
		}

		// Update/set text message
		// display.setText(curMessage);
	}

	override public function nodeUpdate()
	{
		super.nodeUpdate();

		if(hasComponent(Text))
		{
			var text:Text = getComponent(Text);
			var updateDisplay = false;
			var forceNew = false;

			// Check for style change, provide style default
			var style = text.style;
			if(style == null)
				throw "Cannot create BitmapTextView with a null text style";
			if(style != curStyle || style.changed)
			{
				curStyle = style;
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

			// If any changes, update text object
			if(updateDisplay)
				setText(forceNew);

			// Update alpha/transparency
			if(hasComponent(Alpha))
			{
				var alpha:Float = getComponent(Alpha).value;
				// if(alpha != display.alpha)
				// 	display.alpha = alpha;
			}
		}
		else if(display != null)
		{
			display = null;
			return;
		}
	}
}