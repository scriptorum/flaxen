//
// The entity-specific stuff should be moved to Flaxen itself
// The other stuff deserves its own service
// If a service requires a universal object as the first parameter, call it a MixIn instead.
//

package flaxen.service;

import com.haxepunk.HXP;

import ash.core.Engine;
import ash.core.Entity;
import ash.core.Node;

import openfl.Assets;

import flaxen.component.ActionQueue;
import flaxen.component.Animation;
import flaxen.component.Application;
import flaxen.component.CameraFocus;
import flaxen.component.Control;
import flaxen.component.Dependents;
import flaxen.component.Audio;
import flaxen.component.Image;
import flaxen.component.Offset;
import flaxen.component.Position;
import flaxen.component.Size;
import flaxen.component.Sound;
import flaxen.component.Timestamp;
import flaxen.component.Tween;
import flaxen.node.TransitionalNode;
import flaxen.node.CameraFocusNode;
import flaxen.node.SoundNode;
import flaxen.util.Easing;
import flaxen.util.Util;

using StringTools;

class DependentsNode extends Node<DependentsNode>
{
	public var dependents:Dependents;
}

class EntityService
{
	public static inline var CONTROL:String = "control";
	public static inline var APPLICATION:String = "application";
	public static inline var GLOBAL_AUDIO_NAME:String = "globalAudio";

	public var engine:Engine;
	public var nextId:Int = 0;

	public function new(engine:Engine)
	{
		this.engine = engine;
		engine.getNodeList(DependentsNode).nodeRemoved.add(dependentsNodeRemoved); // entity lifecycle dependency
	}

	public function makeEntity(prefix:String): Entity // does NOT add entity to engine
	{
		var name = prefix + nextId++;
		return new Entity(name);
	}

	public function getApplication(): Application
	{
		var e = resolveEntity(APPLICATION);
		var app = e.get(Application);
		if(app == null)
		{
			app = new Application();
			e.add(app);
			e.add(Transitional.Always);
		}
		return app;
	}

	// Finds or makes a named entity and adds it to the engine
	public function resolveEntity(name:String): Entity
	{
		var e = engine.getEntityByName(name);
		if(e != null)
			return e;
		return add(new Entity(name));
	}

	public function add(entity:Entity): Entity
	{
		engine.addEntity(entity);
		return entity;
	}

	public function addTo(e:Entity, x:Float, y:Float): Entity
	{
		e.add(new Position(x, y));
		return add(e);
	}

	public function transitionTo(mode:ApplicationMode): Void
	{
		// Remove all entities, excepting those marked as transitional for this mode
		for(e in engine.entities)
		{
			if(e.has(Transitional))
			{
				var transitional:Transitional = e.get(Transitional);
				if(transitional.isProtected(mode))
				{
					if(transitional.destroyComponent)
						e.remove(Transitional);
					else 
						transitional.complete = true;					
					continue;
				}
			}

			engine.removeEntity(e);
		}
	}

	public function removeTransitionedEntities(matching:String = null, excluding:String = null)
	{
		for(node in engine.getNodeList(TransitionalNode))
		{
			if(node.transitional.isCompleted()) // should spare Always transitionals from removal
			{
				if(matching != null && matching != node.transitional.kind)
					continue;
				if(excluding != null && excluding == node.transitional.kind)
					continue;

				engine.removeEntity(node.entity);				
			}
		}
	}

	public function restartApplicationMode(): Void
	{
		var app:Application = getApplication();
		app.init = true;
	}

	private function dependentsNodeRemoved(node:DependentsNode): Void
	{
		removeDependents(node.entity);
	}

	// Creates a lifecycle dependency between entitientityService. When the parent entity
	// is destroyed, all of its dependent children will also be immediately destroyed.
	public function addDependent(parent:Entity, child:Entity): Void
	{		
		// trace("Creating dependency. Parent:" + parent.name + " Child:" + child.name);

		if(child == null)
			throw("Cannot create dependency; child entity does not exist");
		if(parent == null)
			throw("Cannot create dependency; parent entity does not exist");

		var dependents = parent.get(Dependents);
		if(dependents == null)
		{
			dependents = new Dependents();
			parent.add(dependents);
		}

		dependents.add(child.name);
	}

	public function addDependentByName(parentName:String, childName:String): Void
	{
		var parent = engine.getEntityByName(parentName);
		var child = engine.getEntityByName(childName);
		addDependent(parent, child);
	}

	// Destroys all dependents of the entity
	public function removeDependents(e:Entity): Void
	{
		var dependents:Dependents = e.get(Dependents);
		if(dependents == null)
			return;

		for(name in dependents.names)
		{
			var e:Entity = engine.getEntityByName(name);
			if(e != null)
			{
				engine.removeEntity(e);
				// trace("Removing dependent:" + e.name);
			}
			// else trace(" ** Can't remove already gone dependent " + name);
		}
		dependents.clear();
	}

	public function expandMarkerName(markerName:String): String
	{
		return "marker-" + markerName;
	}

	public function hasMarker(markerName:String): Bool
	{
		var name = expandMarkerName(markerName);
		return (engine.getEntityByName(name) != null);
	}

	public function addMarker(markerName:String): Void
	{
		var name = expandMarkerName(markerName);
		if(!hasMarker(name))
			resolveEntity(name);
	}

	public function removeMarker(markerName:String): Void
	{
		var name = expandMarkerName(markerName);
		var entity = engine.getEntityByName(name);
		if(entity != null)
			engine.removeEntity(entity);
	}

	// Entity hit test, does not currently respect the Scale component
	// nor the ScaleFactor component.
	public function hitTest(e:Entity, x:Float, y:Float): Bool
	{
		if(e == null)
			return false;

		var pos = e.get(Position);
		var image = e.get(Image);
		if(image == null && e.has(Animation))
			image = e.get(Animation).image;
		if(pos == null || image == null)
			return false;

		var off = e.get(Offset);
		if(off != null)
		{
			if(off.asPercentage)
			{
				x -= off.x * image.width;
				y -= off.y * image.height;
			}
			else
			{
				x -= off.x;
				y -= off.y;
			}
		}

		return(x >= pos.x && x < (pos.x + image.width) && 
			y >= pos.y && y < (pos.y + image.height));
	}

	public function startInit(): Void
	{
		#if profiler
			ProfileService.init();
			var e = new Entity("profileControl");
			e.add(ProfileControl.instance);
			e.add(Transitional.Always);
			engine.addEntity(e);
		#end
	}

	// public function toggleMute()
	// {
	// 	// Toggle mute flag
	// 	var globalAudio:GlobalAudio = getGlobalAudio();
	// 	if(globalAudio.muted)
	// 	{
	// 		// Turn off mute
	// 		globalAudio.muted = false;

	// 		// Restart music depending on game mode
	// 		// Currently only supports toggle in main menu
	// 		var app:Application = getApplication();
	// 		if(app.mode == ApplicationMode.MENU)
	// 			addSound(Sound.MENU_MUSIC, true);
	// 	}
	// 	else
	// 		globalAudio.mute(); // Mute now

	// 	var e = resolveEntity(MAINMENU_MUTE);
	// 	var tile = e.get(Tile);
	// 	tile.tile = (globalAudio.muted ? 7 : 6);
	// }

	public function changeCameraFocus(entity:Entity): Void
	{
		for(node in engine.getNodeList(CameraFocusNode))
			node.entity.remove(CameraFocus);

		if(entity != null)
			entity.add(CameraFocus.instance);			
	}

	public function addActionQueue(name:String = null): ActionQueue
	{
		var e = makeEntity("aq");
		if(name != null)
			e.name = name;

		var aq = new ActionQueue();
		e.add(aq);
		aq.destroyEntity = true;
		add(e);
		aq.name = e.name;

		return aq;
	}

	public function addTween(source:Dynamic, target:Dynamic, duration:Float, 
		easing:EasingFunction = null, autoStart:Bool = true, name:String = null, 
		parent:String = null): Tween
	{
		var e = makeEntity("tween");
		if(name != null)
			e.name = name;

		var tween = new Tween(source, target, duration, easing, autoStart);
		tween.destroyEntity = true;
		e.add(tween);
		add(e);
		tween.name = e.name;

		if(parent != null)
			addDependentByName(parent, e.name);

		return tween;
	}

	public function addControl(control:Control): Entity
	{
		// trace("Adding control " + Type.typeof(control));
		var e = resolveEntity(CONTROL);
		e.add(control);
		return e;
	}

	public function removeControl(control:Class<Control>): Entity
	{
		var e = resolveEntity(CONTROL);
		e.remove(control);
		return e;
	}

	public function hasControl(control:Class<Control>): Bool
	{
		var e = resolveEntity(CONTROL);
		return e.has(control);
	}

	// Stops all currently playing sounds
	public function stopSounds(): Void
	{
		var globalAudio:GlobalAudio = getGlobalAudio();
		globalAudio.stop(Timestamp.create());
	}

	public function getGlobalAudio(): GlobalAudio
	{
		var entity:Entity = getEntity(GLOBAL_AUDIO_NAME);
		if(entity == null)
		{
			entity = new Entity(GLOBAL_AUDIO_NAME);
			entity.add(new GlobalAudio());
			entity.add(Transitional.Always);
			engine.addEntity(entity);
		}
		return entity.get(GlobalAudio);
	}

	public function stopSound(file:String): Void
	{
		for(node in engine.getNodeList(SoundNode))
		{
			if(node.sound.file == file)
				node.sound.stop = true;
		}
	}

	public function addSound(name:String, loop:Bool = false, offset:Float = 0): Entity
	{
		return add(getSound(name, loop, offset));
	}

	public function getSound(name:String, loop:Bool = false, offset:Float = 0): Entity
	{
		var e = makeEntity("sound");
		var sound = new Sound(name, loop, offset);
		sound.destroyEntity = true;
		e.add(sound);
		return e;
	}

	// Must have initialized engine with RenderMode.BUFFER for this to work
	#if (!flash && FORCE_BUFFER)
	public function snapshot(filename:String, size:Size = null): Void
	{
		var image:com.haxepunk.graphics.Image = HXP.screen.capture();
		if(size != null)
		{
			image.scaleX = size.width / image.width;
			image.scaleY = size.height / image.height;
		}
		var bm:flash.display.BitmapData = new flash.display.BitmapData(Std.int(image.scaleX * image.width), 
			Std.int(image.scaleY * image.height));
		image.render(bm, new flash.geom.Point(0,0), new flash.geom.Point(0,0));
		var ba:flash.utils.ByteArray = bm.encode("png");
		var fo:sys.io.FileOutput = sys.io.File.write(filename);
		fo.write(ba);
		fo.close();
	}
	#end

	// Returns true if the named entity exists in the engine, otherwise false
	public function entityExists(name:String): Bool
	{
		return (engine.getEntityByName(name) != null);
	}
	
	public function getEntity(name:String): Entity
	{
		return name == null ? null : engine.getEntityByName(name);
	}

	public function getComponent<T>(name:String, component:Class<T>): T
	{
		var e:Entity = getEntity(name);
		if(e == null)
			return null;
		return e.get(component);
	}

	public function removeEntity(name:String): Void
	{
		var e:Entity = getEntity(name);
		if(e != null)
			engine.removeEntity(e);
	}

	public function addSimpleEntity(component:Dynamic, ?name:String): Entity
	{
		var e = new Entity(name);
		e.add(component);
		engine.addEntity(e);
		return e;
	}

	public function countNodes<T:Node<T>>(nodeClass:Class<T>): Int
	{
		var count:Int = 0;
	 	for(node in engine.getNodeList(nodeClass))
	 		count++;
	 	return count;
	}
}
