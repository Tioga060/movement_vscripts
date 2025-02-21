//movement_scripts.nut by Tioga060

// --------------Helper Functions-------------- //

// Take dot product of two vectors or vector and scalar
function dotMultiply(v1,v2)
{
	local vector2Type = typeof(v2);
	
	//Vector * Scalar
	if(vector2Type == "integer" || vector2Type == "float")
	{
		return Vector(v1.x*v2,v1.y*v2,v1.z*v2);
	}
	//Vector * Vector
	if(vector2Type == "Vector")
	{
		return Vector(v1.x*v2.x,v1.y*v2.y,v1.z*v2.z);
	}
	return null;
}

function toVector(qAngle) {
	if (typeof(qAngle) == "QAngle") {
		return Vector(qAngle.x, qAngle.y, qAngle.z);
	}
	// else assume it is a vector already
	return qAngle;
}

function toQAngle(vector) {
	if (typeof(vector) == "QAngle") {
		return vector;
	}
	return QAngle(vector.x, vector.y, vector.z);
}

// Normalizes the given vector
function normalize(v)
{
	v = toVector(v);
	local len = v.Length();
	return Vector(v.x/len,v.y/len,v.z/len);
}

function qAngleToNormalizedVectorXY(qAngle) {
	return rotateVectorAroundZ(Vector(1, 0, 0), qAngle.y);
}

function eyeAngleToNormalizedVector(eyeAngles) {
	local yaw = toRadians(eyeAngles.y);
	local pitch = toRadians(eyeAngles.x);
	local x = cos(yaw)*cos(pitch);
	local y = sin(yaw)*cos(pitch);
	local z = -sin(pitch);
	return normalize(Vector(x, y, z));
}

local PI = 3.14159;
function toDegrees(radians) {
	return radians * 180 / PI;
}

function toRadians(degrees) {
	return degrees * PI / 180;
}

function rotateVectorAroundZ(v, degrees) {
	local radians = toRadians(degrees);
	local x = v.x * cos(radians) - v.y * sin(radians);
	local y = v.x * sin(radians) + v.y * cos(radians);
	return Vector(x, y, v.z);
}

function getXYSpeed(ent) {
	local velocity = ent.GetAbsVelocity();
	return sqrt(pow(velocity.x, 2) + pow(velocity.y, 2));
}

function getAbsoluteSpeed(ent) {
	local velocity = ent.GetAbsVelocity();
	return sqrt(pow(velocity.x, 2) + pow(velocity.y, 2) + pow(velocity.z, 2));
}

// --------------Movement Functions-------------- //

// Reverses a player's velocity on the given axis
function BouncePlayer(axis) {
  local startVelocity = activator.GetAbsVelocity();
  activator.SetVelocity(Vector(0,0,0));
  switch(axis){
		case 0:
      // X
			activator.SetVelocity(dotMultiply(startVelocity, Vector(-1, 1, 1)));
			break;
		case 1:
      // Y
			activator.SetVelocity(dotMultiply(startVelocity, Vector(1, -1, 1)));
			break;
		case 2:
      // Z
			activator.SetVelocity(dotMultiply(startVelocity, Vector(1, 1, -1)));
			break;
	}
}

// Sets player's vertical velocity to zero and sets their gravity to almost zero
function StartSkating() {
  local startVelocity = activator.GetAbsVelocity();
  activator.SetVelocity(Vector(startVelocity.x, startVelocity.y, 0));
  activator.SetGravity(0.000000001);
}

// Resets player's gravity
function FinishSkating() {
  activator.SetGravity(1);
}

// Teleports a player to the given entityName
// set snapToDestinationAngles to 1 to snap the player's velocity and eye angles to the destination
// set useCallerOffset to 1 to translate the player's destination relative to the input's origin (like a traditional landmark teleport)
// Trigger must have its name set to the angle the player will be entering from
function LandmarkTeleportXY(entityName, snapToDestinationAngles, useCallerOffset) {
	// Only supports rotations around the Z axis
	local destination = Entities.FindByName(null, entityName);
	if (destination == null) {
		printl("Entity not found: " + entityName);
		return;
	};

	local callerAngle = caller.GetName().tointeger();

	local positionDelta = Vector(0,0,0);
	if (useCallerOffset == 1) {
		local angleDelta = destination.GetAbsAngles().y - callerAngle;
		positionDelta = activator.GetOrigin() - caller.GetOrigin();
		
		positionDelta = rotateVectorAroundZ(positionDelta, angleDelta);
	}

	activator.SetAbsOrigin(destination.GetOrigin() + positionDelta);
	local activatorSpeed = getXYSpeed(activator);
	local activatorVelocity = activator.GetAbsVelocity();

	if (snapToDestinationAngles == 1) {
		local destinationAngle = destination.GetAbsAngles();
		activator.SnapEyeAngles(destinationAngle);
		local xyVelocity = qAngleToNormalizedVectorXY(destinationAngle) * activatorSpeed;
		activator.SetVelocity(Vector(xyVelocity.x, xyVelocity.y, activatorVelocity.z));
	} else {
		local lookAngleDelta = activator.EyeAngles().y - callerAngle;
		local velocityAngleDelta = callerAngle - toDegrees(atan2(activatorVelocity.y, activatorVelocity.x));
		local destinationAngle = destination.GetAbsAngles();
		local xyVelocity = qAngleToNormalizedVectorXY(QAngle(destinationAngle.x, destinationAngle.y + velocityAngleDelta, destinationAngle.z)) * activatorSpeed;
		activator.SnapEyeAngles(QAngle(activator.EyeAngles().x, destinationAngle.y + lookAngleDelta, activator.EyeAngles().z));
		activator.SetVelocity(Vector(xyVelocity.x, xyVelocity.y, activatorVelocity.z));
	}
}

// Redirects all of a player's velocity to the direction they are looking
function RedirectVelocityToEyeAngles() {
	local speed = getAbsoluteSpeed(activator);
	activator.SetVelocity(eyeAngleToNormalizedVector(activator.EyeAngles()) * speed);
}
