package flaxen.component;

import flash.media.SoundChannel;
import flaxen.component.Timestamp;

// Low level "SoundChannel" wrapper
// Stored separately from Sound
// Does for Sound what Display does for View
class Audio
{
	public var channel:SoundChannel;
	public var startTime:Int;

	public function new(channel:SoundChannel)
	{
		this.channel = channel;
		startTime = Timestamp.now();
	}
}

class GlobalAudio
{
	public var muted:Bool = false;		// Stops new audio from playing
	public var volume:Float = 1.0;		// Audio volume multiplier
	public var stopping:Bool = false;	// Stops existing playing audio
	public var cutoff:Timestamp; 		// Optional w/stopping, audio after cutoff is left playing

	public function new() { }

	public function mute(): Void
	{
		muted = true; 	// prevent all new audio from playing
		stop(); 		// stop all current playing audio
	}

	public function stop(cutoff:Timestamp = null): Void
	{
		stopping = true;
		this.cutoff = cutoff;
	}
}