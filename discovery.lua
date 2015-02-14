local svc_manifest = {id="ATeam"}              


S_PORT = 1525

-- service announcement table
local svc_manifest ={ id= "Sin Nombre", setRlyA={ s="setBool", desc= "red LED"}, }	
local msg = storm.mp.pack(svc_manifest)

s_handler = function(payload, from, port) 
		print (string.format("from %s port %d: %s",from,port,payload))
	    end
ssock = storm.net.udpsocket(S_PORT, s_handler)

storm.os.invokePeriodically(5*storm.os.SECOND, function()
	storm.net.sendto(ssock, msg, "ff02::1", 1525)
	print("service table has been sent!")
end)

-- service that receives a string and simply prints it out
function svc_stdout(from_ip, from_port, msg)
  print (string.format("[STDOUT] (ip=%s, port=%d) %s", from_ip, from_port, msg))
end
