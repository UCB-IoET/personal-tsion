require "cord"
sh = require "stormsh"
shield = require("starter")

table = {}

S_PORT = 1626
R_PORT = 1625

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

function pt(x) for k,v in pairs(x) do print("", "", k,v) end end

function print_msg(msg)
   if (type(msg) ~= "table") then
	  print("Malformed service [type=%s]", type(msg))
	  return {}
   end

   for k,v in pairs(msg) do
	  if (k ~= "id") then
		 if type(v) ~= "table" then
			print("", k, v)
		 else
			print("", k)
			pt(v)
		 end
	  else
		 print("", k, v)
	  end
   end

   return msg
end

----------------------- S Main --------------------------

function s_main()
	-- service announcement table
        local svc_manifest = { id= "Sin Nombre", setRlyA={ s="setBool", desc= "red LED"}}
        local msg = storm.mp.pack(svc_manifest) -- pack service announcement table
        -- set up udp socket
        ssock = storm.net.udpsocket(R_PORT, function(payload, from, port)
						print (string.format("We're not stupid: from %s port %d: %s",from,port,payload))
                                                table[from] = storm.mp.unpack(payload)
                                                --pprint(table)
					     end)

        serviceSock = storm.net.udpsocket(S_PORT, function(payload, from, port)
          print (string.format("We're stupid: from %s port %d: %s", from, port, payload))
        end)



        storm.os.invokePeriodically(5*storm.os.SECOND, function()
                print(msg)
                storm.net.sendto(ssock, msg, "ff02::1", R_PORT)
		print("service table has been sent!")
		end)
end
---------------------- R Main --------------------------

function r_main()
	-- service announcement table
	local svc_manifest ={ id = "Firestorm2", redLED={ s="setBool", desc= "red LED"}}       
	local msg = storm.mp.pack(svc_manifest)

	-- service invocation message
        local svc_invoke ={"setLEDblue", {1}}
        invoke_msg = storm.mp.pack(svc_invoke)  -- pack service invocation

	--- set up socket
	rsock = storm.net.udpsocket(R_PORT, function(payload, from, port)
					print (string.format("from %s port %d:",from,port))
					
					table[from] = storm.mp.unpack(payload)
					pprint()
					svc_stdout(from, port, storm.mp.unpack(payload))
				    end)


	--- send service table
	storm.os.invokePeriodically(5*storm.os.SECOND, function()
						storm.net.sendto(rsock, msg, "ff02::1", R_PORT)
						print("service table has been sent!")
						for location, service_announcement in pairs(table) do
							print ("location:", location)
							for id, services_offered in pairs(service_announcement) do
								print ("id:", id)
								--print ("services_offered ", services_offered)
								if (services_offered.s == "setBool") then
									print("found service of type setBool:", services_offered.desc)
									local svc_invoke = {id, {1}}
									local msg_sent = storm.mp.pack(svc_invoke)
									storm.net.sendto(rsock, msg_sent, location, S_PORT)
									print (string.format("to %s port %d: %s", location, S_PORT, msg_sent))
				                                end
								--print ("Checked services offered.")
                       					 end
                				end
	      
					end)
end

-- service that receives msg and carries out call
function svc_stdout(from_ip, from_port, msg)
	--print (string.format("[STDOUT] (ip=%s, port=%d) %s", from_ip, from_port, msg))
	--print (string.format("[STDOUT] (ip=%s, port=%d)", from_ip, from_port))
	--print(msg.setRlyA)	
	--local invoke = msg.setRlyA
	--if invoke == 1 then
	--	shield.LED.on("blue")
	--	print("Decoded message!")
	--end
	print("Decoded message!")
end

sh.start()
shield.LED.start()
cord.enter_loop()
