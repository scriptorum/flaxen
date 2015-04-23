package flaxen.component;

/**
 * Intents are a way to decouple input from reaction to that input. When the appropriate
 * input is detected, instead of taking that action, create an Intent. Then in a
 * subsequent system process that Intent. This has two effects. First, it simplifies
 * the InputSystem so it no longer needs to know about operational details of the
 * reaction. Second, it allows a third-party system to introduce its own intents
 * and drive reactions without player inputs.
 *
 * Example: When FireControl is enabled, a player hits spacebar. The InputSystem adds
 * a FireIntent, storing the player's angle. The FireSystem detects this intent
 * and causes the player avatar to fire in the angle specified. In another case,
 * the player is possessed. The PossessedSystem detects this state and at random
 * intervals injects a fireIntent with a random angle. As a result the player 
 * randomly starts randomly firing.
 * 
 * Example subclass to create a FireIntent:
 *```
 * 		class FireIntent extends Intent
 * 		{
 * 			public var angle:Float;
 * 			public function new(angle:Float, ?name:String)
 * 			{
 * 				super(name);
 * 				this.angle = angle;
 * 			}
 * 		}
 *
 * 		flaxen.newEntity().add(new FireIntent(random(360))); 
 *```
 *
 *  - TODO: Work on some practical implementations of this. Is the name variable even '
 *    	helpful? Maybe this should just be a plain interface? Or create a "buildValueClass()"
 *    	macro... note that if you're going to make a custom intent class, you probably don't 
 *    	need to extend Intent to do it.
 */
 class Intent
{
	public var name:String;
	public function new(name:String = "default")
	{
		this.name = name;
	}
}


