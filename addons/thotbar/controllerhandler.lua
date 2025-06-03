local LHeld = false;
local RHeld = false;

local function GetStPartyIndex()
    local ptr = AshitaCore:GetPointerManager():Get('party');
    ptr = ashita.memory.read_uint32(ptr);
    ptr = ashita.memory.read_uint32(ptr);
    local isActive = (ashita.memory.read_uint32(ptr + 0x54) ~= 0);
    if isActive then
        return ashita.memory.read_uint8(ptr + 0x50);
    else
        return nil;
    end
end

local function GetTargets()

    local mainTarget, subTarget;

    local trgt = AshitaCore:GetMemoryManager():GetTarget();
    if (trgt ~= nil) then
        -- Get the main target
        if (trgt:GetIsSubTargetActive() == 1) then
            mainTarget = trgt:GetTargetIndex(1);
        elseif (trgt:GetSubTargetFlags() == 0xFFFFFFFF) then
            mainTarget = trgt:GetTargetIndex(0);
        else
            mainTarget = 0;
        end

        -- Get the sub target
        if (trgt:GetIsSubTargetActive() == 1) then
            subTarget = trgt:GetTargetIndex(0);
        elseif (trgt:GetSubTargetFlags() == 0xFFFFFFFF) then
            subTarget = 0;
        else
            subTarget = trgt:GetTargetIndex(0);
        end
    end

    return mainTarget, subTarget;
end

local function GetSubTargetActive()
    local mt, st = GetTargets();
    return GetStPartyIndex() ~= nil or st ~= 0;
end

--[[
* event: dinput_button
* desc : Event called when the addon is processing DirectInput controller input.
--]]
ashita.events.register('dinput_button', 'dinput_button_callback1', function (e)
    --[[ Valid Arguments
        e.button    - The controller button id.
        e.state     - The controller button state value.
        e.blocked   - Flag that states if the button has been, or should be, blocked.
        e.injected  - (ReadOnly) Flag that states if the button was injected by Ashita or an addon/plugin.
    --]]

--    print('Button: '..tostring(e.button)..'   State: '..tostring(e.state));

    if (gSettings.EnableController == false) then return end

    -- Handle gamepad inputs
    if (e.button == 54) then -- L Trigger
        e.blocked = true;
        LHeld = e.state == 128;
        if (LHeld == false and RHeld == false) then
            gDisplay:Pad(-1);
        end
    elseif (e.button == 55) then -- R Trigger
        e.blocked = true;
        RHeld = e.state == 128;
        if (LHeld == false and RHeld == false) then
            gDisplay:Pad(-1);
        end
    elseif (e.button == 32) then -- D-Pad
        if (e.state == -1) then
            gDisplay:Pad(e.state);
        elseif ((LHeld or RHeld) and GetSubTargetActive() == false) then
            e.blocked = true;
            gDisplay:Pad(e.state);
        end
    elseif (e.button == 49 and e.state == 128) then -- Confirm
        if ((LHeld or RHeld) and GetSubTargetActive() == false) then
            e.blocked = true;
            gDisplay:PadActivate();
        end
    elseif (e.button == 52 and e.state == 128) then -- L Bumper
        if (LHeld or RHeld) then
            e.blocked = true;
            gBindings:PreviousPalette();
        end
    elseif (e.button == 53 and e.state == 128) then -- R Bumper
        if (LHeld or RHeld) then
            e.blocked = true;
            gBindings:NextPalette();
        end
    end
end);

--[[
* event: xinput_button
* desc : Event called when the addon is processing XInput controller input.
--]]
ashita.events.register('xinput_button', 'xinput_button_callback1', function (e)

    -- print('Button: '..tostring(e.button)..'   State: '..tostring(e.state));

    if (gSettings.EnableController == false) then return end

    -- Handle gamepad inputs
    if (e.button == 16) then -- L Trigger
        e.blocked = true;
        LHeld = e.state == 255;
        if (LHeld == false and RHeld == false) then
            gDisplay:Pad(-1);
        end
    elseif (e.button == 17) then -- R Trigger
        e.blocked = true;
        RHeld = e.state == 255;
        if (LHeld == false and RHeld == false) then
            gDisplay:Pad(-1);
        end
    elseif (e.button == 0) then -- D Pad
        if (e.state == 0) then
            gDisplay:Pad(-1);
        elseif (e.state == 1 and (LHeld or RHeld) and GetSubTargetActive() == false) then
            e.blocked = true;
            gDisplay:Pad(0);
        end
    elseif (e.button == 1) then -- D Pad
        if (e.state == 0) then
            gDisplay:Pad(-1);
        elseif (e.state == 1 and (LHeld or RHeld) and GetSubTargetActive() == false) then
            e.blocked = true;
            gDisplay:Pad(18000);
        end
    elseif (e.button == 2) then -- D Pad
        if (e.state == 0) then
            gDisplay:Pad(-1);
        elseif (e.state == 1 and (LHeld or RHeld) and GetSubTargetActive() == false) then
            e.blocked = true;
            gDisplay:Pad(27000);
        end
    elseif (e.button == 3) then -- D Pad
        if (e.state == 0) then
            gDisplay:Pad(-1);
        elseif (e.state == 1 and (LHeld or RHeld) and GetSubTargetActive() == false) then
            e.blocked = true;
            gDisplay:Pad(9000);
        end
    elseif (e.button == 13 and e.state == 1) then -- Confirm
        if ((LHeld or RHeld) and GetSubTargetActive() == false) then
            e.blocked = true;
            gDisplay:PadActivate();
        end
    elseif (e.button == 8 and e.state == 1) then -- L Bumper
        if (LHeld or RHeld) then
            e.blocked = true;
            gBindings:PreviousPalette();
        end
    elseif (e.button == 9 and e.state == 1) then -- R Bumper
        if (LHeld or RHeld) then
            e.blocked = true;
            gBindings:NextPalette();
        end
    end
--[[
    if (gSettings.EnableController == false) then return end

    -- Handle gamepad inputs
    if (e.button == 32) then -- L Trigger
        e.blocked = true;
        LHeld = e.state == 255;
        if (LHeld == false and RHeld == false) then
            gInterface:GetSquareManager():Pad(-1);
        end
    elseif (e.button == 33) then -- R Trigger
        e.blocked = true;
        RHeld = e.state == 255;
        if (LHeld == false and RHeld == false) then
            gInterface:GetSquareManager():Pad(-1);
        end
    elseif (T{0,1,2,3}:contains(e.button)) then -- D-Pad
        if (e.state == 0) then
            gInterface:GetSquareManager():Pad(-1);
        elseif ((LHeld or RHeld) and GetSubTargetActive() == false) then
            e.blocked = true;
            local fauxState;
            if (e.button == 0) then
                fauxState = 0; -- up
            elseif (e.button == 1) then
                fauxState = 18000; -- down
            elseif (e.button == 2) then
                fauxState = 27000; -- left
            elseif (e.button == 3) then
                fauxState = 9000; -- right
            end
            gInterface:GetSquareManager():Pad(fauxState);
        end
    elseif (e.button == 12 and e.state == 1) then -- Confirm
        if ((LHeld or RHeld) and GetSubTargetActive() == false) then
            e.blocked = true;
            gInterface:GetSquareManager():PadActivate();
        end
    elseif (e.button == 8 and e.state == 1) then -- L Bumper
        if (LHeld or RHeld) then
            e.blocked = true;
            gBindings:PreviousPalette();
        end
    elseif (e.button == 9 and e.state == 1) then -- R Bumper
        if (LHeld or RHeld) then
            e.blocked = true;
            gBindings:NextPalette();
        end
    end
    --]]
end);

--[[
* event: xinput_state
* desc : Event called when the addon is processing XInput controller input.
--]]
ashita.events.register('xinput_state', 'xinput_state_callback1', function (e)
    --[[ Valid Arguments
        e.size              - (ReadOnly) The size of the state information. (Always sizeof(XINPUT_STATE))
        e.user              - (ReadOnly) Index of the user's controller.
        e.state             - (ReadOnly) The current XINPUT_STATE information of the event.
        e.state_modified    - The modified XINPUT_STATE information of the event.
    --]]
end);