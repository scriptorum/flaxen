package flaxen.render.view;

import flaxen.common.TextAlign;
import flaxen.core.Log;
import flaxen.component.Alpha;
import flaxen.component.Image;
import flaxen.component.Size;
import flaxen.component.Text;
import flaxen.render.BitmapText;
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
			var img:Image = getComponent(Image); // required image

			var width:Int = 0;
			var height:Int = 0;
			if(hasComponent(Size)) // optional size
			{
				var size:Size = getComponent(Size); 
				width = Std.int(size.width);
				height = Std.int(size.height);
			}

			graphic = display = new BitmapText(img.path, 0, 0, curMessage, width, height, 
				curStyle.wordWrap, curStyle.align, curStyle.leading, curStyle.kerning, 
				curStyle.baseline, curStyle.charSet, curStyle.emChar);

			curStyle.changed = false;			
		}

		// Update/set text message
		else display.setText(curMessage);
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
				Log.error("Cannot create BitmapTextView with a null text style");
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
		}
		else if(display != null)
		{
			display = null;
			return;
		}
	}

	// BitmapTextView uses BitmapText which is a subclass of Image. We don't want the 
	// our superclass View to apply automatic scaling based on Size, because we're using 
	// Size to mean the shape of the bitmap text box.
	override private function useSizeForImageScaling()
	{ 
		return false; 
	} 
}