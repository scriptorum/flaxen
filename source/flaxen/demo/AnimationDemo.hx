package flaxen.demo; 

import ash.core.Entity;
import flaxen.core.Flaxen;
import flaxen.component.Image;
import flaxen.component.Offset;
import flaxen.component.Position;
import flaxen.component.Data;
import flaxen.component.Animation;
import flaxen.component.ImageGrid;
import flaxen.component.Alpha;
import flaxen.service.InputService;
import flaxen.common.LoopType;
import com.haxepunk.HXP;
import com.haxepunk.utils.Key;

class AnimationDemo extends Flaxen
{
	private static inline var northRoll:String = "5-9,0-4";
	private static inline var westRoll:String = "15-19,10-14";

	public static function main()
	{
		var demo = new AnimationDemo();
	}

	override public function ready()
	{	
		newComponentSet("ball")
			.add(new Image("art/ball.png")) // Share image between all balls
			.add(Offset.center) // create new Offset for each ball, no parameters
			.add(function() { return Position.center(); }) // create new Position, via function
			.add(ImageGrid.create(60, 60));

		// could also have done newSingletonWithSet("ball", "ball"), instead of installComponents
		var ball = newSingleton("ball")
			.add(new Data(false))
			.add(new Animation(northRoll, 30));
		installComponents(ball, "ball"); // add components to set

		newEntityWithSet("ball")
			.add(new Animation(westRoll, 30, LoopType.Both))
			.get(Position).y = HXP.height / 3;

		newEntityWithSet("ball")
			.add(new Animation(westRoll, 30, LoopType.BothBackward))
			.get(Position).y = HXP.height / 3 * 2;

		newEntityWithSet("ball")
			.add(new Animation(northRoll, 30, LoopType.Backward))
			.get(Position).x = HXP.width / 3;

		newEntityWithSet("ball")
			.add(new Animation(westRoll, 30, LoopType.Backward))
			.get(Position).x = HXP.width / 3 * 2;

		setInputHandler(function(f)
		{
			if(InputService.pressed(Key.S))
			{
				var ball = demandEntity("ball");
				var data = ball.get(Data);
				data.value = !data.value;
				ball.get(Animation).setFrames(data.value ? westRoll : northRoll);
			}

			if(InputService.pressed(Key.P))
			{
				var ball = demandEntity("ball");
				var anim = ball.get(Animation);
				anim.paused = !anim.paused;
			}
		});
	}
}
