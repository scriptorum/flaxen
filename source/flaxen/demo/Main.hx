package flaxen.demo; 
import com.haxepunk.utils.Key;
import flaxen.component.Application;
import flaxen.component.Text;
import flaxen.component.Transitional;
import flaxen.component.Position;
import flaxen.demo.*;
import flaxen.Flaxen;
import flaxen.service.InputService;

/**
 * Flaxen Demo.
 * 
 * - TODO: I'd rather use CTRL/CMD-ENTER to toggle fullscreen. Right now, Flash 
 * 	  requires ESC to leave fullscreen mode. Also, I'm triggering on the F
 * 	  key instead the desired key combo.
 * - TODO: All demos (but layout) suffer from resize issues. Fixxy fix it!
 * - TODO: Break apart Animation demo into several examples, rather than the 1-5 key business you've got going on.
 */
class Main extends Flaxen
{
	private static var handlers:Array<Dynamic> = [SimpleHandler, 
		WobbleHandler, AnimationHandler, BitmapTextHandler, LayoutHandler, 
		MotionHandler];
	public var modes:Array<String>;
	public var handlerIndex:Int = 0;

	public static function main()
		new Main();

	override public function ready()
	{
		// Keep track of all handlers/modes
		modes = new Array<String>();

		// Define specific handlers, each is a separate demo
		for(handler in handlers)
				defineHandler(handler);

		// Define handler that is "always" called
		setHandler(new AlwaysHandler(this), Always);

		// Transition to first mode/handler
		restart();
	}

	private function defineHandler(clazz:Class<FlaxenHandler>): Void
	{
		var name:String = Type.getClassName(clazz);
		name = name.substring(name.lastIndexOf(".") + 1);
		var mode:ApplicationMode = Mode(name); // Create custom application mode
		var handler:FlaxenHandler = Type.createInstance(clazz, [this]);
		setHandler(handler, Mode(name));
		modes.push(name);
	}

	public function changeHandler(offset:Int)
	{
		handlerIndex += offset;
		if(handlerIndex < 0)
			handlerIndex = modes.length -1;
		else if(handlerIndex >= modes.length)
			handlerIndex = 0;

		restart();
	}

	// Stops the current handler (if any) and starts the handler currently indicated by handlerIndex
	public function restart()
	{
		setMode(Mode(modes[handlerIndex]));
	}
}

// TODO Having "before" and "after" always handlers would be useful. Really gotta rethink handlers/modes.
class AlwaysHandler extends FlaxenHandler
{
	public var main:Main;

	public function new(main:Main)
	{
		super(main);
		this.main = main;
	}

	override public function start()
	{
		f.newEntity()
			.add(new Text(main.modes[main.handlerIndex] + ": [ Previous, ] Next, R Restart, F Full Screen"))
			.add(Position.topLeft());
	}

	override public function update()
	{
		if(InputService.lastKey() == Key.F)
			com.haxepunk.HXP.fullscreen = !com.haxepunk.HXP.fullscreen;

		else if(InputService.lastKey() == Key.R)
			main.restart();

		else if(InputService.lastKey() == Key.LEFT_SQUARE_BRACKET)
			main.changeHandler(-1);
		
		else if(InputService.lastKey() == Key.RIGHT_SQUARE_BRACKET)
			main.changeHandler(1);

		else return;

		InputService.clearLastKey();		
	}

	override public function stop()
	{
	}
}
