package flaxen.demo; 
import flaxen.Flaxen;
import flaxen.component.Transitional;
import flaxen.component.Application;
import flaxen.service.InputService;
import flaxen.demo.*;
import com.haxepunk.utils.Key;

/**
 * Flaxen Demo.
 * 
 * - TODO: I'd rather use CTRL/CMD-ENTER to toggle fullscreen. Right now, Flash 
 * 	  requires ESC to leave fullscreen mode. Also, I'm triggering on the F
 * 	  key instead the desired key combo.
 * - TODO: All demos (but layout) suffer from resize issues. Fixxy fix it!
 * - TODO: Add name of handler on screen and key stroke instructions
 * - TODO: Add Tester as one of the handlers, and display the final result on screen, if possible.
 * - TODO: Break apart Animation demo into several examples, rather than the 1-5 key business you've got going on.
 * - TODO: Add movement, gravity, and friction demos.
 */
class Main extends Flaxen
{
	private var modes:Array<ApplicationMode>;
	private var handlerIndex:Int = 0;

	public static function main()
		new Main();

	override public function ready()
	{
		modes = new Array<ApplicationMode>();

		defineHandler("BasicImage",	SimpleHandler);
		defineHandler("Wobble",		WobbleHandler);
		defineHandler("Animation",	AnimationHandler);
		defineHandler("BitmapText",	BitmapTextHandler);
		defineHandler("Layout",		LayoutHandler);

		// The ALWAYS update handler is called after the current update handler runs
		setUpdateCallback(globalUpdate, Always); 

		// Transition to first mode
		setMode(modes[handlerIndex]);		
	}

	private function defineHandler(name:String, clazz:Class<FlaxenHandler>): Void
	{
		var mode:ApplicationMode = Mode(name); // Create custom application mode
		var handler:FlaxenHandler = Type.createInstance(clazz, [this]);
		setHandler(handler, mode);
		modes.push(mode);
	}

	// Alternatively, you could skip setUpdateCallback and this could override 
	// HaxePunk's update, but remember to call super.update()!
	public function globalUpdate()
	{
		if(InputService.lastKey() == Key.F)
		{
			com.haxepunk.HXP.fullscreen = !com.haxepunk.HXP.fullscreen;
			InputService.clearLastKey();
		}		

		else if(InputService.lastKey() == Key.LEFT_SQUARE_BRACKET)
			changeHandler(-1);
		
		else if(InputService.lastKey() == Key.RIGHT_SQUARE_BRACKET)
			changeHandler(1);
	}

	public function changeHandler(offset:Int)
	{
		handlerIndex += offset;
		if(handlerIndex < 0)
			handlerIndex = modes.length -1;
		else if(handlerIndex >= modes.length)
			handlerIndex = 0;

		setMode(modes[handlerIndex]);
		InputService.clearLastKey();
	}
}
