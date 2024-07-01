-- A basic LDtk loader for LÖVE created by Hamdy Elzonqali
-- Last tested with LDtk 0.9.3
--
-- ldtk.lua
--
-- Copyright (c) 2021 Hamdy Elzonqali
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--



---@alias Color [number, number, number, number?]

----------- Loading JSON ------------
-- Remember to put json.lua in the same directory as ldtk.lua

-- Current folder trick
local currentFolder = (...):gsub('%.[^%.]+$', '')

-- Try to load relatively
local json = require("json")
if not json then
    json = require(currentFolder .. ".json")
end

local cache = {
    ---@type table<integer, love.Image>
    tilesets = {

    },
    quods = {

    },
    ---@type table<integer, love.SpriteBatch>
    batch = {

    }
}

local ldtk = {
    ---@type {string: integer}
    levels = {},
    ---@type {integer: string}
    levelsNames = {},
    ---@type {integer: LDtkTileset}
    tilesets = {},
    ---@type integer?
    currentLevelIndex = nil,
    currentLevelName  = '',
    flipped = false,
    cache = cache
}

local _path

--------- LAYER OBJECT ---------
--This is used as a switch statement for lua. Much better than if-else pairs.
local flipX = {
    [0] = 1,
    [1] = -1,
    [2] = 1,
    [3] = -1
}

local flipY = {
    [0] = 1,
    [1] = 1,
    [2] = -1,
    [3] = -1
}

---@type Color
local oldColor = {}


--draws tiles
---@param self LDtkLayer
---@return nil
local function draw_layer_object(self)
    if self.visible then
        --Saving old color
        oldColor[1], oldColor[2], oldColor[3], oldColor[4] = love.graphics.getColor()

        --Clear batch
        cache.batch[self.tileset.uid]:clear()

        -- Fill batch with quads
         for i = 1, self._tilesLen do
            cache.batch[self.tileset.uid]:add(
                cache.quods[self.tileset.uid][self.tiles[i].t],
                self.x + self.tiles[i].px[1] + self._offsetX[self.tiles[i].f],
                self.y + self.tiles[i].px[2] + self._offsetY[self.tiles[i].f],
                0,
                flipX[self.tiles[i].f],
                flipY[self.tiles[i].f]
            )
        end

        --Setting layer color
        love.graphics.setColor(self.color)
        --Draw batch
        love.graphics.draw(cache.batch[self.tileset.uid])

        --Resotring old color
        love.graphics.setColor(oldColor)
    end
end

---@class LDtkTileset
---@field package __cHei integer
---@field package __cWid integer
---@field cachedPixelData table
---@field customData table
---@field enumTags {enumValueId: string, tileIds: [integer]}[]
---@field identifier string
---@field padding integer
---@field pxHei integer
---@field pxWid integer
---@field relPath string
---@field savedSelections table
---@field spacing integer
---@field tags table
---@field tagsSourceEnumUid integer
---@field tileGridSize integer
---@field uid integer

--creates the layer object from data. only used here. ignore it
---@param data table
---@param order integer
---@param type LDtkLayerTypes The layer type
---@return LDtkLayer self
local function create_layer_object(data, order, type)
    ---@alias LDtkPoint [integer, integer]
    ---@class LDtkTile
    ---@field a number Alpha/opacity of the tile (0-1, defaults to 1)
    ---@field private d number[] Internal data used by the editor.
    ---@field f number "Flip Bits", see https://ldtk.io/json/#ldtk-Tile;f
    ---@field px LDtkPoint Pixel coordinates of the tile in the layer ([x,y] format)
    ---@field src LDtkPoint Pixel coordinates of the tile in the tileset ([x,y] format)
    ---@field t integer The Tile ID in the corresponding tileset

    ---@class LDtkBaseLayer
    ---@field package _offsetX {[0]: integer, [1]: integer, [2]: integer, [3]: integer}
    ---@field package _offsetY {[0]: integer, [1]: integer, [2]: integer, [3]: integer}
    ---@field order integer Draw Order
    ---@field id string Identifier
    ---@field x integer X Position
    ---@field y integer Y Position
    ---@field width integer Grid-based Width
    ---@field height integer Grid-based Height
    ---@field gridSize integer Size of Tile
    ---@field type LDtkLayerTypes Layer Type

    ---@class LDtkTileLayer : LDtkBaseLayer
    ---@field package _tilesLen integer The amount of tiles
    ---@field relPath string Path of tileset relative to main.lua
    ---@field path string Path of tileset relative to .ldtk file
    ---@field tiles LDtkTile[] Generated Tiles
    ---@field tileset LDtkTileset Tileset to use
    ---@field tilesetID integer UID of Tileset
    ---@field visible boolean Layer instance visibility
    ---@field color Color
    local tile_placeholder = {
        draw = draw_layer_object
    }

    ---@class LDtkIntGridLayer : LDtkBaseLayer
    ---@field intGrid table A list of all values in the IntGrid layer, stored in CSV format (Comma Separated Values). Order is from left to right, and top to bottom (ie. first row from left to right, followed by second row, etc). 0 means "empty cell" and IntGrid values start at 1.

    ---@class LDtkAutoLayer : LDtkIntGridLayer

    ---@alias LDtkLayer LDtkAutoLayer | LDtkIntGridLayer | LDtkTileLayer

    local self = {
        draw = draw_layer_object,
        order = order,
        type = type,
    }

    self._offsetX = {
        [0] = 0,
        [1] = data.__gridSize,
        [2] = 0,
        [3] = data.__gridSize,
    }

    self._offsetY = {
        [0] = 0,
        [1] = 0,
        [2] = data.__gridSize,
        [3] = data.__gridSize,
    }

    --getting tiles information
    self.intGrid = data.intGridCsv
    if type == "AutoLayer" then
        self.tiles = data.autoLayerTiles
    elseif type == "Tiles" then
        self.tiles = data.gridTiles
    end

    self.id = data.__identifier
    self.x, self.y = data.__pxTotalOffsetX, data.__pxTotalOffsetY

    self.width = data.__cWid
    self.height = data.__cHei
    self.gridSize = data.__gridSize

    if not (type == "AutoLayer" or type == "Tiles") then
        return self
    end

    self._tilesLen = #self.tiles

    self.relPath = data.__tilesetRelPath
    self.path = ldtk.getPath(data.__tilesetRelPath)

    self.visible = data.visible
    self.color = {1, 1, 1, data.__opacity}

    --getting tileset information
    self.tileset = ldtk.tilesets[data.__tilesetDefUid]
    self.tilesetID = data.__tilesetDefUid

    --creating new tileset if not created yet
    if not cache.tilesets[data.__tilesetDefUid] then
        --loading tileset
        cache.tilesets[data.__tilesetDefUid] = love.graphics.newImage(self.path)
        --creating spritebatch
        cache.batch[data.__tilesetDefUid] = love.graphics.newSpriteBatch(cache.tilesets[data.__tilesetDefUid])

        --creating quads for the tileset
        cache.quods[data.__tilesetDefUid] = {}
        local count = 0
        for ty = 0, self.tileset.__cHei - 1, 1 do
            for tx = 0, self.tileset.__cWid - 1, 1 do
                cache.quods[data.__tilesetDefUid][count] =
                    love.graphics.newQuad(
                        self.tileset.padding + tx * (self.tileset.tileGridSize + self.tileset.spacing),
                        self.tileset.padding + ty * (self.tileset.tileGridSize + self.tileset.spacing),
                        self.tileset.tileGridSize,
                        self.tileset.tileGridSize,
                        cache.tilesets[data.__tilesetDefUid]:getWidth(),
                        cache.tilesets[data.__tilesetDefUid]:getHeight()
                    )
                count = count + 1
            end
        end
    end

    return self
end

----------- HELPER FUNCTIONS ------------
--LDtk uses hex colors while LÖVE uses RGB (on a scale of 0 to 1)
-- Converts hex color to RGB
---@param color string Hex color formatted like "#ffffff"
---@return Color
function ldtk.hex2rgb(color)
    local r = load("return {0x" .. color:sub(2, 3) .. ",0x" .. color:sub(4, 5) ..
                ",0x" .. color:sub(6, 7) .. "}")()
    return {r[1] / 255, r[2] / 255, r[3] / 255}
end


--Checks if a table is empty.
---@param t table<any, any>
---@return boolean
local function is_empty(t)
    for _, _ in pairs(t) do
        return false
    end
    return true
end

----------- LDTK Functions -------------
--loads project settings
---@param file string File Path
---@param level integer? Optional Level Index
---@return nil
function ldtk:load(file, level)
    self.data = json.decode(love.filesystem.read(file))
    self.entities = {}
    self.x, self.y = self.x or 0, self.x or 0
    self.countOfLevels = #self.data.levels
    self.countOfLayers = #self.data.defs.layers

    --creating a table with the path to .ldtk file separated by '/',
    --used to get the path relative to main.lua instead of the .ldtk file. Ignore it.
    _path = {}
    for str in string.gmatch(file, "([^"..'/'.."]+)") do
        table.insert(_path, str)
    end
    _path[#_path] = nil

    for index, value in ipairs(self.data.levels) do
        self.levels[value.identifier] = index
    end

    for key, value in pairs(self.levels) do
        self.levelsNames[value] = key
    end

    for index, value in ipairs(self.data.defs.tilesets) do
        self.tilesets[value.uid] = self.data.defs.tilesets[index]
    end

    if level then
        self:goTo(level)
    end
end

--getting relative file path to main.lua instead of .ldtk file
---@param relPath string Path Relative to .ldtk file
---@return string path Path Relative to main.lua
function ldtk.getPath(relPath)
    local newPath = ''
    local newRelPath = {}
    local pathLen = #_path

    for str in string.gmatch(relPath, "([^"..'/'.."]+)") do
        table.insert(newRelPath, str)
    end

    for i = #newRelPath, 1, -1 do
        if newRelPath[i] == '..' then
            pathLen = pathLen - 1
            newRelPath[i] = nil
        end
    end

    for i = 1, pathLen, 1 do
        newPath = newPath .. (i > 1 and '/' or '') .. _path[i]
    end

    local keys = {}
    for key, _ in pairs(newRelPath) do
        table.insert(keys, key)
    end
    table.sort(keys)


    local len = #keys
    for i = 1, len, 1 do
        newPath = newPath .. (newPath ~= '' and '/' or '') .. newRelPath[keys[i]]
    end

    return newPath
end

---@alias LDtkLayerDefTypes  "AutoLayer" | "Entities" | "IntGrid" | "Tiles"
---@alias LDtkLayerTypes  "AutoLayer" | "IntGrid" | "Tiles"

---@param layerDef table
---@param order integer
---@param level LDtkLevel
local function layer_handler(layerDef, order, level)
    ---@type LDtkLayerDefTypes
    local type = layerDef.__type

    if type == "Entities" then
        for _, value in ipairs(layerDef.entityInstances) do
            local props = {}

            for _, p in ipairs(value.fieldInstances) do
                props[p.__identifier] = p.__value
            end

            ---@class LDtkEntity
            ---@field id string Entity ID
            ---@field iid string LDtk Unique Instance ID
            ---@field x integer X Position
            ---@field y integer Y Position
            ---@field width integer Configured Width in LDtk
            ---@field height integer Configured Height in LDtk
            ---@field px integer Pixot X
            ---@field py integer Pivot Y
            ---@field order integer Draw Order
            ---@field visible boolean Visiblity
            ---@field props table<string, any> Custom Fields defined in LDtk
            local entity = {
                id = value.__identifier,
                iid = value.iid,
                x = value.px[1],
                y = value.px[2],
                width = value.width,
                height = value.height,
                px = value.__pivot[1],
                py = value.__pivot[2],
                order = order,
                visible = layerDef.visible,
                props = props
            }

            ldtk.onEntity(entity, level)
        end
    else
        ---@cast type LDtkLayerTypes
        local layer = create_layer_object(layerDef, order, type)
        ldtk.onLayer(layer, level)
    end
end

--Load a level by its index
---@param index integer
---@return nil
function ldtk:goTo(index)
    if index > self.countOfLevels or index < 1 then
        error('There are no levels with that index.')
    end

    self.currentLevelIndex = index
    self.currentLevelName  = ldtk.levelsNames[index]

    local layers
    if self.data.externalLevels then
        layers = json.decode(love.filesystem.read(self.getPath(self.data.levels[index].externalRelPath))).layerInstances
    else
        layers = self.data.levels[index].layerInstances
    end

    local levelProps = {}
    for _, p in ipairs(self.data.levels[index].fieldInstances) do
        levelProps[p.__identifier] = p.__value
    end

    ---@class LDtkLevel
    ---@field backgroundColor Color Background Color
    ---@field id string Level ID
    ---@field worldX integer X Position in World
    ---@field worldY integer Y Position in World
    ---@field width integer Width
    ---@field height integer Height
    ---@field neighbours {dir: string, levelIid: string}[] Neighbouring Levels
    ---@field index integer Level Index
    ---@field props table<string, any> Custom Level Properties
    local levelEntry = {
        backgroundColor = ldtk.hex2rgb(self.data.levels[index].__bgColor),
        id = self.data.levels[index].identifier,
        worldX  = self.data.levels[index].worldX,
        worldY = self.data.levels[index].worldY,
        width = self.data.levels[index].pxWid,
        height = self.data.levels[index].pxHei,
        neighbours = self.data.levels[index].__neighbours,
        index = index,
        props = levelProps
    }

    self.onLevelLoaded(levelEntry)



    if self.flipped then
        for i = self.countOfLayers, 1, -1 do
            layer_handler(layers[i], i, levelEntry)
        end
    else
        for i = 1, self.countOfLayers do
            layer_handler(layers[i], i, levelEntry)
        end
    end


    self.onLevelCreated(levelEntry)
end

--loads a level by its name
---@param name string
---@return nil
function ldtk:level(name)
    self:goTo(self.levels[tostring(name)] or error('There are no levels with the name: "' .. tostring(name) .. '".\nDid you save? (ctrl +s)'))
end

--loads next level
---@return nil
function ldtk:next()
    self:goTo(self.currentLevelIndex + 1 <= self.countOfLevels and self.currentLevelIndex + 1 or 1)
end

--loads previous level
---@return nil
function ldtk:previous()
    self:goTo(self.currentLevelIndex - 1 >= 1 and self.currentLevelIndex - 1 or self.countOfLevels)
end

--reloads current level
---@return nil
function ldtk:reload()
    self:goTo(self.currentLevelIndex)
end

--gets the index of a specific level
---@param name string Level's Name
---@return integer index Index of level by name
function ldtk.getIndex(name)
    return ldtk.levels[name]
end

--get the name of a specific level
---@param index integer Level Index
---@return string name Name of level by index
function ldtk.getName(index)
    return ldtk.levelsNames[index]
end

--gets the current level index
---@return integer index Current level index
function ldtk:getCurrent()
    return self.currentLevelIndex
end

--get the current level name
---@return string name Current level name
function ldtk:getCurrentName()
    return ldtk.levelsNames[self:getCurrent()]
end

--sets whether to invert the loop or not
---@param flipped boolean
---@return nil
function ldtk:setFlipped(flipped)
    self.flipped = flipped
end

--gets whether the loop is inverted or not
---@return boolean flipped
function ldtk:getFlipped()
    return self.flipped
end

--remove the cached tiles and quods. you may use it if you have multiple .ldtk files
---@return nil
function ldtk.removeCache()
    cache = {
        tilesets = {

        },
        quods = {

        },
        batch = {

        }
    }
    collectgarbage()
end



--------- CALLBACKS ----------
--[[
    This library depends heavily on callbacks. It works by overriding the default callbacks.
]]

--[[
    ldtk.onEntity is called when a new entity is created.

    entity = {
        id          = (string),
        x           = (int),
        y           = (int),
        width       = (int),
        height      = (int),
        visible     = (bool)
        px          = (int),    --pivot x
        py          = (int),    --pivot y
        order       = (int),
        props       = (table)   --custom fields defined in LDtk
    }

    Remember that colors are saved in HEX format and not RGB.
    You can use ldtk ldtk.hex2rgb(color) to get an RGB table like {0.21, 0.57, 0.92}
]]
---@param entity LDtkEntity
---@param level LDtkLevel?
function ldtk.onEntity(entity, level)

end

--[[
    ldtk.onLayer is called when a new layer is created.

    layer:draw() --used to draw the layer

    layer = {
        id          = (string),
        x           = (int),
        y           = (int),
        visible     = (bool)
        color       = (table),  --the color of the layer {r,g,b,a}. Usually used for opacity.
        order       = (int),
        draw        = (function) -- used to draw the layer
    }
]]
---@param layer LDtkLayer
---@param level LDtkLevel?
---@return nil
function ldtk.onLayer(layer, level)

end

--[[
    ldtk.onLevelLoaded is called after the level data is loaded but before it's created.

    It's usually useful when you need to remove old objects and change some settings like background color

    level = {
        id          = (string),
        worldX      = (int),
        worldY      = (int),
        width       = (int),
        height      = (int),
        props       = (table), --custom fields defined in LDtk
        backgroundColor = (table) --the background color of the level as defined in LDtk
    }

    props table has the custom fields defined in LDtk
]]
---@param levelData LDtkLevel
---@return nil
function ldtk.onLevelLoaded(levelData)

end

--[[
    ldtk.onLevelCreated is called after the level is created.

    It's usually useful when you need to call a function or manipulate the objects after they are created.

    level = {
        id          = (string),
        worldX      = (int),
        worldY      = (int),
        width       = (int),
        height      = (int),
        props       = (table), --custom fields defined in LDtk
        backgroundColor = (table) --the background color of the level as defined in LDtk
    }
]]
---@param levelData LDtkLevel
---@return nil
function ldtk.onLevelCreated(levelData)

end




return ldtk
