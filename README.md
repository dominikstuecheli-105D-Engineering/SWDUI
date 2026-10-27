# SWDUI (Stormworks Declarative UI)

## Declarative UI Framework for Stormworks: Build and Rescue LUA scripts

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/dominikstuecheli-105D-Engineering/BetterSlotAssign2/blob/main/BSA2/105DLogo.png?raw=true">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/dominikstuecheli-105D-Engineering/BetterSlotAssign2/blob/main/BSA2/105DLogoBright.png?raw=true">
  <img alt="Logo" src="https://github.com/dominikstuecheli-105D-Engineering/BetterSlotAssign2/blob/main/BSA2/105DLogo.png?raw=true">
</picture>

SWDUI aims to simplify the boilerplate code for LUA UIs in the game Stormworks: Build and Rescue. It offers constraint-based layout handling with space distribution, view state and animations. Because of the character limit of Stormworks´ LUA scripts, SWDUI has to be used in combination with LifeBoatAPI ([github.com/nameouschangey/Stormworks_LifeBoatAPI_MC](https://github.com/nameouschangey/Stormworks_LifeBoatAPI_MC) or [marketplace.visualstudio.com/...lifeboatapi](https://marketplace.visualstudio.com/items?itemName=NameousChangey.lifeboatapi))

Even the minimized code is quite character-intensive, so using SWDUI does not make sense for scripts that contain a lot of logic in onTick().

For a full documentation of **how to use**, all functions, views and view modifiers, visit Documentation.md.

## Example
```lua
require("SWDUI")

function onTick()
    setCursor(input.getNumber(3), input.getNumber(4), input.getBool(1))
end

function onDraw() drawOnScreen(
    VStack {
        Text("Hello world!")
            :color(20,20,200)
            :fixedSize(nil,7),

        Button(
            Text("Press me!")
                :color(100),
            Text("Pressed")
                :color(20,200,20),
            false, false,
            function () end
        )
            :fixedSize(nil,7),
    }
) end
```

## Same example in normal Stormworks UI Code
```lua
function isInRectangle(x,y,rectX,rectY,rectWidth,rectHeight)
    return x>=rectX and x<=rectX+rectWidth and y>=rectY and y<=rectY+rectHeight
end

function onTick()
    cursorX, cursorY, isPressed = input.getNumber(3), input.getNumber(4), input.getBool(1)
end

function onDraw()
    screenW, screenH = screen.getWidth(), screen.getHeight()
    screenCenterX, screenCenterY = screenW/2, screenH/2

    screen.setColor(20,20,200)
    screen.drawTextBox(0,screenCenterY-7, screenW,7, "Hello world!", 0,0)

    if isInRectangle(cursorX,cursorY, 0,screenCenterY, screenW,7) and isPressed then
        screen.setColor(20,200,20)
        screen.drawTextBox(0,screenCenterY, screenW,7, "Pressed", 0,0)
    else
        screen.setColor(100,100,100)
        screen.drawTextBox(0,screenCenterY, screenW,7, "Press me!", 0,0)
    end
end
```
