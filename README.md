#Flaxen
##Overview
> You've got Haxepunk in my Ash! You got Ash in my Haxepunk!

Flaxen blends an entity/component system with a Haxe-based game engine, powered by [HaxePunk](https://github.com/HaxePunk/HaxePunk) and [Ash](https://github.com/nadako/Ash-HaXe). 

### Features
* ECS-driven design. Create entities, add components to them, and build systems to process and transform those entities.
* Built-in components and systems to automatically display and integrate with HaxePunk graphics. The RenderingSystem supports HaxePunk's Tilemap, Spritemap, Backdrop, Text, and Emitter.
* Access to additional HaxePunk attributes with built-in components to adjust alpha, position, layer, active visibility, rotation, scaling, scroll factor, overall size, registration point, sound, and transformation origin.
* Other features like component-level tweening, audio support, action chaining, transitions, dependent entity management, system-level profiling service, and batch entity transformations via component sets.
* Full access to the Ash engine and HaxePunk objects.

### Developing with Components
Flaxen makes it simple to create entities and add components to them. The built-in RenderingSystem automatically creates the appropriate HaxePunk objects behind the scenes. This example displays an image and centers it on the screen.

```haxe
class BasicImageDemo extends Flaxen
{
	public static function main()
	{
		var demo = new BasicImageDemo();
	}

	override public function ready()
	{
		var e:Entity = newEntity()
			.add(new Image("art/flaxen.png"))
			.add(Position.center())
			.add(Offset.center());
	}
}
```

To get started, documentation is up [on the wiki](https://github.com/scriptorum/flaxen/wiki).

##Dependencies/Credits
Flaxen would not be possible without the work of these awesome projects:
* [HaxePunk](https://github.com/HaxePunk/HaxePunk) 
* [Ash-Haxe](https://github.com/nadako/Ash-HaXe)
* [OpenFL](http://www.openfl.org/)
* [Haxe](http://haxe.org)

##The MIT License (MIT)

Copyright (c) 2013-2015 Eric Lund

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
