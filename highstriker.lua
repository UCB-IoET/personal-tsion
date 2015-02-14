require "cord"
LCD = require "lcd"
LED = require "led"
Button = require "button"
ACC = require "acc"

-- Setup Section --
function acc_setup()
	ac1 = ACC:new()
	cord.new(function()
		ac1:init()
		ac1:calibrate()
	end)
end

function lcd_setup()
	lcd = LCD:new(storm.i2c.EXT, 0x7c, storm.i2c.EXT, 0xc4)
	cord.new(function() lcd:init(2,1) end)
end

function wait_ms(period)
	cord.await(storm.os.invokeLater, period*storm.os.MILLISECOND)
end

C_PORT = 47772
S_PORT = 47771

button_press = false

-------------------- Server --------------------

-- Server Main
function server_main()
	-- set up LCD (at I2C)
	lcd_setup()
	-- set up Buzzer (optional) (plugged into D2)
	-- set up network (on 47771) i.e. set up listening socket
	ssock = storm.net.udpsocket(S_PORT, s_handler)
	-- set up button (plugged into D6)
	print("Server started")
	btn1 = Button:new("D6")
	btn1:whenever("RISING",function()
		-- wait for start button to be pressed
		print("button pressed")
		if button_press then
			print("already running the game")
			return
		end
		button_press = false
		-- call storm.net.sendto funciton to send start packet to client
		local msg = "-2"
		-- TODO: Hack, change later for ACK based handshake
		for i = 1, 5 do
			print("i = " .. i)
			storm.net.sendto(ssock, msg, "ff02::1", C_PORT)
		end
		print("sent msg 5 times to client")
		-- wait until you receive an end packet from the client and close the listening socket -- use a signaling variable
		-- display the final result (do something fun)
	end)
end


handling = false

--- call from network handler -- NOT IN MAIN LOOP
s_handler = function(payload, from, port)
	cord.new(function()
		print (string.format("from %s port %d: %s",from,port,payload))
		-- check if it is an end packet
		if handling then
			return
		end
		handling = true
		button_press = false
		local num = tonumber(payload)
		--if num == -1 then
		--button_press = false
		--	return
		-- if it is an end packet, flag the end signal variable and return
		-- else Compute Score (from payload, assuming INT data type)
		--else
		print("about to compute score..")
		cord.new(function() compute_score(num) end)
		--end
		handling = false
		-- Get RGB values (map accel value to RGB value)
		-- Display Results (look at demo) (ascii bars & color)
	end)
end

-- what is a minimum accel score??
function compute_score(x)
	print("computing score...")
	local r = math.max((-510*x)/255 + 255, 0)
	local b = math.min(510*x/255,255)
	local g = math.max(510*x/255 - 255,0)
	print("Made math stuff")
	--for i=1,5 do
	lcd:setBackColor(r,g,b)
	print("Printed color")
	wait_ms(500)
	--end
	--for i=1,5 do
	lcd:setCursor(0,0)
    	lcd:writeString("Score: " .. x)
	wait_ms(1000)
	-- end
	print("DONE!")
end

-------------------- Client --------------------

-- Client Main
	-- set up accelerometer
	-- set up network (port 47772)

-- Client network handler
	-- check if it is a start packet if yes continue
	-- clear the old max score
	-- start tracking accl readings to compute the magnitude of the acceleration
	-- normalize it to 0-255 with 0 be 0, 255 be 4g
	-- keep track of the max every 50ms
	-- the total time for this should be less than 2s
	-- at 2s send the max back to server
client_running = false

function client_main()
	acc_setup()
	-- create client socket
	csock = storm.net.udpsocket(C_PORT, client_handler)
	print("Started Client")
end

client_handler = function(payload, from, port)
	cord.new(function()
		print (string.format("received from %s port %d: %s",from,port,payload))
		if client_running then
			print("game started")
			return
		end
		client_running  = true
		print("client start running")
		local max_acc = 0
		local period = 50
		local count = 2000 / 50
		local aax, aay, aaz, m, m_norm = 0, 0, 0, 0, 0
		while count > 0 do
			aax, aay, aaz = ac1:get_mg()
			print("aax = " .. aax .. " aay = " .. aay .." aaz = " .. aaz)
			m = math.sqrt(aax^2 + aay^2 + aaz^2) - 1000 -- remove gravity
			m_norm = m * 255 / 6000
			max_acc = math.max(m_norm, max_acc)
			print("max accl = " .. max_acc)
			wait_ms(50)
			count = count - 1
		end
		for i = 1, 5 do
			print("i = ".. i)
			storm.net.sendto(csock, tostring(max_acc), "ff02::1", S_PORT)
		end
		print(string.format("finished measurement, max accl: %d", max_acc))
		client_running = false
	end)
end


--- Call either server or client main function here

--- temp shell
server_main()

cord.enter_loop()
