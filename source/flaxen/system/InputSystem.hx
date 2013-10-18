package flaxen.system;

import ash.core.Engine;
import ash.core.System;
import ash.core.Node;
import ash.core.Entity;

import com.haxepunk.utils.Key;
import com.haxepunk.HXP;

import flaxen.node.ControlNode;
import flaxen.node.EditorObjectNode;
import flaxen.service.EntityService;
import flaxen.service.InputService;
import flaxen.service.SaveService;
import flaxen.component.Firing;
import flaxen.component.Application;
import flaxen.component.Control;
import flaxen.component.Sound;
import flaxen.component.Level;
import flaxen.component.Editor;
import flaxen.component.Timestamp;
import flaxen.component.Position;
import flaxen.component.Tween;
import flaxen.component.CameraFocus;
import flaxen.util.Easing;
import flaxen.util.Util;

#if profiler
	import flaxen.service.ProfileService;
#end

#if (development && !flash)
import sys.io.FileOutput;
#end

class InputSystem extends System
{
	public var engine:Engine;
	public var factory:EntityService;

	public function new(engine:Engine, factory:EntityService)
	{
		super();
		this.engine = engine;
		this.factory = factory;
		InputService.init();
	}

	override public function update(_)
	{
		handleProfileControl();
		handleCheats();
		handleFireControl();
		handlePopupControl();
		handleMenuControl();
		handleLevelEndingControl();
		handleRocketingControl();
		handleLevelEndControl();
		handleEditorControl();
		handleGameEndControl();
		handleDebugControl();
		InputService.clearLastKey();
	}

	public function handleEditorControl(): Void
	{
	#if (development && !flash)
		if(factory.hasControl(EditorControl) && InputService.lastKey() == Key.E)
		{
			InputService.clearLastKey();
			factory.toggleEditor();
		}

		if(!factory.hasControl(EditControl))
			return;

		if(InputService.clicked)
		{
 			var x = InputService.mouseX;
 			var y = InputService.mouseY;
 			var selectedNode:EditorObjectNode = null;
			for(object in engine.getNodeList(EditorObjectNode))
			{
				if(factory.hitTest(object.entity, x, y))
				{
					selectedNode = object;
					break;
				}
			}

			if(selectedNode != null)
				trace("Selecting " + selectedNode.entity.name);
			else trace("Nothing selected.");

			// Add current on-deck editor object
			if(selectedNode == null)
				factory.editorAdd(x, y);

			// Change selector to this object, if it's clickable
			else if(selectedNode.editorObject.editable)
				factory.editorSelect(selectedNode.entity);
		}
		else switch (InputService.lastKey())
		{
			case Key.P:
			#if snapshots
				factory.takeSnapshots();
			#else
				trace("Cannot make snapshots without defining 'snapshots' in project.xml.");
			#end

			// Delete currently selected object
			// Write change to level XML
			case Key.BACKSPACE:
			factory.editorDeleteSelected();
			
			// Switch to previous on-deck editor object
			case Key.LEFT_SQUARE_BRACKET:
			factory.editorPreviousDeck();

			// Switch to next on-deck editor object
			case Key.RIGHT_SQUARE_BRACKET:
			factory.editorNextDeck();

			case 190: // >.
			factory.editorNextLevel();

			case 188: // <,
			factory.editorPreviousLevel();

			// Write XML changes to file
			case Key.S:
			factory.editorSave();

			// Reload XML from file
			case Key.L:
			factory.editorLoad();

			// Set editor mode to "value entry"
			case Key.N:
			factory.editorRecordSequence("N");

			// Set editor mode to "level entry"
			case Key.J:
			factory.editorRecordSequence("J");

			// Set editor mode to "best entry"
			case Key.B:
			factory.editorRecordSequence("B");

			// Exit value/level entry for editor mode
			// If value mode, change value of object on screen and in xml
			// If level mode, load numerically entered level
			case Key.ENTER:
			factory.editorResolveSequence();

			case Key.UP:
			factory.editorMoveSelected(0, -10);
			
			case Key.DOWN:
			factory.editorMoveSelected(0, 10);
			
			case Key.LEFT:
			factory.editorMoveSelected(-10, 0);
			
			case Key.RIGHT:
			factory.editorMoveSelected(10, 0);
			
			// Update "last number entered"
			// Existing number *= 10 + new digit.					
			default:
			var str = String.fromCharCode(InputService.lastKey());
			// trace("Pressed: " + str + " code:" + InputService.lastKey());
			if(Util.isNumeric(str))
				factory.editorRecordSequence(str);
		}
	#end
	}

	public function handleProfileControl()
	{
		#if profiler 
	 	for(node in engine.getNodeList(ProfileControlNode))
	 	{
	 		if(InputService.lastKey() == Key.P)
	 		{
	 			ProfileService.dump();
	 			ProfileService.reset();
	 			InputService.clearLastKey();
	 		}
	 	}
		#end
	} 

	public function handleDebugControl(): Void
	{
		#if development
		// Flush and rebuild display objects, for debugging
		// This doesn't work so well...
		// if(InputService.pressed(Key.TAB))
		// 	for(node in engine.getNodeList(flaxen.node.DisplayNode))
		// 		node.entity.remove(flaxen.component.Display);

		if(InputService.pressed(InputService.debug))
		{
			#if flash
				haxe.Log.clear();

			#else
				var path:String = "/Users/elund/Development/reRocket/entities.log";
				Util.dumpLog(engine, path);
				// trace(Util.dumpHaxePunk(com.haxepunk.HXP.scene));
			#end

			trace("Entity list:");	
			for(e in engine.entities)
				trace(" * " + e.name);			
		}
		#end
	}

	public function handleCheats()
	{
		#if cheats
			if(!factory.hasControl(EditControl))
			{	
				if(InputService.pressed(Key.DIGIT_1))
				{
					trace("Cheat 1: Played some levels");
					var level = factory.getConfig().get(Level);
					level.testGotStarted();
					SaveService.save(level.exportSave());
					factory.getApplication().changeMode(ApplicationMode.MENU);
				}

				else if(InputService.pressed(Key.DIGIT_2))
				{
					trace("Cheat 2: Played all levels");
					var level = factory.getConfig().get(Level);
					level.testGotToEnd();
					SaveService.save(level.exportSave());
					factory.getApplication().changeMode(ApplicationMode.MENU);
				}

				else if(InputService.pressed(Key.DIGIT_3))
				{
					trace("Cheat 3: Got all stars");
					var level = factory.getConfig().get(Level);
					level.testGotAllStars();
					SaveService.save(level.exportSave());
					factory.getApplication().changeMode(ApplicationMode.MENU);
				}
		 		else if(InputService.pressed(Key.C))
		 			factory.emptyAllFireworks();
			}
		#end

		if(!factory.hasControl(FireControl))
			return;

		checkRestart();

 		#if development
	 		if(InputService.pressed(Key.O))
	 		{
	 			SaveService.clear();
	 			trace("Cleared shared object");
				factory.getApplication().changeMode(ApplicationMode.INIT);
			}

		#end
	}


	public function handleFireControl()
	{
		if(!factory.hasControl(FireControl))
			return;

 		if(InputService.pressed(Key.ESCAPE) || isButtonPressed(EntityService.BACK_BUTTON))
 		{
 			// TODO Pop up ARE YOU SURE
			factory.addSound(Sound.CLICK);
			factory.getApplication().changeMode(ApplicationMode.MENU); 			 			
 		}

 		else if(InputService.pressed(Key.ENTER))
 			factory.switchActiveOrb();

 		else if(InputService.pressed(Key.SPACE))
 		{
 			var now = Timestamp.now();
	 		var tube = engine.getEntityByName("tube");
	 		if(!tube.has(Firing))
 				tube.add(new Firing(now));
 		}

 		else if(InputService.released(Key.SPACE))
 		{
	 		var tube = engine.getEntityByName("tube");
	 		if(tube.has(Firing))
 				tube.get(Firing).end = Timestamp.now();
 		}

 		else if(InputService.clicked)
 			moveCamera();
	}

	public function handlePopupControl()
	{
		if(!factory.hasControl(PopupControl))
			return;

		// Tutorial - wait for input and just continue
		if(factory.entityExists("enter") &&
			(InputService.pressed(Key.ENTER) || isButtonPressed("enter")))
		{
			removePopup();
			// Existing action queue should wait for popup removal and then continue automatically
		}

		// NEW GAME? Yes - clear existing game and start playing
		else if(factory.entityExists("yes") &&
			(InputService.pressed(Key.Y) || isButtonPressed("yes")))
		{
			// Wait for popup removal and then start new game
			var aq = factory.addActionQueue();
			aq.addThread(function() 
			{
				return !factory.entityExists("popup");
			});
			aq.addCallback(function()
			{
				// Clear saved game and go to game mode
				factory.clearSave();
	 			factory.getApplication().changeMode(GAME);
			});
			removePopup();
		}

		// NEW GAME? No - remove popup and return to menu
		else if(factory.entityExists("no") &&
			(InputService.pressed(Key.N) || isButtonPressed("no")))
		{
			// Wait for popup removal and then restore menu control
			var aq = factory.addActionQueue();
			aq.addThread(function() 
			{
				return !factory.entityExists("popup");
			});
			aq.addCallback(function() { factory.addControl(MenuControl.instance); });
			removePopup();
		}

		else if(factory.entityExists("popup") && isButtonPressed("popup"))
		{
			// Do nothing when popup window interior clicked
		}
	}

	public function removePopup()
	{
		// Remove popup control
		factory.addSound(Sound.CLICK);
		factory.removeControl(PopupControl);

		// Animate away popup
		var e = factory.getEntity("popup");
		var t = new Tween(e.get(Position), { x:600 }, 0.6, Easing.easeInCubic);
		t.destroyEntity = true;
		e.add(t);
	}

	public function handleMenuControl()
	{
		var level = factory.getConfig().get(Level);
	 	for(node in engine.getNodeList(MenuControlNode))
	 	{
	 		// Just one thing to click on
	 		if(InputService.clicked || InputService.lastKey() != 0)
	 		{
	 			if(isButtonPressed(EntityService.MAINMENU_NEW) ||
	 				InputService.pressed(Key.N))
	 			{
					factory.addSound(Sound.CLICK);

					if(level.progress > 0) // erase game progress? confirm first
					{
		 				factory.removeControl(MenuControl);	
		 				factory.addPopup("Starting a new game will erase your existing progress. " + 
		 					"Are you sure you want to start a new game?", "START OVER?", true);
					}
					else // never played - just start new game
			 			factory.getApplication().changeMode(GAME);
	 			}

	 			else if(isButtonPressed(EntityService.MAINMENU_CONTINUE) || 
	 				InputService.pressed(Key.C))
	 			{
	 				if(level.gameOver || level.progress < 1)
	 					return;

	 				level.current = level.progress + 1;
					factory.addSound(Sound.CLICK);
		 			factory.getApplication().changeMode(ApplicationMode.GAME);
	 			}

	 			else if(isButtonPressed(EntityService.MAINMENU_SELECT) || 
	 				InputService.pressed(Key.L))
	 			{
	 				if(level.progress <= 0)
	 					return;

					factory.addSound(Sound.CLICK);
		 			factory.getApplication().changeMode(ApplicationMode.END);
	 			}

	 			else if(isButtonPressed(EntityService.MAINMENU_MUTE) || 
	 				InputService.pressed(Key.A))
	 			{
					factory.addSound(Sound.CLICK);
					factory.toggleMute();
	 			}
	 		}
	 	}
	}

	private function isButtonPressed(buttonName:String): Bool
	{
		if(!InputService.clicked)
			return false;

		var e = factory.getEntity(buttonName);
		if(e == null)
			return false;

		var alpha = e.get(flaxen.component.Alpha);
		if(alpha != null && alpha.value < 1.0)
			return false;
	 			
	 	return factory.hitTest(e, InputService.mouseX, InputService.mouseY);
	}

	public function handleLevelEndingControl()
	{
		if(factory.hasControl(LevelEndingControl))
			checkRestart();
	}

	public function handleRocketingControl()
	{
		if(factory.hasControl(RocketingControl))
			checkRestart();
	}

	public function handleLevelEndControl()
	{
	 	for(node in engine.getNodeList(LevelEndControlNode))
	 	{
 			if(isButtonPressed(EntityService.LEVELEND_REPLAY) || InputService.pressed(Key.R))
 			{
				factory.addSound(Sound.CLICK);
	 			factory.restartLevel();	 				
 			}
 			else if(isButtonPressed(EntityService.LEVELEND_CONTINUE) || InputService.pressed(Key.C))
 			{
				factory.addSound(Sound.CLICK);

 				// Check if at last level, if so go to final summary screen, otherwise load next level
				var level = factory.getConfig().get(Level);
				if(level.progress >= level.max || level.gameOver)
				{
					level.gameOver = true;
					factory.getApplication().changeMode(ApplicationMode.END);
				}
 				else factory.changeLevelTo(level.progress + 1);
 			}
	 	}
	}

	// e.g. Level Select
	public function handleGameEndControl(): Void
	{
		if(!factory.hasControl(GameEndControl))
			return;

 		if(InputService.pressed(Key.ESCAPE) || isButtonPressed(EntityService.BACK_BUTTON))
 		{
			factory.addSound(Sound.CLICK);
			factory.getApplication().changeMode(ApplicationMode.MENU);
			return; 			
 		}

 		if(!InputService.clicked)
 			return;

		var level = factory.getConfig().get(Level);
		for(i in 1...level.max+1)
		{
			var name = "level" + i;
			if(isButtonPressed(name))
			{
				if(i > level.progress + 1 && !level.gameOver)
					factory.addSound(Sound.DENIED);
				else
				{
					factory.addSound(Sound.CLICK);
					level.current = i;
					factory.getApplication().changeMode(ApplicationMode.GAME);
				}
				return;
			}
		}
	}

	public function moveCamera()
	{
		factory.addSound(Sound.CLICK);

		if(factory.entityExists("cameraLock"))
			factory.addTip("Use the SPACEBAR to fire a rocket");
		else
		{
			factory.addTip("Moving camera. Hit ENTER to center over a barrel.");
 			var manualFocus = factory.resolveEntity(CameraFocus.MANUAL_FOCUS_ENTITY);
 			var x = InputService.mouseX + HXP.camera.x;
 			var y = InputService.mouseY + HXP.camera.y;
 			manualFocus.add(new Position(x, y));
 			factory.changeCameraFocus(manualFocus);
 		}
	}

	public function checkRestart()
 	{
 		if(InputService.pressed(Key.R))
 		{
			factory.addSound(Sound.CLICK);
 			factory.restartLevel();		
 		}
 	}
}
