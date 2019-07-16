function plotData(src, event)
    global tempData;
    global data
    if(isempty(tempData))
    tempData = [];
    end
    plot(event.TimeStamps, event.Data)
    tempData = [tempData;event.Data];
    data = tempData;
    end