//
// This is a flash preloader, it's not used for CPP targets
// The Assets class is not available at this stage of the bootstrap,
// so you must use the "native Haxe" way of loading embedded assets.
//

package inscrutablegames;

import openfl.display.BitmapData;
import openfl.display.Graphics;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormatAlign;
import openfl.text.TextFormat;
import openfl.text.Font;
import openfl.events.Event;
import openfl.geom.Rectangle;
import openfl.display.Tilesheet;

@:bitmap("assets/art/inscrutablegames.png") class LogoImage extends BitmapData {}
@:font("assets/font/AccidentalPresidency.ttf") class MainFont extends Font { }

class Preloader extends Sprite
{
	private static inline var LOGO_WIDTH:Int = 386;
	private static inline var LOGO_HEIGHT:Int = 116;

	private var tf:TextField;
	private var tiles:Tilesheet;
	private var tileData:Array<Float>;

	public function new()
	{
		super();

        graphics.beginFill(0x9d9283);
        graphics.drawRect(0, 0, getWidth(), getHeight());
        graphics.endFill();
            	
		tileData = [
			  (getWidth() - LOGO_WIDTH) / 2, -LOGO_HEIGHT / 2 + getHeight() * 1/2 , 0,
		];

		tiles = new Tilesheet(new LogoImage(0,0));
		tiles.addTileRect(new Rectangle(0, 0, LOGO_WIDTH, LOGO_HEIGHT));
		tiles.drawTiles(graphics, tileData, true);

		var format = new TextFormat();
		format.align = TextFormatAlign.CENTER;
		format.size = 24;
		format.color = 0xFFFFFF;
		format.bold = true;
		format.font = new MainFont().fontName;

		tf = new TextField();
		tf.width = getWidth() * 1/4;
		tf.height = 200;
		tf.text = "Loading";
		tf.x = getWidth() * 3/4;
		tf.y = getHeight() * 7/8;
		tf.selectable = false;
		tf.defaultTextFormat = format;
		addChild(tf);
	}
		
	public function getHeight():Float
	{
		return openfl.Lib.current.stage.stageHeight;
	}
	
	public function getWidth():Float
	{
		return openfl.Lib.current.stage.stageWidth;
	}
		
	public function onInit()
	{
	}
	
	public function onLoaded()
	{
		#if !freezeloader
		dispatchEvent (new Event (Event.COMPLETE));
		#end
	}

	public function onUpdate(bytesLoaded:Int, bytesTotal:Int)
	{
		var percentLoaded = Math.min(1, bytesLoaded / bytesTotal);		
		tf.text = Std.int(percentLoaded * 100) + "%";
	}
}
