#Flaxen
##Overview
> You've got Haxepunk in my Ash! You got Ash in my Haxepunk!

Flaxen is a Haxe 3 project that combines [HaxePunk](https://github.com/HaxePunk/HaxePunk) (a game engine) with [Ash-Haxe](https://github.com/nadako/Ash-HaXe) (an entity component system or ECS).  

### Example
Flaxen makes it simply to create entities and add components to them. The built-in RenderingSystem automatically creates the appropriate HaxePunk objects behind the scenes. This example displays an object and centers it on the screen.

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

##Documenntation
Documentation is finally up in the [wiki](https://github.com/scriptorum/flaxen/wiki)!

##Dependencies
Flaxen would not be possible without the work of these awesome projects:
* [HaxePunk](https://github.com/HaxePunk/HaxePunk) 
* [Ash-Haxe](https://github.com/nadako/Ash-HaXe)
* [OpenFL](http://www.openfl.org/)
* [Haxe](http://haxe.org)

##The MIT License (MIT)

Copyright (c) 2014 Eric Lund

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
