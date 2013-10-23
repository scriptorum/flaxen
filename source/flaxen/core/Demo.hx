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

import flaxen.component.Application;

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
		newEntity()
			.add(new Image("art/flaxen.png"))
			.add(new Position(HXP.halfWidth, HXP.halfHeight))
			.add(Offset.center);		
	}
}
