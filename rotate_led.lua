require("cord") -- scheduler / fiber library
require("storm")
shield = require("starter")

counter = 0

function right()
  if counter == 0 then
     shield.LED.on("red2")
  end

  if counter == 1 then
     shield.LED.on("red2")
     shield.LED.off("blue")
  end
  if counter == 2 then
     shield.LED.on("red")
     shield.LED.off("red2")
  end
  if counter == 3 then
     shield.LED.on("green")
     shield.LED.off("red")
  end
  if counter == 4 then
     shield.LED.on("blue")
     shield.LED.off("green")
  end
  counter = (counter%4) + 1
end

function left()
  if counter == 0 then
     shield.LED.on("blue")
  end

  if counter == 1 then
     shield.LED.on("green")
     shield.LED.off("blue")
  end
  if counter == 2 then
     shield.LED.on("red")
     shield.LED.off("green")
  end
  if counter == 3 then
     shield.LED.on("red2")
     shield.LED.off("red")
  end
  if counter == 4 then
     shield.LED.on("blue")
     shield.LED.off("red2")
  end

  counter = (counter%4) + 1
end

function reset()
  counter = 0
  shield.LED.off("red2")
  shield.LED.off("red2")
  shield.LED.off("green")
  shield.LED.off("blue")
end

shield.LED.start()
shield.Button.start()

reset()
shield.Button.whenever(1, "RISING", right)
shield.Button.whenever(2, "RISING", left)
shield.Button.whenever(3, "RISING", reset)


cord.enter_loop()
