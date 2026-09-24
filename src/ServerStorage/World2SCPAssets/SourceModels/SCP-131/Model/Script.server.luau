s1 = script.S1
s2= script.S2
s3 = script.S3
s4= script.S4
s5 = script.S5


local sayings = {s1,s2,s3,s4,s5}
while true do
wait(math.random(2,10))
	sayings[math.random(1,#sayings)]:Play()
end
