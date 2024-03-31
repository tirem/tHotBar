local d3d8 = require('d3d8');
local Element = require('element');
local ffi = require('ffi');
local gdi = require('gdifonts.include');
ffi.cdef[[
    int16_t GetKeyState(int32_t vkey);
]]

local function IsControlPressed()
    return (bit.band(ffi.C.GetKeyState(0x11), 0x8000) ~= 0);
end

local modifiers = T{
    ['!'] = 'alt',
    ['^'] = 'ctrl',
    ['@'] = 'win',
    ['#'] = 'apps',
    ['+'] = 'shift'
};

local function bind(hotkey, index)
    local defaults = {
        alt = false,
        ctrl = false,
        win = false,
        apps = false,
        shift =  false
    };

    local working = hotkey;
    local firstChar = string.sub(working, 1, 1);
    while (modifiers[firstChar] ~= nil) do
        defaults[modifiers[firstChar]] = true;
        working = string.sub(working, 2);
        firstChar = string.sub(working, 1, 1);
    end

    local kb = AshitaCore:GetInputManager():GetKeyboard();
    kb:Bind(kb:S2D(working), true, defaults.alt, defaults.apps, defaults.ctrl, defaults.shift, defaults.win,
    string.format('/tb activate %u', index));
end

local function unbind(hotkey)
    local defaults = {
        alt = false,
        ctrl = false,
        win = false,
        apps = false,
        shift =  false
    };

    local working = hotkey;
    local firstChar = string.sub(working, 1, 1);
    while (modifiers[firstChar] ~= nil) do
        defaults[modifiers[firstChar]] = true;
        working = string.sub(working, 2);
        firstChar = string.sub(working, 1, 1);
    end

    local kb = AshitaCore:GetInputManager():GetKeyboard();
    kb:Unbind(kb:S2D(working), true, defaults.alt, defaults.apps, defaults.ctrl, defaults.shift, defaults.win);
end

local Display = { Valid = false };

function Display:Destroy()
    self.Layout = nil;
    if type(self.Elements) == 'table' then
        local bindSetting = AshitaCore:GetInputManager():GetKeyboard():GetSilentBinds();
        AshitaCore:GetInputManager():GetKeyboard():SetSilentBinds(true);
        for _,element in ipairs(self.Elements) do
            unbind(element.State.Hotkey);
        end
        AshitaCore:GetInputManager():GetKeyboard():SetSilentBinds(bindSetting);
    end
    self.Elements = T{};
    self.Valid = false;
end

function Display:Initialize(layout)
    self.lastUpdateTime = os.clock()  -- Initialize the last update time
    self.initialDelay = .2 -- How long before selection loop starts
    self.loopInterval = 0.06  -- Loop selection this fast
    self.isLooping = false  -- Indicates whether the looping has started
    self.SelectedIndex = 0; -- Initial index for selections
    self.state = -1;    -- Current state the controller is in

    self.Layout = layout;
    self.Elements = T{};

    local position = gSettings.Position;

    local bindSetting = AshitaCore:GetInputManager():GetKeyboard():GetSilentBinds();
    AshitaCore:GetInputManager():GetKeyboard():SetSilentBinds(true);
    for _,data in ipairs(layout.Elements) do
        local newElement = Element:New(data.DefaultMacro, layout);
        newElement.OffsetX = data.OffsetX;
        newElement.OffsetY = data.OffsetY;
        newElement:SetPosition(position);
        self.Elements:append(newElement);
        bind(data.DefaultMacro, #self.Elements);
    end
    AshitaCore:GetInputManager():GetKeyboard():SetSilentBinds(bindSetting);

    if (self.Sprite == nil) then
        local sprite = ffi.new('ID3DXSprite*[1]');
        if (ffi.C.D3DXCreateSprite(d3d8.get_device(), sprite) == ffi.C.S_OK) then
            self.Sprite = d3d8.gc_safe_release(ffi.cast('ID3DXSprite*', sprite[0]));
        else
            Error('Failed to create Sprite in Display:Initialize.');
        end
    end
    
    self.Valid = (self.Sprite ~= nil);
    local obj = gdi:create_object(self.Layout.Palette, true);
    obj.OffsetX = self.Layout.Palette.OffsetX;
    obj.OffsetY = self.Layout.Palette.OffsetY;
    self.PaletteDisplay = obj;

    if (self.Valid) then
        gBindings:Update();
    end
end

function Display:Activate(index)
    if (self.Valid == false) then
        return;
    end

    local element = self.Elements[index];
    if element then
        element:Activate();
    end
end

local d3dwhite = d3d8.D3DCOLOR_ARGB(255, 255, 255, 255);
local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });
function Display:Render()
    if (self.Valid == false) then
        return;
    end

    local currentTime = os.clock()

    -- Handle the initial delay and loop timing
    if (self.state ~= -1) then
        if not self.isLooping and currentTime - self.lastUpdateTime >= self.initialDelay then
            self.isLooping = true
            self.lastUpdateTime = currentTime
        elseif self.isLooping and currentTime - self.lastUpdateTime >= self.loopInterval then
            self:ExecutePad(self.state)  -- Update the state based on the current direction
            self.lastUpdateTime = currentTime
        end
    end

    local pos = gSettings.Position;
    local sprite = self.Sprite;
    sprite:Begin();

    for _,object in ipairs(self.Layout.FixedObjects) do
        local component = self.Layout.Textures[object.Texture];
        vec_position.x = pos[1] + object.OffsetX;
        vec_position.y = pos[2] + object.OffsetY;
        sprite:Draw(component.Texture, component.Rect, component.Scale, nil, 0.0, vec_position, d3dwhite);
    end
    
    local paletteText, opacity = gBindings:GetDisplayTextAndOpacity();
    if (gSettings.ShowPalette) and (paletteText) then
        local obj = self.PaletteDisplay;
        obj:set_text(paletteText);
        local texture, rect = obj:get_texture();
        local posX = obj.OffsetX + pos[1];
        if (obj.settings.font_alignment == 1) then
            vec_position.x = posX - (rect.right / 2);
        elseif (obj.settings.font_alignment == 2) then
            vec_position.x = posX - rect.right;
        else
            vec_position.x = posX;;
        end
        vec_position.y = obj.OffsetY + pos[2];
        
        opacity = d3d8.D3DCOLOR_ARGB(opacity, 255, 255, 255);
        sprite:Draw(texture, rect, vec_font_scale, nil, 0.0, vec_position, opacity);
    end

    for index, element in ipairs(self.Elements) do
        element:RenderIcon(sprite, index == self.SelectedIndex);
    end
    

    for _,element in ipairs(self.Elements) do
        element:RenderText(sprite);
    end
    
    if (self.AllowDrag) then
        local component = self.Layout.Textures[self.Layout.DragHandle.Texture];
        vec_position.x = pos[1] + self.Layout.DragHandle.OffsetX;
        vec_position.y = pos[2] + self.Layout.DragHandle.OffsetY;
        sprite:Draw(component.Texture, component.Rect, component.Scale, nil, 0.0, vec_position, d3dwhite);
    end

    sprite:End();
end

local dragPosition = { 0, 0 };
local dragActive = false;
function Display:DragTest(e)
    local handle = self.Layout.DragHandle;
    local pos = gSettings.Position;
    local minX = pos[1] + handle.OffsetX;
    local maxX = minX + handle.Width;
    if (e.x < minX) or (e.x > maxX) then
        return false;
    end

    local minY = pos[2] + handle.OffsetY;
    local maxY = minY + handle.Height;
    return (e.y >= minY) and (e.y <= maxY);
end

function Display:HandleMouse(e)
    if (self.Valid == false) then
        return;
    end

    if dragActive then
        local pos = gSettings.Position;
        pos[1] = pos[1] + (e.x - dragPosition[1]);
        pos[2] = pos[2] + (e.y - dragPosition[2]);
        dragPosition[1] = e.x;
        dragPosition[2] = e.y;
        self:UpdatePosition();
        if (e.message == 514) or (not self.AllowDrag) then
            dragActive = false;
            settings.save();
        end
    elseif (self.AllowDrag) and (e.message == 513) and self:DragTest(e) then
        dragActive = true;
        dragPosition[1] = e.x;
        dragPosition[2] = e.y;
        e.blocked = true;
        return;
    end

    if (e.message == 513) then
        local hitElement = self:HitTest(e.x, e.y);
        if hitElement then
            if IsControlPressed() then
                gBindingGUI:Show(hitElement.State.Hotkey, hitElement.Binding);
                e.blocked = true;
            elseif (gSettings.ClickToActivate) then
                hitElement:Activate();
                e.blocked = true;
            end
        end
    end
end

function Display:HitTest(x, y)
    if (self.Valid == false) then
        return;
    end

    local pos = gSettings.Position;
    if (x < pos[1]) or (y < pos[2]) then
        return false;
    end

    if (x > (pos[1] + self.Layout.Panel.Width)) then
        return false;
    end

    if (y > (pos[2] + self.Layout.Panel.Height)) then
        return false;
    end

    for index,element in ipairs(self.Elements) do
        if (element:HitTest(x, y)) then
            return element;
        end
    end
end

function Display:UpdateBindings(bindings)
    if (self.Valid == false) then
        return;
    end

    for index,element in ipairs(self.Elements) do
        element:UpdateBinding(bindings[element.State.Hotkey]);
    end
end

function Display:UpdatePosition()
    if (self.Valid == false) then
        return;
    end
    
    local position = gSettings.Position;

    for _,element in ipairs(self.Elements) do
        element:SetPosition(position);
    end
end

function Display:ExecutePad(state)
    local maxColumns = 10  -- The width is always 10 (hardcoded garbage code)
    local maxRows = 4;
    local numElements = #self.Elements
    if (numElements ~= nil) then
        maxRows = numElements / maxColumns
    end

    if (state == 0) then -- up
        self.SelectedIndex = self.SelectedIndex - 10
        -- Wrap to the bottom if moving up from the top row
        if self.SelectedIndex < 1 then
            self.SelectedIndex = self.SelectedIndex + (maxRows * maxColumns)
        end
    elseif (state == 18000) then -- down
        self.SelectedIndex = self.SelectedIndex + 10
        -- Wrap to the top if moving down from the bottom row
        if self.SelectedIndex > (maxRows * maxColumns) then
            self.SelectedIndex = self.SelectedIndex - (maxRows * maxColumns)
        end
    elseif (state == 27000) then -- left
        self.SelectedIndex = self.SelectedIndex - 1
        -- Wrap to the right if moving left from the first column
        if (self.SelectedIndex % maxColumns) == 0 then
            self.SelectedIndex = self.SelectedIndex + maxColumns
        end
    elseif (state == 9000) then -- right
        self.SelectedIndex = self.SelectedIndex + 1
        -- Wrap to the left if moving right from the last column
        if (self.SelectedIndex % maxColumns) == 1 then
            self.SelectedIndex = self.SelectedIndex - maxColumns
        end
    end

    -- catch for invalid index
    if (numElements ~= nil and (self.SelectedIndex < 1 or self.SelectedIndex > #self.Elements)) then
        self.SelectedIndex = 1;
    end
end

function Display:Pad(state)
    if (T{-1, 0, 18000, 27000, 9000}:contains(state)) then
        self.isLooping = false;
        self.state = state;
        self.lastUpdateTime = os.clock();

        self:ExecutePad(self.state);
    end
end

function Display:PadActivate()
    self:Activate(self.SelectedIndex);
end

return Display;