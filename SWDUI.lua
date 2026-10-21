
--STUFF

---@section clamp
---Clamps a value to the range {l,h}
---@param v number the value
---@param l number lower bound
---@param h number upper bound
---@return number clampedValue v clamped to the range {l,h}
function clamp(v,l,h) return math.max(l, math.min(h, v)) end
---@endsection

---@section isInRectangle
function isInRectangle(x,y,rectX,rectY,rectWidth,rectHeight)
    return x>=rectX and x<=rectX+rectWidth and y>=rectY and y<=rectY+rectHeight
end
---@endsection

---@section round
---Rounds a number to the closest integer
---@param v number some number
---@return number roundedValue v rounded to the closest integer
function round(v) return math.floor(v+0.5) end
---@endsection

---@section isInteger
---Checks if a number is an integer
---@param v number number
---@return boolean isInteger true if v is an integer
function isInteger(v) return v==round(v) end
---@endsection


infinity = 1/0



--TOUCH FUNCTIONALITY

cursorX = 0
cursorY = 0
cursorPressed = false
cursorPressedOnLastTick = false
cursorPressedPulse = false

---@section setCursor
---Sets the SWDUI touch values to the ones given in the arguments. Has to be used in onTick() if touch functionality is needed.
---@param xPos number the X coordinate of the cursor/a touch input
---@param yPos number the Y coordinate of the cursor/a touch input
---@param isPressed boolean if the cursor/touchscreen is down/pressed
function setCursor(xPos, yPos, isPressed)
    cursorX, cursorY = xPos, yPos
    cursorPressed = isPressed
    cursorPressedPulse = cursorPressed and not cursorPressedOnLastTick
    cursorPressedOnLastTick = cursorPressed
end
---@endsection



--VIEW STATE

viewStates = {}
---@section ensureViewStateExists
---Makes sure a view state entry exists. Meant to be used before accessing it via the key to prevent crashes.
---@param key any the key to look for
---@param defaultValue any the value the view state is set to if it doesnt exist yet
function ensureViewStateExists(key, defaultValue)
    if viewStates[key] == nil then viewStates[key] = defaultValue end
end
---@endsection



--VIEW

---The core "object" that everything builds upon. Contains information about sizing etc. as well as all view modifiers as methods of the table.
---@class View: ViewModifiers
---@field minWidth number
---@field minHeight number
---@field maxWidth number
---@field maxHeight number
---@field horizontalAlignment number
---@field verticalAlignment number
---@field offsetX number
---@field offsetY number
---@field draw fun(self: View, x: number, y: number, width: number, height: number)
---@param drawFunction fun(x: number, y: number, width: number, height: number) The draw function that draws the view at x,y with the given width and height
---@return View
function View(drawFunction)
local returnView = {
    minWidth = 0,
    minHeight = 0,
    maxWidth = infinity,
    maxHeight = infinity,
    horizontalAlignment = 0,
    verticalAlignment = 0,
    offsetX = 0,
    offsetY = 0,

    --Draw the view to the screen at the specified location with the specified size
    draw = function (self, x,y,width,height)
        --if the views max size is smaller than the container, position the view in the center of the container
        if width > self.maxWidth then
            x = x + (width-self.maxWidth)/2 * (self.horizontalAlignment + 1)
            width = self.maxWidth
        end

        if height > self.maxHeight then
            y = y + (height-self.maxHeight)/2 * (self.verticalAlignment + 1)
            height = self.maxHeight
        end

        drawFunction(x+self.offsetX, y+self.offsetY, width,height)
    end
}

--copy the references to all View modifiers to this view
for key, modifier in pairs(viewModifiers) do returnView[key] = modifier end
return returnView

end



--MODIFIERS

---@class ViewModifiers
viewModifiers = {

    ---@section :align
    ---Modify the alignment values
    ---@param self View
    ---@param horizontalAlignment number
    ---@param verticalAlignment number
    ---@return View self
    align = function (self, horizontalAlignment, verticalAlignment)
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        return self
    end,
    ---@endsection

    ---@section :offset
    ---Modify the offset values
    ---@param self View
    ---@param offsetX number horizontal offset in pixels
    ---@param offsetY number vertical offset in pixels
    ---@return View self
    offset = function (self, offsetX, offsetY)
        self.offsetX = offsetX
        self.offsetY = offsetY
        return self
    end,
    ---@endsection

    ---@section :size
    ---Modify the size values
    ---@param self View
    ---@param minWidth number?
    ---@param minHeight number?
    ---@param maxWidth number?
    ---@param maxHeight number?
    ---@return View self
    size = function (self, minWidth, minHeight, maxWidth, maxHeight)
        self.minWidth = minWidth or self.minWidth
        self.minHeight = minHeight or self.minHeight
        self.maxWidth = maxWidth or self.maxWidth
        self.maxHeight = maxHeight or self.maxHeight
        return self
    end,
    ---@endsection

    ---@section :adjustSizeFor
    ---Modify the size values to fit all of the views in the viewTable
    ---@param self View
    ---@param viewTable View[]
    ---@return View self
    adjustSizeFor = function (self, viewTable)
        self.maxWidth, self.maxHeight = 0,0
        for _, view in pairs(viewTable) do
            self.minWidth = math.max(self.minWidth, view.minWidth)
            self.minHeight = math.max(self.minHeight, view.minHeight)
            self.maxWidth = math.max(self.maxWidth, view.maxWidth)
            self.maxHeight = math.max(self.maxHeight, view.maxHeight)
        end
        return self
    end,
    ---@endsection

    ---@section :fixedSize
    ---Modify the size values in a way that the view has a fixed size when drawn: nil arguments are allowed if the size should only be fixed for one dimension.
    ---@param self View
    ---@param width number?
    ---@param height number?
    ---@return View self
    fixedSize = function (self, width, height)
        self.minWidth = width or self.minWidth
        self.maxWidth = width or self.maxWidth
        self.minHeight = height or self.minHeight
        self.maxHeight = height or self.maxHeight
        return self
    end,
    ---@endsection

    ---@section :padding
    ---Add margin with the specified width around the view
    ---@param self View
    ---@param paddingValue number the size of the margin
    ---@return View self
    padding = function (self, paddingValue)
        self.minWidth = self.minWidth + 2*paddingValue
        self.minHeight = self.minHeight + 2*paddingValue
        self.maxWidth = self.maxWidth + 2*paddingValue
        self.maxHeight = self.maxHeight + 2*paddingValue

        local oldDraw = self.draw
        self.draw = function (self, x,y,width,height)
            oldDraw(self, x+paddingValue, y+paddingValue, width-2*paddingValue, height-2*paddingValue)
        end
        return self
    end,
    ---@endsection

    ---@section :individualPadding
    ---Adds individual padding on all sides {top, right, bottom, left}
    ---@param self View
    ---@param paddings [number?, number?, number?, number?] The size of the padding on the 4 sides [top, right/trailing, bottom, left/leading]
    ---@return View self
    individualPadding = function (self, paddings)
        local offsetX, offsetY, additionalWidth, additionalHeight = 0,0,0,0
        if paddings[1] ~= nil then --top
            offsetY, additionalHeight = paddings[1], paddings[1]
        end
        if paddings[2] ~= nil then --right/trailing
            additionalWidth = paddings[2]
        end
        if paddings[3] ~= nil then --bottom
            additionalHeight = additionalHeight + paddings[3]
        end
        if paddings[4] ~= nil then --left/leading
            offsetX, additionalWidth = offsetX + paddings[4], additionalWidth + paddings[4]
        end

        self.minWidth = self.minWidth + additionalWidth
        self.minHeight = self.minHeight + additionalHeight
        self.maxWidth = self.maxWidth + additionalWidth
        self.maxHeight = self.maxHeight + additionalHeight

        local oldDraw = self.draw
        self.draw = function (self, x,y,width,height)
            oldDraw(self, x+offsetX, y+offsetY, width-additionalWidth, height-additionalHeight)
        end
        return self
    end,
    ---@endsection

    ---@section :color
    ---Set the color the view will be drawn in
    ---@param self View
    ---@param r number 0-255
    ---@param g number? 0-255, Set to the value of r if not specified
    ---@param b number? 0-255, Set to the value of r if not specified
    ---@param a number? 0-1
    ---@return View self
    color = function (self, r,g,b,a)
        a = a or 1 --if a is not given, set it to full opacity
        g,b = g or r, b or r --if only one values is given, set all RGB values to that value

        local oldDraw = self.draw
        self.draw = function (self, x,y,width,height)
            screen.setColor(r,g,b,a*255)
            oldDraw(self, x,y,width,height)
        end
        return self
    end,
    ---@endsection

    ---@section :overlay
    ---Draw an overlay view over the view
    ---@param self View
    ---@param overlayView View
    ---@return View
    overlay = function (self, overlayView)
        return ZStack {
            self,
            overlayView
        }
    end,
    ---@endsection

    ---@section :background
    ---Draw a background view behind the view
    ---@param self View
    ---@param backgroundView View
    ---@return View
    background = function (self, backgroundView)
        return ZStack {
            backgroundView,
            self
        }
    end,
    ---@endsection

    ---@section :backgroundColor
    ---Fill the background of the view with the specified color
    ---@param self View
    ---@param r number 0-255
    ---@param g number? 0-255, Set to the value of r if not specified
    ---@param b number? 0-255, Set to the value of r if not specified
    ---@param a number? 0-1
    ---@return View
    backgroundColor = function (self, r,g,b,a)
        return ZStack {
            FilledRectangle():color(r,g,b,a),
            self
        }
    end,
    ---@endsection
    
    ---@section :onClick
    ---Execute a function when a view is clicked
    ---@param self View
    ---@param clickAction fun()
    ---@param onlyExecuteOneTick boolean? If true, clickAction is only executed on the first tick the view is pressed. Set to true by default
    ---@return View self
    onClick = function (self, clickAction, onlyExecuteOneTick)
        local oldDraw = self.draw
        if onlyExecuteOneTick == nil then onlyExecuteOneTick = true end
        self.draw = function (self, x,y,width,height)
            oldDraw(self, x,y,width,height)
            local pressed = isInRectangle(cursorX,cursorY, x,y, width,height) and cursorPressed
            if (pressed and onlyExecuteOneTick and cursorPressedPulse)
            or (pressed and not onlyExecuteOneTick) then clickAction() end
        end
        return self
    end,
    ---@endsection

}



--VIEW ARRANGEMENT VIEWS

---@section drawOnScreen
---Draw a view onto the screen filling the whole screen
---@param view View
function drawOnScreen(view)
    view:draw(0,0,screen.getWidth(),screen.getHeight())
end
---@endsection

---@section Spacer
---Empty Spacer view to space objects or fill empty space
---@param size number? The fixed size if the Spacer; the Spacer fills the space provided if this value is nil
---@return View
function Spacer(size)
    return View(function (x,y,width,height) end):fixedSize(size, size)
end
---@endsection

--Helper function for Stacks
---@section distributeSizes
function distributeSizes(minSizes, maxSizes, totalSizeAvailable)
    local remainingSpace, remainingItems, sizes, changedSomething = totalSizeAvailable, #minSizes, {}, true

    while changedSomething do
        changedSomething = false
        for i=1,#minSizes do if sizes[i] == nil then
            local equalShare = remainingSpace/remainingItems
            if minSizes[i] > equalShare then
                sizes[i] = minSizes[i]
                remainingSpace = remainingSpace - sizes[i]
                remainingItems = remainingItems - 1
                changedSomething = true
            elseif maxSizes[i] < equalShare then
                sizes[i] = maxSizes[i]
                remainingSpace = remainingSpace - sizes[i]
                remainingItems = remainingItems - 1
                changedSomething = true
            end
        end end
    end

    --also set sizes[i] for the views that just get the equal share
    if remainingItems > 0 then
        local equalShare = remainingSpace/remainingItems
        for i=1,#minSizes do if sizes[i] == nil then sizes[i] = equalShare end end
    end

    return sizes
end
---@endsection

---@section VStack
---Align views vertically respecting their sizing
---@param viewTable View[]
---@param spacing number?
---@return View
function VStack(viewTable, spacing)
    local minWidth, minHeight, maxWidth, maxHeight, minSizes, maxSizes = 0,0,0,0, {},{}
    spacing = spacing or 0

    for i=1, #viewTable do
        local currentView = viewTable[i]
        minWidth = math.max(minWidth, currentView.minWidth)
        minHeight = minHeight + currentView.minHeight
        maxWidth = math.max(maxWidth, currentView.maxWidth)
        maxHeight = maxHeight + currentView.maxHeight
        minSizes[i] = currentView.minHeight
        maxSizes[i] = currentView.maxHeight
    end

    minHeight = minHeight + (#viewTable-1)*spacing
    maxHeight = maxHeight + (#viewTable-1)*spacing

    return View(function (x,y,width,height)
        local currentHeight, calculatedSizes = 0, {}
        calculatedSizes = distributeSizes(minSizes, maxSizes, height - (#viewTable-1)*spacing)
        
        for i=1, #viewTable do
            viewTable[i]:draw(x, y+currentHeight+(i-1)*spacing, width, calculatedSizes[i])
            currentHeight = currentHeight + calculatedSizes[i]
        end

    end):size(minWidth, minHeight, maxWidth, maxHeight)
end
---@endsection

---@section HStack
---Align views horizontally respecting their sizing
---@param viewTable View[]
---@param spacing number?
---@return View
function HStack(viewTable, spacing)
    local minWidth, minHeight, maxWidth, maxHeight, minSizes, maxSizes = 0,0,0,0, {},{}
    spacing = spacing or 0

    for i=1, #viewTable do
        local currentView = viewTable[i]
        minWidth = minWidth + currentView.minWidth
        minHeight = math.max(minHeight, currentView.minHeight)
        maxWidth = maxWidth + currentView.maxWidth
        maxHeight = math.max(maxHeight, currentView.maxHeight)
        minSizes[i] = currentView.minWidth
        maxSizes[i] = currentView.maxWidth
    end

    minWidth = minWidth + (#viewTable-1)*spacing
    maxWidth = maxWidth + (#viewTable-1)*spacing

    return View(function (x,y,width,height)
        local currentWidth, calculatedSizes = 0, {}

        calculatedSizes = distributeSizes(minSizes, maxSizes, width - (#viewTable-1)*spacing)
        
        for i=1, #viewTable do
            viewTable[i]:draw(x+currentWidth+(i-1)*spacing, y, calculatedSizes[i], height)
            currentWidth = currentWidth + calculatedSizes[i]
        end
    end):size(minWidth, minHeight, maxWidth, maxHeight)
end
---@endsection

---@section ZStack
---Draws views as layers over each other
---@param viewTable View[]
---@return View
function ZStack(viewTable)
    return View(function (x,y,width,height)
        for i=1, #viewTable do viewTable[i]:draw(x,y, width,height) end
    end):adjustSizeFor(viewTable)
end
---@endsection

---@section animateValue
---Helper functions for animations
---@param v number the value to be animated
---@param setPoint number the target value for v
---@param duration number the duration of the animation in seconds
---@return number
function animateValue(v, setPoint, duration)
    local step = 1/duration/60
    v = v + clamp(setPoint - v, -step, step)
    if v > setPoint-step and v < setPoint+step then v = setPoint end
    return v
end
---@endsection

---@section animateViewStateValue
---Animates a value stored in viewStates with animateValue(...)
---@param key any the identifying key in viewStates
---@param setPoint number the target value
---@param duration number the duration of the animation in seconds
---@return number value
function animateViewStateValue(key, setPoint, duration)
    ensureViewStateExists(key, setPoint)
    viewStates[key] = animateValue(viewStates[key], setPoint, duration)
    return viewStates[key]
end
---@endsection

---@section Pages
---Draws the view at the speficied index in the pageTable: Changes in the openedPage value are animated with a page flipping animation.
---@param identifier any the identifier for the view state
---@param openedPage integer the index of the page that should be displayed
---@param animationDuration number the duration of the page flipping animation in seconds
---@param pageTable View[]
---@return View
function Pages(identifier, openedPage, animationDuration, pageTable)
    return View(function (x,y,width,height)
        openedPageState = clamp(animateViewStateValue(identifier, openedPage, animationDuration), 1,#pageTable)

        if isInteger(openedPageState) then
            pageTable[openedPageState]:draw(x,y,width,height)
        else
            local lastPageIndex, nextPageIndex = math.floor(openedPageState), math.ceil(openedPageState)
            pageTable[lastPageIndex]:offset((lastPageIndex-openedPageState)*width,0):draw(x,y,width,height)
            pageTable[nextPageIndex]:offset((nextPageIndex-openedPageState)*width,0):draw(x,y,width,height)
        end
    end):adjustSizeFor(pageTable)
end
---@endsection


---@section IfTrue
---Only draws a view when state is true: Changes in state are animated.
---@param identifier any the identifier for the view state
---@param state boolean whether or not view should be displayed
---@param animationDuration number the duration of the fade in/out animation in seconds
---@param view View
---@return View
function IfTrue(identifier, state, animationDuration, view)
    local actualState = state and 1 or 0
    actualState = animateViewStateValue(identifier, actualState, animationDuration)

    return View(function (x,y,width,height)
        if state == 1 then view:draw(x,y,width,height) end
    end):size(view.minWidth*actualState, view.minHeight*actualState, view.maxWidth*actualState, view.maxHeight*actualState)
end
---@endsection

---@section forEach
---Makes a view table with a view for each item in the items table. forEach itself is not a view. getItemView is a function with the item and its index as the argument that returns a view for that item.
---@param items any[]
---@param getItemView fun(item: any, itemIndex: integer): View
---@return View[]
function forEach(items, getItemView)
    local viewTable = {}
    for itemIndex, item in ipairs(items) do viewTable[#viewTable+1] = getItemView(item, itemIndex) end
    return viewTable
end
---@endsection



--SHAPES

--Filled rectangle
---@section FilledRectangle
---@return View
function FilledRectangle()
    return View(screen.drawRectF)
end
---@endsection

--Rectangle with rounded corners (radius 1)
---@section RoundedRectangle
---@return View
function RoundedRectangle()
    return View(function (x,y,width,height)
        screen.drawRectF(x+1,y,width-2,height)
        screen.drawRectF(x,y+1,width,height-2)
    end)
end
---@endsection

--Rectangle border, adjusted for the incorrect sizing of the Stormworks screen.drawRect(...) function.
---@section RectangleBorder
---@return View
function RectangleBorder()
    return View(function (x,y,width,height)
        screen.drawRect(x,y,width-1,height-1)
    end)
end
---@endsection



--NORMAL VIEWS

---@section Text
---Text: The specified alignment values are for the text box and are therefore seperate from the alignment values of the view they are contained in. nil values are allowed for the alignment values.
---@param text string
---@param horizontalAlignment number?
---@param verticalAlignment number?
---@return View
function Text(text, horizontalAlignment, verticalAlignment)
    return View(function (x,y,width,height)
        screen.drawTextBox(x,y,width,height, text, horizontalAlignment or 0,verticalAlignment or 0)
    end):size(4,5)
end
---@endsection

---@section Button
---@param labelView View the View displayed if the button is not pressed
---@param labelViewIfPressed View the View displayed if the button is pressed
---@param onlyExecuteOneTick boolean whether or not clickAction should only be executed on the first tick the button is pressed
---@param displayAsPressedAnyways boolean for toggle buttons; if true, the buttons is displayed as if it was pressed
---@param clickAction fun() is executed when the button is pressed
---@return View
function Button(labelView, labelViewIfPressed, onlyExecuteOneTick, displayAsPressedAnyways, clickAction)
    return View(function (x,y,width,height)
        local isHovering = isInRectangle(cursorX,cursorY,x,y,width,height)
        local pressed = isHovering and cursorPressed and (not onlyExecuteOneTick or cursorPressedPulse)

        if pressed then clickAction() end

        if pressed or displayAsPressedAnyways or (onlyExecuteOneTick and cursorPressed and isHovering) then
            labelViewIfPressed:draw(x,y,width,height)
        else
            labelView:draw(x,y,width,height)
        end
    end):adjustSizeFor{labelView, labelViewIfPressed}
end
---@endsection

---@section ProgressBar
---@param value number how far along the progress bar is
---@param orientation number 1 = bottom to top, 2 = left to right, 3 = top to bottom, 4 = right to left
---@return View
function ProgressBar(value, orientation)
    value = clamp(value, 0,1)
    return View(function (x,y,width,height)
        if orientation == 1 then --bottom to top
            screen.drawRectF(x,y+height,width,-height*value)
        elseif orientation == 2 then --left to right
            screen.drawRectF(x,y,width*value,height)
        elseif orientation == 3 then --top to bottom
            screen.drawRectF(x,y,width,height*value)
        else --right to left
            screen.drawRectF(x+width,y,-width*value,height)
        end
    end)
end
---@endsection



