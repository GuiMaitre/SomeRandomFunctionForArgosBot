-- Put your global variables here
count = 0

--[[ This function is executed every time you press the 'execute' button ]]
function init()
    -- put your code here
    --enable vision cam
    robot.colored_blob_omnidirectional_camera.enable()
end

--moving
function driveAsCar(forwardSpeed, angularSpeed)
    leftSpeed  = forwardSpeed - angularSpeed
    rightSpeed = forwardSpeed + angularSpeed
    robot.wheels.set_velocity(leftSpeed,rightSpeed)
end

--obstacle avoidance
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

--make the bot wander until it goes over black surface
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

--debug de la vision pour afficher en log ce qu'il ce passe
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
            --  log("angle" .. math.deg(robot.colored_blob_omnidirectional_camera[i].angle))
        end
        --log("meanAng" .. meanAng)

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

--[[ This function is executed at each time step
It must contain the logic of your controller ]]
function step()
    -- getMeanDistance
    dist = 0
    for i = 1,#robot.colored_blob_omnidirectional_camera do
        dist = dist + robot.colored_blob_omnidirectional_camera[i].distance
        meanDist = dist/#robot.colored_blob_omnidirectional_camera
        --  log("angle" .. math.deg(robot.colored_blob_omnidirectional_camera[i].angle))
    end

    --avoid while going in the direction and go around if not on black
    if (meanDist >= 10) then
        joinBlack()
    else
        floor = getFloor(0)
        if ( floor == 0 ) then
            if count < 4 then
                count = count + 1
                robot.wheels.set_velocity(0,0)
                robot.leds.set_single_color(13, "red")
            end
        elseif (floor < 0) && (floor <= 2) then
            --chopper l'angle et le faire aller dans le bon sens (line follow) et stopper quand capteur interne ok
        elseif (floor > 2) then
            --gauche ou droite et inverse après avec test de distance
        end
    end
end


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

