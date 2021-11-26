local class = import("classes.baseclass")
local taskhandler = class("TaskHandler")
local sqlite = import("sqlite3")
-- DB format:
--
-- ID (INT) | event(STR) | args (STR) | date (STR) | command (STR)
-- ---------|------------|------------|------------|--------------
-- 1        |    time    | NULL       |12 30 1 10  | ?echo today is yes day
-- 2        |    msg     | hi         |NULL        | ?echo yes hello
--
local exists = function(tab,sv)
    for k,v in pairs(tab) do
        if v == sv then
            return true
        end
    end
    return false
end
function taskhandler:__init(dbpath)
    self.db = sqlite.open(dbpath)
    local query = self.db:exec("SELECT * FROM sqlite_master;")
    if not exists(query.tbl_name,"tasks") then
        self.db:exec([[
CREATE TABLE tasks(
    ID      INTEGER  PRIMARY KEY,
    event   STR,
    args    STR,
    date    STR,
    command STR
);
        ]])
    end
    self.cache = {}
end

function taskhandler:daily_cache()
    self.db:

