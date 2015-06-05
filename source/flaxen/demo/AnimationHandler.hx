package flaxen.demo; 

import ash.core.Entity;
import com.haxepunk.utils.Key;
import flaxen.common.TextAlign;
import flaxen.common.LoopType;
import flaxen.common.OnCompleteAnimation;
import flaxen.component.Alpha;
import flaxen.component.Animation;
import flaxen.component.Data;
import flaxen.component.Display;
import flaxen.component.Image;
import flaxen.component.ImageGrid;
import flaxen.component.Offset;
import flaxen.component.Position;
import flaxen.component.Layer;
import flaxen.component.Repeating;
import flaxen.component.Size;
import flaxen.component.Text;
import flaxen.Flaxen;
import flaxen.FlaxenHandler;
import flaxen.Log;
import flaxen.render.view.AnimationView;
import flaxen.util.LogUtil;
import flaxen.service.InputService;

/**
 * This demo is really hard to follow. Instead of having keys bound to 
 * turning on an off different Animation options, come up with a sequence 
 * of animations that illustrates the intended effects.
 */
class AnimationHandler extends FlaxenHandler
{
	private var anim:Animation;
	private static inline var northRoll:String = "11-20";
	private static inline var eastRoll:String = "5-10,1-4";

	override public function start()
	{	
		f.newEntity()
			.add(new Image("art/metalpanels.png"))
			.add(new Layer(100))
			.add(Repeating.instance);

		f.newComponentSet("ballSet")
			.add(new Image("art/ball.png")) // Share image between all balls
			.addFunction(function(_) { return Offset.center(); }) // create new Offset for each
			.addFunction(function(_) { return Position.center(); }) // create new Position for each
			.add(ImageGrid.create(60, 60)); // Share image grid

		anim = new Animation(northRoll, 30);
		var ball = f.newSetEntity("ballSet", "master")
			.add(new Data(false))
			.add(anim);

		f.newSetEntity("ballSet", "ball#")
			.add(new Animation(eastRoll, 30, LoopType.Both))
			.get(Position).y = com.haxepunk.HXP.height / 3;

		f.newSetEntity("ballSet", "ball#")
			.add(new Animation(eastRoll, 30, LoopType.BothBackward))
			.get(Position).y = com.haxepunk.HXP.height / 3 * 2;

		f.newSetEntity("ballSet", "ball#")
			.add(new Animation(northRoll, 30, LoopType.Backward))
			.get(Position).x = com.haxepunk.HXP.width / 3;

		f.newSetEntity("ballSet", "ball#")
			.add(new Animation(eastRoll, 30, LoopType.Backward))
			.get(Position).x = com.haxepunk.HXP.width / 3 * 2;

		updateStatus();
	}

	private function updateStatus()
	{
		var style = TextStyle.createTTF();
		style.halign = Right;
		f.resolveEntity("status")
			.add(new Text("1 " + anim.frames 
				+ ", 2 " + (anim.paused ? "Paused" : "Running")
				+ ", 3 " + anim.loop 
				+ ", 4 Restart Anim"
				+ ", 5 " + anim.onComplete
				+ ", 6 StopReset, 7 Stop"))
			.add(style)
			.add(new Size(com.haxepunk.HXP.width, 20)) // specify size of text box
			.add(new Position(0, com.haxepunk.HXP.height - 20)); // specify by upper left corner of text box			
	}

	private var status = {};

	override public function update()
	{
		if(InputService.pressed(Key.DIGIT_1))
		{
			var ball = f.getEntity("master");
			var data = ball.get(Data);
			data.value = !data.value;
			anim.setFrames(data.value ? eastRoll : northRoll);
			updateStatus();
		}

		if(InputService.pressed(Key.DIGIT_2))
		{
			var ball = f.getEntity("master");
			var anim = ball.get(Animation);
			anim.paused = !anim.paused;
			updateStatus();
		}

		if(InputService.pressed(Key.DIGIT_3))
		{
			var ball = f.getEntity("master");
			var anim = ball.get(Animation);
			anim.setLoopType(anim.loop == None ? Forward : None, Last);
			updateStatus();
		}

		if(InputService.pressed(Key.DIGIT_4))
		{
			var ball = f.getEntity("master");
			var anim = ball.get(Animation);
			anim.restart = true;
			updateStatus();
		}

		if(InputService.pressed(Key.DIGIT_5))
		{
			var ball = f.getEntity("master");
			var anim = ball.get(Animation);
			switch(anim.onComplete)
			{
				case Clear: 	anim.onComplete = First;
				case First: 	anim.onComplete = Last;
				case Current: 	anim.onComplete = Clear; // Not really useful for demo, same effect as Last
				case Last: 		anim.onComplete = Clear; // Skipping Pause
				default: 		// do nothing
			}
			anim.loop = None;
			anim.restart = true;
			updateStatus();
		}

		if(InputService.pressed(Key.DIGIT_6))
		{
			var ball = f.getEntity("master");
			var view:AnimationView = cast ball.get(Display).view;
			view.spritemap.stop(true);
		}

		if(InputService.pressed(Key.DIGIT_7))
		{
			var ball = f.getEntity("master");
			var view:AnimationView = cast ball.get(Display).view;
			view.spritemap.stop(false);
		}
	}
}
