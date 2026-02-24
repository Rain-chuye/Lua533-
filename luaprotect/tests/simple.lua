local function greet(name)
    local msg = "Hello, " .. name
    print(msg)
end

for i = 1, 3 do
    greet("User " .. i)
end

local a = 10
local b = 20
if a + b > 25 then
    print("Sum is greater than 25")
else
    print("Sum is small")
end
