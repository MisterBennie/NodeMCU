--[[

Category:   Timers
Version:    1.2
Author:     Ben de Vette <NodeMCU@Profiler.nl>
Copyright:  2015 - end of time, None
Licence:    (re)Use as you like

Changelog:
V1.0:       Initial release

V1.1:       Fixed bug with tmr.now() overflow

V1.2:       Introduced working removeTimeout
            Removed not needed code so everything should be working a bit faster

]]--

Timer = { 
    timerId = 0,
    timedItems = {},
    running = false,
    now = tmr.now(),

    addTimeEvent = function(self, key, timeout, numberOfTimes, callBack)
        if (callBack == nil) then
            return false;
        end
        
        local now = tmr.now();
        self.timedItems[key] = {
            timeout = timeout,
            callBack = callBack,
            originalTimeStamp = now,
            nextEventTime = now / 1000 + timeout,
            triggerTimes = 0,
            totalNumberOfTimes = numberOfTimes,
        }

        if (not self.running) then
            self.running = true;
            self:startNextEvent();
        end

        return true;
    end,

    removeTimeEvent = function(self, key)
        self.timedItems[key]= nil;
    end,

    print = function(self)
        print("TimerId: "..self.timerId)
        for key, value in pairs(self.timedItems) do
            print(key..": "..value.totalNumberOfTimes..": "..value.nextEventTime)
        end
    end,

    getNextEvent = function(self)
        local nextTime = 2147483647;
        local nextKey = "";
        local index = 1;
        local callBack = nil;
        local triggerTimes = 0;
        local convertTimeout = false;
        local now = tmr.now()
        local data = nil;
        
        if (self.now > now) then
            convertTimeout = true;
        end
        
        for key, value in pairs(self.timedItems) do
            if (value.nextEventTime < nextTime) then
                data = value;
                nextKey = key;
                nextTime = value.nextEventTime;
            end

            -- Handle maxInt overflow for tmr.now()
            if (convertTimeout) then
                local difference = 2147483 - value.nextEventTime;
                print (key.." : "..difference.." : "..(now + difference))
                value.nextEventTime = now + difference;
            end
        end

        self.now = now

        if (not (data == nil)) then
           return nextKey, data.nextEventTime, data.callBack, data.triggerTimes;
        end
    end,

    setVariablesForNextEvent = function(self, key)
        local data = self.timedItems[key];
        if (not (data == nil)) then
            data.triggerTimes = data.triggerTimes + 1;
            
            if (data.totalNumberOfTimes > 0) then
                if (data.totalNumberOfTimes == data.triggerTimes) then
                    self.timedItems[key]= nil
                end
            end
            
            if (not (data == nil)) then
                local nextTimeout = tmr.now() / 1000 + data.timeout;
                data.nextEventTime = nextTimeout;
            end
        end
    end,

    startNextEvent = function(self)
        local nextKey, nextTime, callBack, triggerTimes = self:getNextEvent()
        local interval = nextTime - tmr.now() / 1000;
        if (interval <= 0) then
            interval = 1;
        end

        if (not (nextKey == "")) then
            tmr.alarm(self.timerId, interval, 0, function()
                callBack(nextKey, triggerTimes);       
                self:setVariablesForNextEvent(nextKey);
                self:startNextEvent();                 
            end)     
        else
            self.running = false;
        end
    end,

    new = function(self, timerId)
        newObject = {}
        setmetatable(newObject, self)
        self.__index = self
        newObject.timedItems = timedItems
        newObject.timerId = timerId
        newObject.running = running
        newObject.now = now 
        return newObject
    end,
}

