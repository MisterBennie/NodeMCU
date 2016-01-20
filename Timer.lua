--[[

Category:   Timers
Version:    1.3.1
Author:     Ben de Vette <NodeMCU@Profiler.nl>
Copyright:  2015 - end of time, None
Licence:    (re)Use as you like

Changelog:
V1.0:       Initial release

V1.1:       Fixed bug with tmr.now() overflow

V1.2:       Introduced working removeTimeout
            Removed not needed code so everything should be working a bit faster

V1.3:       Rearranged some code for optimalization
            Fixed tmr.now() overflow bug
            Maximum timerout is now around 40 days
            Can start and stop timers without crashing (quite handy)
            Introduced internal timer to keep everything alive

V1.31:      Something is wrong with the internal time, for the time I set it to 1000mS

]]--

Timer = { 
    timerId = 0,
    timedItems = {},
    nrOfTimedObjects = 0,
    running = false,
    now = tmr.now(),

    addTimeEvent = function(self, key, timeout, numberOfTimes, callBack)
        local newTimer = self.timedItems[key] == nil
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

        if (newTimer) then
            self:increaseTimerCounter(key);
        end
        
        if (not self.running) then
            self.running = true;
            self:startNextEvent();
        end

        return true;
    end,

    removeTimeEvent = function(self, key)
        if (not(self.timedItems[key] == nil)) then
            self.timedItems[key]= nil;
            self:decreaseTimerCounter(key);
            self:startNextEvent();
        end
    end,

    print = function(self)
        print("TimerId: "..self.timerId)
        if (self.running) then
            print("Running: Yes")
            print("Number of timers running: "..self.nrOfTimedObjects - 1)
        else
            print("Running: No")
        end
        for key, value in pairs(self.timedItems) do
            if (not ( key == "InternalTimer")) then
                print(key..": "..value.triggerTimes.." of "..value.totalNumberOfTimes.." - Timout: "..value.timeout.."mSec")
            end
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
        
        -- Handle maxInt overflow for tmr.now()
        if (self.now > now) then
            for key, value in pairs(self.timedItems) do
                local difference = value.nextEventTime - 2147483;
                if (difference < 0) then
                    value.nextEventTime = -difference;
                end
                value.nextEventTime = difference;
            end
        end
        
        for key, value in pairs(self.timedItems) do
            if (value.nextEventTime < nextTime) then
                data = value;
                nextKey = key;
                nextTime = value.nextEventTime;
            end
        end

        self.now = now

        if (not (data == nil)) then
           return nextKey, data;
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

    increaseTimerCounter = function(self, key)
        self.nrOfTimedObjects = self.nrOfTimedObjects + 1;
        if (self.nrOfTimedObjects == 1) then
            -- Add internal timer so we are sure that very long timers are still executed when we have a tmr.now() overflow
            self:addTimeEvent("InternalTimer", 1000 * 1, 0, function() end);
        end
    end,

    decreaseTimerCounter = function(self, key)
        self.nrOfTimedObjects = self.nrOfTimedObjects - 1;
        if (self.nrOfTimedObjects == 1) then
            self:removeTimeEvent("InternalTimer");
        end
    end,

    startNextEvent = function(self)
        local nextKey, data = self:getNextEvent()
        nextTime = data.nextEventTime;
        callBack = data.callBack;
        if (not (nextKey == "") and not (nextTime == nil)) then
            local interval = nextTime - tmr.now() / 1000;
            if (interval <= 0) then
                callBack(nextKey, triggerTimes);       
                self:setVariablesForNextEvent(nextKey);
                self:startNextEvent();                 
            else
                tmr.alarm(self.timerId, interval, 0, function()
                    callBack(nextKey, triggerTimes);       
                    self:setVariablesForNextEvent(nextKey);
                    self:startNextEvent();                 
                end)     
            end
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
        newObject.nrOfTimedObjects = nrOfTimedObjects
        return newObject
    end,
}

