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
        local nextTime = 999999999999;
        local nextKey = "";
        local index = 1;
        local convertTimeout = false;
        local now = tmr.now()
        if (self.now > now) then
            covertTimeout = true;
            print("============= THIS SHOULD NOT HAPPEN =============")
        end
        
        for key, value in pairs(self.timedItems) do
            if (value.nextEventTime < nextTime) then
                nextKey = key;
                nextTime = value.nextEventTime;
            end

            -- Handle maxInt overflow for tmr.now()
            if (convertTimeout) then
                local difference = 2147483647 - value.nextEventTime;
                print (key.." : "..difference.." : "..(now + difference))
                value.nextEventTime = now + difference;
            end
        end

        self.now = now
        return nextKey, nextTime;
    end,

    setVariablesForNextEvent = function(self, key)
        local data = self.timedItems[key];
        data.triggerTimes = data.triggerTimes + 1;
        
        if (data.totalNumberOfTimes > 0) then
            if (data.totalNumberOfTimes == data.triggerTimes) then
                self.timedItems[key]= nil
            end
        end
        
        data = self.timedItems[key];
        if (not (data == nil)) then
            local nextTimeout = tmr.now() / 1000 + data.timeout;
            data.nextEventTime = nextTimeout;

            self.timedItems[key] = data;
        end
    end,

    startNextEvent = function(self)
        local nextKey, nextTime = self:getNextEvent()
        local interval = nextTime - tmr.now() / 1000;
        if (interval <= 0) then
            interval = 1;
        end

        if (not (nextKey == "")) then
            tmr.alarm(self.timerId, interval, 0, function()
                local callBack = self.timedItems[nextKey].callBack;
                local triggerTimes = self.timedItems[nextKey].triggerTimes;
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

