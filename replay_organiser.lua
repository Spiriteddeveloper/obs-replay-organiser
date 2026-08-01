local obs = obslua
local ffi = require("ffi")

ffi.cdef[[
    int GetForegroundWindow();
    int GetWindowTextLengthA(int hwnd);
    int GetWindowTextA(int hwnd, char* lpString, int nMaxCount);
    bool CreateDirectoryA(const char* lpPathName, void* lpSecurityAttributes);
]]

local user32 = ffi.load("user32")
local kernel32 = ffi.load("kernel32")

local tracked_game = "Desktop"
local pending_renames = {}
local create_subfolders = true

function script_description()
    return [[<h2>OBS Replay Organiser</h2>
<p>Automatically renames your saved Replay Buffer clips based on the window or game currently in focus.</p>
<hr/>
<p><i>Note: This script only applies to the Replay Buffer.</i></p>]]
end

function script_properties()
    local props = obs.obs_properties_create()
    
    obs.obs_properties_add_bool(
        props, 
        "create_subfolders", 
        "Organize clips into Shadowplay-style subfolders"
    )
    
    return props
end

function script_defaults(settings)
    obs.obs_data_set_default_bool(settings, "create_subfolders", true)
end

function script_update(settings)
    create_subfolders = obs.obs_data_get_bool(settings, "create_subfolders")
end

local function get_foreground_window_title()
    local hwnd = user32.GetForegroundWindow()
    if hwnd == 0 then return "" end
    
    local length = user32.GetWindowTextLengthA(hwnd)
    if length == 0 then return "" end
    
    local buf = ffi.new("char[?]", length + 1)
    user32.GetWindowTextA(hwnd, buf, length + 1)
    return ffi.string(buf)
end

local function clean_filename(name)
    local cleaned = name:gsub('[\\/*?:"<>|]', "")
    cleaned = cleaned:match("^%s*(.-)%s*$") or cleaned
    return string.sub(cleaned, 1, 40)
end

function track_active_window()
    local title = get_foreground_window_title()
    
    if title and title ~= "" then
        local safe_title = clean_filename(title)
        
        if safe_title ~= tracked_game and safe_title ~= "" then
            tracked_game = safe_title
        end
    end
end

function on_event(event)
    if event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_SAVED then
        local original_path = obs.obs_frontend_get_last_replay()
        if not original_path or original_path == "" then return end

        local folder, filename, ext = original_path:match("^(.-[\\/])([^\\/]-)(%.[^%.]+)$")
        if not folder then return end

        local target_folder = folder
		
        if create_subfolders then
            target_folder = folder .. tracked_game
            kernel32.CreateDirectoryA(target_folder, nil)
            target_folder = target_folder .. "\\"
        end
		
        local timestamp = filename:match("(%d%d%d%d%-%d%d%-%d%d %d%d%-%d%d%-%d%d)")
        
        local new_filename = ""
        if timestamp then
            new_filename = tracked_game .. " " .. timestamp .. ext
        else
            new_filename = tracked_game .. " " .. filename .. ext
        end
        
        local new_path = target_folder .. new_filename

        table.insert(pending_renames, {
            old = original_path,
            new = new_path,
            attempts = 0
        })
    end
end

function process_renames()
    for i = #pending_renames, 1, -1 do
        local task = pending_renames[i]
        
        local success, err = os.rename(task.old, task.new)
        
        if success then
            obs.script_log(obs.LOG_INFO, "[Auto-Namer] Success! Saved to: " .. task.new)
            table.remove(pending_renames, i)
        else
            task.attempts = task.attempts + 1
            if task.attempts > 10 then
                obs.script_log(obs.LOG_WARNING, "[Auto-Namer] Failed to move: " .. task.old)
                table.remove(pending_renames, i)
            end
        end
    end
end

function script_load(settings)
    obs.timer_add(track_active_window, 2000)
    obs.timer_add(process_renames, 1000)
    obs.obs_frontend_add_event_callback(on_event)
end

function script_unload()
    obs.timer_remove(track_active_window)
    obs.timer_remove(process_renames)
end
