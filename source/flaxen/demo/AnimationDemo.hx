package flaxen.demo; 

import ash.core.Entity;
import com.haxepunk.utils.Key;
import flaxen.common.LoopType;
import flaxen.component.Alpha;
import flaxen.component.Animation;
import flaxen.component.Data;
import flaxen.component.Image;
import flaxen.component.ImageGrid;
import flaxen.component.Offset;
import flaxen.component.Position;
import flaxen.component.Layer;
import flaxen.component.Repeating;
import flaxen.core.Flaxen;
import flaxen.core.Log;
import flaxen.util.LogUtil;
import flaxen.service.InputService;

/**
 * This demo is really hard to follow. Instead of having keys bound to 
 * turning on an off different Animation options, come up with a sequence 
 * of animations that illustrates the intended effects.
 */
class AnimationDemo extends Flaxen
{
	private static inline var northRoll:String = "11-20";
	private static inline var eastRoll:String = "5-10,1-4";

	public static function main()
	{
		var demo = new AnimationDemo();
	}

	override public function ready()
	{	
		newEntity()
			.add(new Image("art/metalpanels.png"))
			.add(new Layer(100))
			.add(Repeating.instance);

		newComponentSet("ballSet")
			.add(new Image("art/ball.png")) // Share image between all balls
			.addFunction(function(_) { return Offset.center(); }) // create new Offset for each
			.addFunction(function(_) { return Position.center(); }) // create new Position for each
			.add(ImageGrid.create(60, 60)); // Share image grid

		var ball = newSetEntity("ballSet", "master")
			.add(new Data(false))
			.add(new Animation(northRoll, 30));

		newSetEntity("ballSet", "ball#")
			.add(new Animation(eastRoll, 30, LoopType.Both))
			.get(Position).y = com.haxepunk.HXP.height / 3;

		newSetEntity("ballSet", "ball#")
			.add(new Animation(eastRoll, 30, LoopType.BothBackward))
			.get(Position).y = com.haxepunk.HXP.height / 3 * 2;

		newSetEntity("ballSet", "ball#")
			.add(new Animation(northRoll, 30, LoopType.Backward))
			.get(Position).x = com.haxepunk.HXP.width / 3;

		newSetEntity("ballSet", "ball#")
			.add(new Animation(eastRoll, 30, LoopType.Backward))
			.get(Position).x = com.haxepunk.HXP.width / 3 * 2;

		setUpdateCallback(function(f)
		{
			if(InputService.pressed(Key.DIGIT_1))
			{
				var ball = getEntity("master");
				var data = ball.get(Data);
				data.value = !data.value;
				var anim = ball.get(Animation);
				anim.setFrames(data.value ? eastRoll : northRoll);
				Log.write("Change animation frames to " + anim.frames);
			}

			if(InputService.pressed(Key.DIGIT_2))
			{
				var ball = getEntity("master");
				var anim = ball.get(Animation);
				anim.paused = !anim.paused;
				Log.write((anim.paused ? "Pausing" : "Unpausing") + " animation");
			}

			if(InputService.pressed(Key.DIGIT_3))
			{
				var ball = getEntity("master");
				var anim = ball.get(Animation);
				anim.setLoopType(anim.loop == None ? Forward : None, Last);
				Log.write("Changing animation loop type to " + anim.loop);
			}

			if(InputService.pressed(Key.DIGIT_4))
			{
				var ball = getEntity("master");
				var anim = ball.get(Animation);
				anim.restart = true;
				Log.write("Restarting animation");
			}

			if(InputService.pressed(Key.DIGIT_5))
			{
				var ball = getEntity("master");
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
				Log.write("Changed animation stop behavior to " + anim.stopType);
			}

			if(InputService.pressed(Key.DIGIT_6))
			{
				var ball = getEntity("master");
				var view:flaxen.render.view.AnimationView = 
					cast ball.get(flaxen.component.Display).view;
				view.spritemap.stop(true);
				Log.write("Stopping anim with reset");
			}

			if(InputService.pressed(Key.DIGIT_7))
			{
				var ball = getEntity("master");
				var view:flaxen.render.view.AnimationView = 
					cast ball.get(flaxen.component.Display).view;
				view.spritemap.stop(false);
				Log.write("Stopping anim without reset");
			}
		});
	}
}
