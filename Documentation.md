# SWDUI Documentation
### Dominik Stücheli, XXXXXX

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/dominikstuecheli-105D-Engineering/BetterSlotAssign2/blob/main/BSA2/105DLogo.png?raw=true">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/dominikstuecheli-105D-Engineering/BetterSlotAssign2/blob/main/BSA2/105DLogoBright.png?raw=true">
  <img alt="Logo" src="https://github.com/dominikstuecheli-105D-Engineering/BetterSlotAssign2/blob/main/BSA2/105DLogo.png?raw=true">
</picture>

## How to use

SWDUI has to be minimized using LifeBoatAPI. If you have not used LifeBoatAPI before, try to understand the basics before trying to use SWDUI.

SWDUI is not small on a Stormworks LUA-script scale. Even tho only the parts you need are included in the compressed output code, character count quickly rises when using a lot of different types of Views. But, by far the largest part of that is the framework itself and not the code that depends on it: Therefore, using SWDUI makes the most sense for UI-heavy applications where not a lot of other logic code is required.

### Using SWDUI in LifeBoatAPI
Put the SWDUI.lua file into _build/libs.

write
```lua
require("SWDUI")
```
at the top of your file.

use drawOnScreen(...) in onDraw():
```lua
function onDraw() drawOnScreen(
    --Your UI code goes here
) end
```

## Architecture

### View
```lua
function View(drawFunction) return table end
```
where
```lua
drawFunction: function (x: number, y: number, width: number, height: number) end
```
Views are the core that the whole framework builds upon.

Even tho View itself is a function, When talking about Views, View refers to the table returned by that function.

The drawFunction draws the view to the screen at the coordinates (x, y) with the size (width, height).

A View contains information about preferred sizing and positioning at the following keys:
|Key |Type   |Default value   |Description  |
|-  |-  |-  |-  |
|minWidth   |number |0 |The minimum width
|minHeight   |number |0 |The minimum height
|maxWidth   |number |infinity |The maximum Width
|maxHeight   |number |infinity |The maximum Height
|horizontalAlignment |number   |0 |The horizontal alignment if the width available is greater than the views max width
|verticalAlignment |number   |0 |The vertical alignment if the height available is greater than the views max height
|offsetX   |number |0 |The horizontal offset the view is drawn at
|offsetY   |number |0 |The vertical offset the view is drawn at

### View modifiers
```lua
someViewModifier = function (self, arguments) return self end
```
View modifiers are methods of a View. They modify the view and return it, which means they can be chained:
```lua
SomeView()
    :someViewModifier()
    :someOtherViewModifier()
```
or
```lua
SomeView():someViewModifier():someOtherViewModifier()
```

### Drawing to the screen
A Views draw function is called with the draw(...) method:
```lua
SomeView():draw(x: number, y: number, width: number, height: number)
```
The use of the colon operator is very important here, as the function needs the views parameters.

If the draw(...) method is called on multiple Views in the same onDraw(), they will not respect each other. It is heavily recommende to use the drawOnScreen(...) function:
```lua
function drawOnScreen(view: View)
```
This function automatically draws a View at full size using the Stormworks screens width and height.

All views are recalculated and redrawn on every frame. This may be inefficient performance-wise, however, it simplifies the structure a lot. Even complex View structures should not take more than a couple of milliseconds to calculate and draw.

### Touch input
```lua
cursorX = 0
cursorY = 0
cursorPressed = false
cursorPressedOnLastTick = false
cursorPressedPulse = false

function setCursor(xPos: number, yPos: number, isPressed: boolean) end
```
For touch inputs to work, for example for the Button View, setCursor(...) has to be called in onTick(). That would typically look like this:
```lua
function onTick()
    setCursor(input.getNumber(3), input.getNumber(4), input.getBool(1))
end
```

### Making your own View
If the built-in Views do not provide whats needed, custom Views can be built like this:
```lua
function MyOwnView(arguments)
    return View(function (x,y,width,height)
        --Your drawing code
    end)
end
```
Make sure to always use the View(...) function.

### Making your own View modifier
If the built-in View modifiers do not provide whats needed, custom modifiers can be built like this:
```lua
function viewModifiers:myOwnViewModifier(arguments)
    --Your modifier code
    return self
end
```
Because all View modifiers are initially stored in the viewModifiers table, you can add your own modifiers there.

Be sure to use the colon operator to have access to self, as well as to return self when the modifier is done.

Modifiers changing something in the draw(...) function can be achieved like this:
```lua
function viewModifiers:myOwnViewModifier(arguments)
    local oldDraw = self.draw
    self.draw = function (self, x,y,width,height)
        --Your code that should be executed before the View is drawn as it was before
        oldDraw(self, x,y,width,height)
    end
    return self
end
```

### View state
```lua
viewStates = {}
```
View states of Views that require it are stored globally in the viewStates table. Views that require state have to be given an identifier: This is the key in the viewStates table at which that Views state is stored. It is recommended to use strings as identifers.

**Identifiers have to be unique.**

## Views

### HStack & VStack
```lua
function HStack(viewTable: View[]) return View end
function VStack(viewTable: View[]) return View end
```
The HStack and VStack stack the Views in the viewTable horizontally or vertically respectively.

Views are not drawn at an equal size if their size constraints do not allow so. If one View is only allowed to take up very little space or requires a lot of Space, all others expand or contract to utilise the provided Space fully. 

The HStack and VStack set their own sizes according to the minimum and maximum size of all of their contained Views combined.

### ZStack
```lua
function ZStack(viewTable: View[]) return View end
```
The ZStack stacks the Views in the viewTable over each other. They will all occupy the same Space.

The ZStack sets its own size as the size of the largest of its contained Views.

### Spacer
```lua
function Spacer(size: number?) return View end
```
A Spacer does not draw anything to the screen. It fills the space it is provided or fixes its size at size if given.

### Pages
```lua
function Pages(
    identifier: any, --see Architecture: View states 
    openedPage: number,
    animationDuration: number,
    pageTable: View[]
) return View end
```
The Pages View displays the View at pageTable[openedPage]. openedPage should be an integer as animation is handled internally.

Page switching is animated with a sliding animation. animationDuration is in seconds.

The Pages View sets its own size as the size of the largest of the page Views.

### IfTrue
```lua
function IfTrue(
    identifier: any, --see Architecture: View states
    state: boolean,
    animationDuration: number,
    view: View
) return View end
```
IfTrue only draws view when state is true.

The transition is animated. animationDuration is in seconds.

If state is true, IfTrue will copy the size of view. if state is false, IfTrue will shrink until not taking up any space.

### forEach
```lua
function forEach(items: any[], getItemView) return View[] end
```
where
```lua
getItemView: function (item: any, itemIndex: number) return View end
```
forEach is not a View itself. It returns a table of Views and is meant to be used in combination with Views that take tables of Views as inputs, for example H-, V- and ZStack or Pages.

forEach will call getItemView for each item in items and adds the View returned by that function to the View table that will be returned by ForEach.

An example application would be:
```lua
todo = {
    "Write documentation",
    "Fix issues",
    "Make Github repository"
}

function onDraw() drawOnScreen(
    VStack(ForEach(
        todo,
        function (todoItem) return Text(todoItem) end
    ))
) end
```

### FilledRectangle
```lua
function FilledRectangle() return View end
```
Draws a filled rectangle.

### RoundedRectangle
```lua
function RoundedRectangle() return View end
```
Draws a rectangle with one pixel chipped out in each corner to look like a slightly rounded rectangle.

### RectangleBorder
```lua
function RectangleBorder() return View end
```
Draws the outline of a rectangle.

### Text
```lua
function Text(text: string, horizontalAlignment: number?, verticalAlignment: number?) return View end
```
Draws a text box with the text aligned by the specified alignment values. These alignment values are seperate from the alignment values of the View itself. It is recommended to leave the maxWidth and maxHeight View properties as infinity to prevent weird alignment behaviour.

If an alignment value is not specified, it is set to 0.

### Button
```lua
function Button(
    labelView: View,
    labelViewIfPressed: View,
    onlyExecuteOneTick: boolean,
    displayAsPressedAnyways: boolean,
    clickAction: function () end
) return View end
```
The Button View only works when setCursor(...) is called in onTick().

If Button is pressed or displayAsPressedAnyways is true, labelViewIfPressed is displayed. otherwise, labelView is displayed.

If onlyExecuteOneTick is true, clickAction(...) is only executed on the first frame the Button is pressed. Otherwise, it is executed on every frame the button is pressed.

### ProgressBar
```lua
function ProgressBar(value: number, orientation: number) return View end
```

Displays a Rectangle that is only filled to the "level" defined by value.

Following orientations are supported:
|orientation value |Direction   |
|-  |-  |
|1   |Bottom to Top |
|2   |Left to Right |
|3   |Top to Bottom |
|4   |Right to Left |


## View modifiers

### align
```lua
function View:align(horizontalAlignment: number, verticalAlignment: number) return self end
```
Modifies the Views alignment values

### offset
```lua
function View:offset(offsetX: number, offsetY: number) return self end
```
Modifies the Views offset values

### size
```lua
function View:size(
    minWidth: number?,
    minHeight: number?,
    maxWidth: number?,
    maxHeight: number?
) return self end
```
Modifies the Views size values. nil values are allowed if a value should not be changed.

### fixedSize
```lua
function View:fixedSize(width: number?, height: number?) return self end
```
Sets the Views size to a fixed value. nil values are allowed if the size in one dimension should not be fixed.

### padding
```lua
function View:padding(paddingValue: number) return self end
```
Adds a padding/margin around the View.

### individualPadding
```lua
function View:individualPadding(paddings: [number?, number?, number?, number?]) return self end
```
Adds side-specific paddings to the View. Each index in the paddings table corresponds to one side as follows:
|index |Side   |
|-  |-  |
|1   |Top |
|2   |Right/Trailing |
|3   |Bottom |
|4   |Left/Leading |

### color
```lua
function View:color(r: number, g: number?, b: number?, a: number?) return self end
```
Draws the View in the specified colors. The Views draw function is executed after the color is set; screen.setColor(...) calls in the draw function will therefore not be affected.

If a is nil, the View will be drawn at full opacity.
If g and b are nil, they will be set to the value of r, resulting in a greyscale color with the value of r.

### overlay
```lua
function View:overlay(overlayView: View) return View end
```
Draws the overlayView over the View. The View returned is not the View itself but a new ZStack.

The new Views size is adjusted to the larger of the two.

### background
```lua
function View:background(backgroundView: View) return View end
```
Draws the backgroundView behind the View. The View returned is not the View itself but a new ZStack.

The new Views size is adjusted to the larger of the two.

### backgroundColor
```lua
function View:backgroundColor(r: number, g: number?, b: number?, a: number?) return View end
```
Draws a filled rectangle with the specified color behind the View. The View returned is not the View itself but a new ZStack.

The new Views maximum size is set to infinity.

### onClick
```lua
function View:onClick(clickAction: function () end, onlyExecuteOneTick: boolean?) return self end
```
Executes onClick when the View is pressed. Only works when setCursor(...) is called in onTick().

If onlyExecuteOneTick is true or nil, clickAction(...) is only executed on the first frame the View is pressed. Otherwise, it is executed on every frame the View is pressed.