package flaxen.system;

import ash.core.Engine;
import ash.core.System;
import ash.core.Entity;

import com.haxepunk.HXP;

import flaxen.service.EntityService;
import flaxen.component.Application;

/*
 * In charge of maintenance of game scenes/modes including intialization of the main flaxen.
 */

class InitSystem extends System
{
	private var app:Application;

	public var factory:EntityService;
	public var engine:Engine;

	public function new(engine:Engine, factory:EntityService)
	{
		super();
		this.engine = engine;
		this.factory = factory;
		this.app = factory.getApplication();
	}

	override public function update(time:Float)
	{
		if(app.init == false)
			return;

		initMode();
	}

	private function initMode()
	{
		factory.transitionTo(app.mode);

		switch(app.mode)
		{
			case INIT:
			factory.startInit();
			app.changeMode(MENU);
			initMode(); // immediately transition to above mode

			case MENU:
			factory.startMenu();

			case GAME:
			factory.startPlay();

			case END:
			factory.startLevelSelect();
		}

		app.init = false;
	}
}