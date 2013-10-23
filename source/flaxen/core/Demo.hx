/*
 *	You don't have to subclass Flaxen if you don't want to:
 *
 *		var flaxen = new Flaxen();
 *	 	flaxen.setStartHandler(Init, function(flaxen:Flaxen)
 *	 	{
 *	 		flaxen.newEntity()....
 *		});
 *
 *	If you don't care to use the init system, you can just start creating entities:
 *
 *		var flaxen = new Flaxen();
 *	 	flaxen.newEntity()....
 */

package flaxen.core; 

import ash.core.Entity;
import com.haxepunk.HXP;
import flaxen.core.Flaxen;
import flaxen.component.Image;
import flaxen.component.Position;
import flaxen.component.Offset;
import flaxen.component.Scale;
import flaxen.component.Tween;
import flaxen.component.Application;
import flaxen.util.Easing;

class Demo extends Flaxen
{
	public static function main()
	{
		new Demo();
	}

	public function new()
	{
		super();
		setStartHandler(Init, startInit);
	}

	public function startInit(_)
	{
		var e:Entity = newEntity()
			.add(new Image("art/flaxen.png"))
			.add(new Position(HXP.halfWidth, HXP.halfHeight))
			.add(new Scale())
			.add(Offset.center);
		var tween:Tween = addTween(e.get(Scale), { x:0.8, y:1.2 }, 0.2, Easing.easeOutQuad);
		tween.loop = Both;
	}
}
