-- Put your global variables here
count = 0

--[[ This function is executed every time you press the 'execute' button ]]
function init()
    -- put your code here
    --enable vision cam
    robot.colored_blob_omnidirectional_camera.enable()
end

--moving ______________________________________________________________________________________________________________________________________________
function driveAsCar(forwardSpeed, angularSpeed)
    leftSpeed  = forwardSpeed - angularSpeed
    rightSpeed = forwardSpeed + angularSpeed
    robot.wheels.set_velocity(leftSpeed,rightSpeed)
end
-- ______________________________________________________________________________________________________________________________________________

--obstacle avoidance ______________________________________________________________________________________________________________________________________________
function avoiding(proxiLeft, proxiRight)
    for i = 1,5 do
        proxiLeft = proxiLeft + robot.proximity[i].value
    end
    for i = 19,24 do
        proxiRight = proxiRight + robot.proximity[i].value
    end

    if (proxiLeft ~= 0) and (proxiRight ~= 0) then
        --log("turn around")
        driveAsCar(0,40)
    elseif (proxiLeft ~= 0) and (proxiRight == 0) then
        --log("turn left")
        driveAsCar(30,-35)
    elseif (proxiLeft == 0) and (proxiRight ~= 0) then
        --log("turn right")
        driveAsCar(40,35)
    else
        --log("foward")
        driveAsCar(20,0)
    end
end

--get the color of the floor
function getFloor(floor)
    for i = 1,4 do
        floor = floor + robot.motor_ground[i].value
    end
    return floor
end
-- ______________________________________________________________________________________________________________________________________________

--make the bot wander until it goes over black surface _______________________________________________________________________
function wanderToBlack()
    floor = getFloor(0)
    if floor ~= 0 then
        avoiding(0, 0)
    else
        count = count + 1
        if count <= 15 then
            log ("Black floor")
            avoiding(0, 0)

            floor = getFloor(0)
            if floor ~= 0 then
                log ("retour arriere")
                avoiding(20,20)
            end
        else
            robot.wheels.set_velocity(0,0)
        end
        -- add the blink of led to get attention from other
        robot.leds.set_single_color(13, "red")
    end
end
-- ______________________________________________________________________________________________________________________________________________

--debug de la vision pour afficher en log ce qu'il ce passe _______________________________________________________________________
function visionDebug()
    for i = 1, #robot.colored_blob_omnidirectional_camera do
        blob = robot.colored_blob_omnidirectional_camera[i]
        log("dist: " .. blob.distance)
        log("angle: " .. blob.angle)
        log("red: " .. blob.color.red ..
        " / blue: " .. blob.color.blue ..
        " / green: " .. blob.color.green)
    end
end
-- ______________________________________________________________________________________________________________________________________________

-- ______________________________________________________________________________________________________________________________________________
function joinBlack()
    if #robot.colored_blob_omnidirectional_camera == 0 then
        wanderToBlack()
    elseif  #robot.colored_blob_omnidirectional_camera >= 1 then
        --init turning to the direction of the well placed robot
        ang = 0
        meanAng = 0
        --Get the mean of the different angles of other seen bot
        for i = 1,#robot.colored_blob_omnidirectional_camera do
            ang = ang + math.deg(robot.colored_blob_omnidirectional_camera[i].angle)
            meanAng = ang/#robot.colored_blob_omnidirectional_camera
        end
        --If the mean of the angle is less than 20 go foward, else turn
        if (meanAng >= 20) then
            robot.wheels.set_velocity(-1,1)
        elseif (meanAng <= -20) then
            robot.wheels.set_velocity(1,-1)
        else
            wanderToBlack()
        end
    end
end
-- ______________________________________________________________________________________________________________________________________________

--line follow and turn _______________________________________________________________________
function lineFollow()
    proxiLeft = 0
    proxiRight = 0
    for i = 1,12 do
        proxiLeft = proxiLeft + robot.proximity[i].value
    end
    for i = 13,24 do
        proxiRight = proxiRight + robot.proximity[i].value
    end

    if (proxiLeft > 0) and (proxiRight == 0) then
        --black on left of bot
        if (robot.motor_ground[1].value == 0) and (robot.motor_ground[2].value == 0) then
            wanderToBlack()

        --black on front of bot
        elseif (robot.motor_ground[1].value == 0) and (robot.motor_ground[4].value == 0) then
            wanderToBlack()

        --black on right of bot
        elseif (robot.motor_ground[3].value == 0) and (robot.motor_ground[4].value == 0) then
            driveAsCar(40,35)

        --one motor on black
        else
            if (robot.motor_ground[1].value == 0) or (robot.motor_ground[2].value == 0) then
                driveAsCar(0,0)
            elseif (robot.motor_ground[3].value == 0) or (robot.motor_ground[4].value == 0) then
                driveAsCar(40,35)
            end
        end
    elseif (proxiLeft == 0) and (proxiRight > 0) then
        --black on left of bot
        if (robot.motor_ground[1].value == 0) and (robot.motor_ground[2].value == 0) then
            driveAsCar(40,-35)
        --black on front of bot
        elseif (robot.motor_ground[1].value == 0) and (robot.motor_ground[4].value == 0) then
            wanderToBlack()
        --black on right of bot
        elseif (robot.motor_ground[3].value == 0) and (robot.motor_ground[4].value == 0) then
            wanderToBlack()
        --one motor on black
        else
            if (robot.motor_ground[3].value == 0) or (robot.motor_ground[4].value == 0) then
                driveAsCar(0,0)
            elseif (robot.motor_ground[1].value == 0) or (robot.motor_ground[2].value == 0) then
                driveAsCar(40,-35)
            end
        end
    -- SI rien en proxy
    else
        wanderToBlack()
    end
end
-- ______________________________________________________________________________________________________________________________________________


--[[ This function is executed at each time step _______________________________________________________________________
It must contain the logic of your controller ]]
function step()
    -- getMeanDistance
    dist = 0
    meanDist = 0
    for i = 1,#robot.colored_blob_omnidirectional_camera do
        dist = dist + robot.colored_blob_omnidirectional_camera[i].distance
        meanDist = dist/#robot.colored_blob_omnidirectional_camera
        --  log("angle" .. math.deg(robot.colored_blob_omnidirectional_camera[i].angle))
    end

    --avoid while going in the direction and go around if not on black
    if (meanDist >= 10) or (meanDist == 0) then
        joinBlack()
    else
        floor = getFloor(0)
        if ( floor == 0 ) then
            if count > 4 then
                count = count + 1
                robot.wheels.set_velocity(0,0)
                robot.leds.set_single_color(13, "red")
            else
                avoiding(0, 0)
            end
        elseif (floor > 0) and (floor <= 3) then
            --[[chopper l'angle et le faire aller dans le bon sens (line follow) et
                stopper quand capteur interne ok]]
            lineFollow()
        else
            --random move
            driveAsCar(40,35)
        end
    end
end
-- ______________________________________________________________________________________________________________________________________________

--[[ This function is executed every time you press the 'reset'
button in the GUI. It is supposed to restore the state
of the controller to whatever it was right after init() was
called. The state of sensors and actuators is reset
automatically by ARGoS. ]]
function reset()
-- put your code here
end


--[[ This function is executed only once, when the robot is removed
from the simulation ]]
function destroy()
-- put your code here
end

