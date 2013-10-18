package flaxen.system;

import ash.core.System;
import com.haxepunk.HXP;
import flaxen.component.Application;

/*
 * In charge of maintenance of game scenes/modes including intialization of the main flaxen.
 */

class InitSystem extends FlaxenSystem
{
	private var app:Application;

	public function init()
	{
		this.app = entityService.getApplication();
	}

	override public function update(time:Float)
	{
		if(app.init == false)
			return;

		initMode();
	}

	private function initMode()
	{
		entityService.transitionTo(app.mode);

		switch(app.mode)
		{
			case INIT:
			entityService.startInit();
			app.changeMode(MENU);
			initMode(); // immediately transition to above mode

			case MENU:
			entityService.startMenu();

			case GAME:
			entityService.startPlay();

			case END:
			entityService.startLevelSelect();
		}

		app.init = false;
	}
}