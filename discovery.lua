require "cord"
sh = require "stormsh"
shield = require("starter")

table = {}

S_PORT = 1526
R_PORT = 1525

function pprint()
	print("print table function")
	print(" ")
	for k,v in pairs(table) do
		for i,j in pairs(v) do
			if type(j)=="table" then 
				for a,b in pairs(j) do 
					print(k,i,a,b)
				end
			else
				print(k,i,j)
			end
		end
	end
	print(" ")
end

----------------------- S Main --------------------------
function s_main()
	-- service announcement table
	local svc_manifest = { id= "Sin Nombre", setRlyA={ s="setBool", desc= "red LED"}}
	local msg = storm.mp.pack(svc_manifest) -- pack service announcement table

	-- service invocation message
	local svc_invoke ={["setRlyA"]=1}
	msg = storm.mp.pack(svc_invoke)  -- pack service invocation

	-- set up udp socket
	ssock = storm.net.udpsocket(S_PORT, function(payload, from, port) 
						print (string.format("from %s port %d: %s",from,port,payload))
						--table[from] = storm.mp.unpack(payload)
						table[from] = svc_manifest
						pprint()
						--msg = storm.mp.pack(svc_invoke)
				     	end)


	storm.os.invokePeriodically(1*storm.os.SECOND, function()
								print(msg)
								storm.net.sendto(ssock, msg, "ff02::1", R_PORT)
								print("service table has been sent!")
							end)

end

---------------------- R Main --------------------------

function r_main()
	-- service announcement table
	local svc_manifest ={ id = "Firestorm2", setRlyA={ s="setBool", desc= "red LED"}}       
	local msg = storm.mp.pack(svc_manifest)

	-- service invocation message
        local svc_invoke ={["setRlyA"]=1}
        msg = storm.mp.pack(svc_invoke)  -- pack service invocation

	--- set up socket
	rsock = storm.net.udpsocket(R_PORT, function(payload, from, port)
					print (string.format("from %s port %d: %s",from,port,payload))
					table[from] = storm.mp.unpack(payload)
					pprint()
					svc_stdout(from, port, storm.mp.unpack(payload))
				    end)


	--- send service table
	storm.os.invokePeriodically(500*storm.os.MILLISECOND, function()
								storm.net.sendto(rsock, msg, "ff02::1", R_PORT)
								print("service table has been sent!")
							      end)
end

-- service that receives msg and carries out call
function svc_stdout(from_ip, from_port, msg)
	--print (string.format("[STDOUT] (ip=%s, port=%d) %s", from_ip, from_port, msg))
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
