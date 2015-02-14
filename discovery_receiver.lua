require("cord")
sh = require("stormsh")
shield = require("starter") 

table = {}

S_PORT = 1525


--functions for printing the service table
function printServicePairs(t)
	for k,v in pairs(t) do
		if k == "id" or k == "t" then
			print(k,v)
		else
			print(k)
			printPairs(v, " >>")
		end
	end
end

function printPairs(t, indent)
	local indent = indent or ""
	for k,v in pairs(t) do
		print(indent..k,v)
	end
end

-- service announcement table
local svc_manifest ={ id = "Firestorm2", setRlyA={ s="setBool", desc= "red LED"}}	
local msg = storm.mp.pack(svc_manifest)

s_handler = function(payload, from, port) 
		print (string.format("from %s port %d: %s",from,port,payload))
		svc_stdout(from, port, storm.mp.unpack(payload))
	    end
ssock = storm.net.udpsocket(S_PORT, s_handler)

--send service table
storm.os.invokePeriodically(500*storm.os.MILLISECOND, function()
	storm.net.sendto(ssock, msg, "ff02::1", 1526)
	print("service table has been sent!")
end)

-- service that receives a string and simply prints it out
function svc_stdout(from_ip, from_port, msg)
	
	--print (string.format("[STDOUT] (ip=%s, port=%d)", from_ip, from_port))

	--printServicePairs(msg)

	-- decode message
	print(msg.setRlyA)
	local invoke = msg.setRlyA
	
	if invoke == 1 then
		shield.LED.on("blue")
		print("Decoded message!")
	end
	
end


sh.start()
shield.LED.start()
cord.enter_loop()
