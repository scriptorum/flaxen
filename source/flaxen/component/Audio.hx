package flaxen.component;

import openfl.media.SoundChannel;
import flaxen.component.Timestamp;

/**
 * Low level "SoundChannel" wrapper.
 */
class Audio
{
	/** Direct access to the OpenFL/Flash SoundChannel. */
	public var channel:SoundChannel;

	/** Time when sound began playing */
	public var startTime:Int;

	public function new(channel:SoundChannel)
	{
		this.channel = channel;
		startTime = Timestamp.now();
	}
}

class GlobalAudio
{
	/** Stop new audio from playing; see `mute()` */
	public var muted:Bool = false;		

	/** Audio volume multiplier */
	public var volume:Float = 1.0;		

	/* Stop existing playing audio; see `stop()` */
	public var stopping:Bool = false;	
	
	/* Optional w/stopping, audio after cutoff is left playing; see `stop()` */
	public var cutoff:Timestamp; 		

	public function new() { }

	public function mute(): Void
	{
		muted = true; 	// prevent all new audio from playing
		stop(); 		// stop all current playing audio
	}

	/**
	 * Stops all sounds that are playing.
	 *
	 * If you supply a cutoff value, any sounds that began playing AFTER this cutoff
	 * will not be stopped.
	 */
	public function stop(cutoff:Timestamp = null): Void
	{
		stopping = true;
		this.cutoff = cutoff;
	}
}