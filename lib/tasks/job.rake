while true
    if Time.now % 60000 = 0
       puts "job.rake job run. #{Time.now}"     
    end
end