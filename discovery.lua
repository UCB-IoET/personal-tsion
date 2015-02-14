require "cord"
sh = require "stormsh"

table = {}

S_PORT = 1526

-- service announcement table
local svc_manifest ={ id= "Sin Nombre", setRlyA={ s="setBool", desc= "red LED"}}	
local msg = storm.mp.pack(svc_manifest)

-- service invocation message
local svc_invoke ={["setRlyA"]=1}
msg = storm.mp.pack(svc_invoke)  

s_handler = function(payload, from, port) 
		print (string.format("from %s port %d: %s",from,port,payload))
		--table[from] = storm.mp.unpack(payload) 
		table[from] = svc_manifest
		--msg = storm.mp.pack(svc_invoke)	
	    end

ssock = storm.net.udpsocket(S_PORT, s_handler)

storm.os.invokePeriodically(1*storm.os.SECOND, function()
	print(msg)
	storm.net.sendto(ssock, msg, "ff02::1", 1525)
	print("service table has been sent!")
end)

-- service that receives a string and simply prints it out
function svc_stdout(from_ip, from_port, msg)
  print (string.format("[STDOUT] (ip=%s, port=%d) %s", from_ip, from_port, msg))
end

sh.start()
cord.enter_loop()
