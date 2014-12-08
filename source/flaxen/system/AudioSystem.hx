package flaxen.system;

import flaxen.core.Flaxen;
import flaxen.core.Log;
import flaxen.core.FlaxenSystem;
import flaxen.core.FlaxenSystem;
import flaxen.component.Audio;
import flaxen.component.Sound;
import flaxen.component.Timestamp;
import flaxen.node.SoundNode;
import ash.core.Node;
import ash.core.Entity;
import openfl.Assets;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import openfl.events.Event;

class AudioNode extends Node<AudioNode>
{
	public var sound:Sound;
	public var audio:Audio;
}

class AudioSystem extends FlaxenSystem
{
	public function new(f:Flaxen)
	{ 
		super(f); 
	}

	override public function init()
	{
		ash.getNodeList(AudioNode).nodeRemoved.add(audioNodeRemoved);
	}

	private function audioNodeRemoved(node:AudioNode): Void
	{
		node.audio.channel.stop();
	}

	override public function update(_)
	{
		var globalAudio:GlobalAudio = f.getGlobalAudio();
		if(globalAudio.stopping)
		{
			for(node in ash.getNodeList(AudioNode))
			{
				if(globalAudio.cutoff == null || node.audio.startTime < globalAudio.cutoff.stamp)
					node.sound.stop = true;
			}
			globalAudio.stopping = false;
			globalAudio.cutoff = null;
		}

		for(node in ash.getNodeList(SoundNode))
		{
			var sound = node.sound;
			if(node.entity.has(Audio))
				updateAudio(sound, node.entity, globalAudio);
			else createAudio(sound, node.entity, globalAudio);
		}
	}	

	private function createAudio(sound:Sound, entity:Entity, globalAudio:GlobalAudio): Void
	{
		if(globalAudio.muted)
			return;

		var flSound = Assets.getSound(sound.file);
		if(flSound == null)
		{
			handleFailure(entity, sound, "Cannot load sound");
			return;			
		}

		var channel = flSound.play(sound.offset, (sound.loop ? 0x3FFFFFFF : 0));
		if(channel == null)
		{
			handleFailure(entity, sound, "Cannot create channel");			
			return;
		}

		if(sound.destroyEntity || sound.destroyComponent)
		channel.addEventListener (Event.SOUND_COMPLETE, function(_) 
		{
			sound.complete = true;
		});			

		var audio = new Audio(channel);
		entity.add(audio);
		updateAudio(sound, entity, globalAudio); // set volumes and pans
	}

	private function handleFailure(entity:Entity, sound:Sound, msg:String): Void
	{
		if(sound.failsAllowed > 0)
		{
			sound.failsAllowed--;
			return;
		}

		Log.warn("Sound failure for " + sound.file + " (" + msg + ")");
		ash.removeEntity(entity);
	}

	private function updateAudio(sound:Sound, entity:Entity, globalAudio:GlobalAudio): Void
	{
		var audio = entity.get(Audio);

		if(sound.stop)
		{
			audio.channel.stop();
			sound.complete = true;
			sound.stop = false;
		}

		if(sound.complete)
		{
			if(sound.destroyEntity)	
				ash.removeEntity(entity);
			else if(sound.destroyComponent)
				entity.remove(Audio);	

			return;
		}

		if(sound.restart)
		{
			sound.restart = false;
			audio.channel.stop();
			entity.remove(Audio);
			createAudio(sound, entity, globalAudio);
			return;
		}

		if(audio == null)
			return;

		// Update volume/panning
		var volume:Float = sound.volume * globalAudio.volume;
		if(volume != audio.channel.soundTransform.volume || sound.pan != audio.channel.soundTransform.pan)
			audio.channel.soundTransform = new SoundTransform(volume, sound.pan);
	}
}