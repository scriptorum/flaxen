package flaxen.demo; 

import ash.core.Entity;
import com.haxepunk.HXP;
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

		newComponentSet("ball")
			.add(new Image("art/ball.png")) // Share image between all balls
			.add(Offset.center) // create new Offset for each ball, no parameters
			.add(function() { return Position.center(); }) // create new Position, via function
			.add(ImageGrid.create(60, 60));

		// could also have done newSingletonWithSet("ball", "ball"), instead of addComponents
		var ball = newSingleton("master")
			.add(new Data(false))
			.add(new Animation(northRoll, 30));
		addComponents(ball, "ball"); // add components to set

		newEntityWithSet("ball")
			.add(new Animation(eastRoll, 30, LoopType.Both))
			.get(Position).y = HXP.height / 3;

		newEntityWithSet("ball")
			.add(new Animation(eastRoll, 30, LoopType.BothBackward))
			.get(Position).y = HXP.height / 3 * 2;

		newEntityWithSet("ball")
			.add(new Animation(northRoll, 30, LoopType.Backward))
			.get(Position).x = HXP.width / 3;

		newEntityWithSet("ball")
			.add(new Animation(eastRoll, 30, LoopType.Backward))
			.get(Position).x = HXP.width / 3 * 2;

		setUpdateCallback(function(f)
		{
			if(InputService.pressed(Key.DIGIT_1))
			{
				var ball = demandEntity("master");
				var data = ball.get(Data);
				data.value = !data.value;
				var anim = ball.get(Animation);
				anim.setFrames(data.value ? eastRoll : northRoll);
				Log.write("Change animation frames to " + anim.frames);
				Log.write(LogUtil.dumpEntity(ball));
			}

			if(InputService.pressed(Key.DIGIT_2))
			{
				var ball = demandEntity("master");
				var anim = ball.get(Animation);
				anim.paused = !anim.paused;
				Log.write((anim.paused ? "Pausing" : "Unpausing") + " animation");
				Log.write(LogUtil.dumpEntity(ball));
			}

			if(InputService.pressed(Key.DIGIT_3))
			{
				var ball = demandEntity("master");
				var anim = ball.get(Animation);
				anim.setLoopType(anim.loop == None ? Forward : None, Last);
				Log.write("Changing animation loop type to " + anim.loop);
				Log.write(LogUtil.dumpEntity(ball));
			}

			if(InputService.pressed(Key.DIGIT_4))
			{
				var ball = demandEntity("master");
				var anim = ball.get(Animation);
				anim.restart = true;
				Log.write("Restarting animation");
				Log.write(LogUtil.dumpEntity(ball));
			}

			if(InputService.pressed(Key.DIGIT_5))
			{
				var ball = demandEntity("master");
				var anim = ball.get(Animation);
				anim.stopType = switch(anim.stopType)
				{
					case Clear: First;
					case First: Last;
					case Last: Clear;
				}
				anim.loop = None;
				anim.restart = true;
				Log.write("Changed animation stop behavior to " + anim.stopType);
				Log.write(LogUtil.dumpEntity(ball));
			}
		});
	}
}
