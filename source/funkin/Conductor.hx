package funkin;

import flixel.util.FlxSignal;
import funkin.SongLoad.SwagSong;
import funkin.play.song.Song.SongDifficulty;
import funkin.play.song.SongData.SongTimeChange;

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
}

class Conductor
{
	/**
	 * The list of time changes in the song.
	 * There should be at least one time change (at the beginning of the song) to define the BPM.
	 */
	private static var timeChanges:Array<SongTimeChange> = [];

	/**
	 * The current time change.
	 */
	private static var currentTimeChange:SongTimeChange;

	/**
	 * The current position in the song in milliseconds.
	 * Updated every frame based on the audio position.
	 */
	public static var songPosition:Float;

	/**
	 * Beats per minute of the current song at the current time.
	 */
	public static var bpm(get, null):Float;

	static function get_bpm():Float
	{
		if (bpmOverride != null)
			return bpmOverride;

		if (currentTimeChange == null)
			return 100;

		return currentTimeChange.bpm;
	}

	static var bpmOverride:Null<Float> = null;

	// OLD, replaced with timeChanges.
	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	/**
	 * Duration of a beat in millisecond. Calculated based on bpm.
	 */
	public static var crochet(get, null):Float;

	static function get_crochet():Float
	{
		return ((60 / bpm) * 1000);
	}

	/**
	 * Duration of a step in milliseconds. Calculated based on bpm.
	 */
	public static var stepCrochet(get, null):Float;

	static function get_stepCrochet():Float
	{
		return crochet / 4;
	}

	public static var currentBeat(get, null):Int;

	static function get_currentBeat():Int
	{
		return currentBeat;
	}

	public static var currentStep(get, null):Int;

	static function get_currentStep():Int
	{
		return currentStep;
	}

	public static var beatHit(default, null):FlxSignal = new FlxSignal();
	public static var stepHit(default, null):FlxSignal = new FlxSignal();

	public static var lastSongPos:Float;
	public static var visualOffset:Float = 0;
	public static var audioOffset:Float = 0;
	public static var offset:Float = 0;

	private function new()
	{
	}

	public static function getLastBPMChange()
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];

			if (Conductor.songPosition < Conductor.bpmChangeMap[i].songTime)
				break;
		}
		return lastChange;
	}

	@:deprecated // Use loadSong with metadata files instead.
	public static function forceBPM(bpm:Float)
	{
		Conductor.bpmOverride = bpm;
	}

	/**
	 * Update the conductor with the current song position.
	 * BPM, current step, etc. will be re-calculated based on the song position.
	 * 
	 * @param	songPosition The current position in the song in milliseconds.
	 *        Leave blank to use the FlxG.sound.music position.
	 */
	public static function update(songPosition:Float = null)
	{
		if (songPosition == null)
			songPosition = (FlxG.sound.music != null) ? (FlxG.sound.music.time + Conductor.offset) : 0;

		var oldBeat = currentBeat;
		var oldStep = currentStep;

		Conductor.songPosition = songPosition;
		// Conductor.bpm = Conductor.getLastBPMChange().bpm;

		currentTimeChange = timeChanges[0];
		for (i in 0...timeChanges.length)
		{
			if (songPosition >= timeChanges[i].timeStamp)
				currentTimeChange = timeChanges[i];

			if (songPosition < timeChanges[i].timeStamp)
				break;
		}

		if (currentTimeChange == null && bpmOverride == null)
		{
			trace('WARNING: Conductor is broken, timeChanges is empty.');
		}
		else if (currentTimeChange != null)
		{
			currentStep = Math.floor((currentTimeChange.beatTime * 4) + (songPosition - currentTimeChange.timeStamp) / stepCrochet);
			currentBeat = Math.floor(currentStep / 4);
		}
		else
		{
			// Assume a constant BPM equal to the forced value.
			currentStep = Math.floor((songPosition) / stepCrochet);
			currentBeat = Math.floor(currentStep / 4);
		}

		// FlxSignals are really cool.
		if (currentStep != oldStep)
			stepHit.dispatch();

		if (currentBeat != oldBeat)
			beatHit.dispatch();
	}

	@:deprecated // Switch to TimeChanges instead.
	public static function mapBPMChanges(song:SwagSong)
	{
		bpmChangeMap = [];

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i in 0...SongLoad.getSong().length)
		{
			if (SongLoad.getSong()[i].changeBPM && SongLoad.getSong()[i].bpm != curBPM)
			{
				curBPM = SongLoad.getSong()[i].bpm;
				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM
				};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = SongLoad.getSong()[i].lengthInSteps;
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}
	}

	public static function mapTimeChanges(currentChart:SongDifficulty)
	{
		var songTimeChanges:Array<SongTimeChange> = currentChart.timeChanges;

		timeChanges = [];

		for (currentTimeChange in songTimeChanges)
		{
			// var prevTimeChange:SongTimeChange = timeChanges.length == 0 ? null : timeChanges[timeChanges.length - 1];

			/*
				if (prevTimeChange != null)
				{
					var deltaTime:Float = currentTimeChange.timeStamp - prevTimeChange.timeStamp;
					var deltaSteps:Int = Math.round(deltaTime / (60 / prevTimeChange.bpm) * 1000 / 4);

					currentTimeChange.stepTime = prevTimeChange.stepTime + deltaSteps;
				}
				else
				{
					// We know the time and steps of this time change is 0, since this is the first time change.
					currentTimeChange.stepTime = 0;
				}
			 */

			timeChanges.push(currentTimeChange);
		}

		trace('Done mapping time changes: ' + timeChanges);

		// Done.
	}
}
