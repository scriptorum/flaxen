/**
	This class is used by Tween and Animation to describe various behaviors of repetition.

	TODO:
	 - Add support for Random?
*/
package flaxen.common;

enum LoopType
{ 
	None; 			// No looping, plays once in sequence order and disappears
	Forward; 		// Plays in sequence order and loops
	Backward; 		// Plays in reverse sequence order and loops
	Both; 			// Plays in sequence order, then reverse sequence order, then loops
	BothBackward; 	// Plays in reverse sequence order, then sequence order, then loops
}
