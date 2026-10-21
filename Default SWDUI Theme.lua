Default = {
    ---@section Default.Topbar
    Topbar = function (title, height)
        return ZStack {
            FilledRectangle():color(15),
            Text(title):color(200):padding(1)
        }:fixedSize(nil, height or 7)
    end,
    ---@endsection

    ---@section Default.Button
    Button = function (label, onlyExecuteOneTick, displayAsPressedAnyways, clickAction)
        return View(function (x,y,width,height)
            Button(
                ZStack {
                    RoundedRectangle():color(8),
                    Text(label):color(200):padding(1)
                },
                ZStack {
                    RoundedRectangle():color(30),
                    Text(label):color(8):padding(1)
                },
                onlyExecuteOneTick, displayAsPressedAnyways, clickAction
            ):draw(x,y,width,height)
        end)
    end,
    ---@endsection

    ---@section Default.Table
    Table = function (leadingViews, trailingViews)
        return View(function (x,y,width,height)
            for i=1,#leadingViews do
                local yPos = y + (i-1)*7

                --Line backgrounds
                if isInteger(i/2) then screen.setColor(15,15,15)
                else screen.setColor(8,8,8) end --alternating line background colors

                if i==1 then
                    screen.drawRectF(x,y+1,width,6)
                    screen.drawRectF(x+1,y,width-2,7)
                elseif i==#leadingViews then
                    screen.drawRectF(x,yPos,width,6)
                    screen.drawRectF(x+1,yPos,width-2,7)
                else
                    screen.drawRectF(x,yPos,width,7)
                end

                --Views
                screen.setColor(50,50,50)
                leadingViews[i]:draw(x+1,yPos,width-2,7)
                screen.setColor(200,200,200)
                trailingViews[i]:draw(x+1,yPos,width-2,7)
            end
        end):fixedSize(nil, #leadingViews*7)
    end,
    ---@endsection
}