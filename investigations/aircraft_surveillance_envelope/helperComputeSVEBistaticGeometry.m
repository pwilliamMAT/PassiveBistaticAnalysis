function [geometry, audit] = helperComputeSVEBistaticGeometry( ...
        states, config, altitudeOffset_m)
%HELPERCOMPUTESVEBISTATICGEOMETRY Compute exact-vector bistatic geometry.

arguments
    states table
    config (1,1) struct
    altitudeOffset_m (1,1) double = 0.0
end

ellipsoid = wgs84Ellipsoid("meter");
receiver = config.ReceiverLLA_deg_m;
transmitter = config.TransmitterLLA_deg_m;
positionENU = double(states.PositionENU_m);
positionENU(:, 3) = positionENU(:, 3) + altitudeOffset_m;
velocityENU = double(states.VelocityENU_mps);

[targetX, targetY, targetZ] = enu2ecef( ...
    positionENU(:, 1), positionENU(:, 2), positionENU(:, 3), ...
    receiver(1), receiver(2), receiver(3), ellipsoid);
targetECEF = [targetX, targetY, targetZ];
[velocityX, velocityY, velocityZ] = enu2ecefv( ...
    velocityENU(:, 1), velocityENU(:, 2), velocityENU(:, 3), ...
    receiver(1), receiver(2));
velocityECEF = [velocityX, velocityY, velocityZ];
[receiverX, receiverY, receiverZ] = geodetic2ecef(ellipsoid, ...
    receiver(1), receiver(2), receiver(3));
[transmitterX, transmitterY, transmitterZ] = geodetic2ecef(ellipsoid, ...
    transmitter(1), transmitter(2), transmitter(3));
receiverECEF = [receiverX, receiverY, receiverZ];
transmitterECEF = [transmitterX, transmitterY, transmitterZ];

targetFromTransmitter = targetECEF - transmitterECEF;
targetFromReceiver = targetECEF - receiverECEF;
transmitterRange_m = vecnorm(targetFromTransmitter, 2, 2);
receiverRange_m = vecnorm(targetFromReceiver, 2, 2);
baseline_m = norm(receiverECEF - transmitterECEF);
excessRange_m = transmitterRange_m + receiverRange_m - baseline_m;
roundoffTolerance_m = 128 .* eps(max( ...
    transmitterRange_m + receiverRange_m + baseline_m, 1.0));
materiallyNegative = excessRange_m < -roundoffTolerance_m;
if any(materiallyNegative)
    error("PBR:SVE:NegativeExcessRange", ...
        "%d states have materially negative excess range.", ...
        sum(materiallyNegative));
end
roundoffCorrected = excessRange_m < 0.0;
excessRange_m(roundoffCorrected) = 0.0;

speedOfLight_mps = physconst("LightSpeed");
wavelength_m = speedOfLight_mps ./ config.CarrierFrequency_Hz;
transmitterUnit = targetFromTransmitter ./ transmitterRange_m;
receiverUnit = targetFromReceiver ./ receiverRange_m;
pathRate_mps = sum((transmitterUnit + receiverUnit) .* ...
    velocityECEF, 2);
dopplerPhysical_Hz = -(config.CarrierFrequency_Hz ./ ...
    speedOfLight_mps) .* pathRate_mps;
targetToTransmitterUnit = -transmitterUnit;
targetToReceiverUnit = -receiverUnit;
bistaticCosine = sum(targetToTransmitterUnit .* ...
    targetToReceiverUnit, 2);
bistaticCosine = min(max(bistaticCosine, -1.0), 1.0);
bistaticAngle_deg = rad2deg(acos(bistaticCosine));
speed_mps = vecnorm(velocityECEF, 2, 2);
dopplerBound_Hz = 2.0 .* speed_mps ./ wavelength_m .* ...
    cosd(bistaticAngle_deg ./ 2.0);
dopplerBoundPassed = abs(dopplerPhysical_Hz) <= ...
    dopplerBound_Hz + 1e-9 .* max(dopplerBound_Hz, 1.0);
if ~all(dopplerBoundPassed)
    error("PBR:SVE:DopplerBound", ...
        "%d states violate the bistatic-angle Doppler bound.", ...
        sum(~dopplerBoundPassed));
end

[latitude_deg, longitude_deg, geometricAltitude_m] = ecef2geodetic( ...
    ellipsoid, targetX, targetY, targetZ);
transmitterVisible = localEllipsoidLineOfSight( ...
    transmitterECEF, targetECEF, ellipsoid);
receiverVisible = localEllipsoidLineOfSight( ...
    receiverECEF, targetECEF, ellipsoid);

physicalDelay_s = excessRange_m ./ speedOfLight_mps;
geometry = table( ...
    latitude_deg, longitude_deg, geometricAltitude_m, ...
    hypot(positionENU(:, 1), positionENU(:, 2)), receiverRange_m, ...
    transmitterRange_m, repmat(baseline_m, height(states), 1), ...
    speed_mps, bistaticAngle_deg, excessRange_m, physicalDelay_s, ...
    -physicalDelay_s, dopplerPhysical_Hz, -dopplerPhysical_Hz, ...
    transmitterRange_m .^ 2 .* receiverRange_m .^ 2, ...
    transmitterVisible, receiverVisible, ...
    repmat(altitudeOffset_m, height(states), 1), ...
    'VariableNames', { ...
    'Latitude_deg', 'Longitude_deg', 'ApproximateGeometricAltitude_m', ...
    'HorizontalReceiverRange_m', 'ReceiverRange_m', ...
    'TransmitterRange_m', 'Baseline_m', 'Speed_mps', ...
    'BistaticAngle_deg', 'ExcessRange_m', 'PhysicalDelay_s', ...
    'ProcessingDelay_s', 'PhysicalDoppler_Hz', ...
    'ProcessingDoppler_Hz', 'SpreadingGeometry_m4', ...
    'TransmitterEllipsoidLOS', 'ReceiverEllipsoidLOS', ...
    'AppliedAltitudeOffset_m'});

audit = struct;
audit.Baseline_m = baseline_m;
audit.RoundoffCorrectionCount = sum(roundoffCorrected);
audit.MateriallyNegativeCount = sum(materiallyNegative);
audit.DopplerBoundPassed = all(dopplerBoundPassed);
audit.WorstCaseDoppler300mps_Hz = 2.0 .* 300.0 ./ wavelength_m;
audit.WorstCaseDopplerCheckPassed = ...
    abs(audit.WorstCaseDoppler300mps_Hz - 1200.0) <= 5.0;
audit.TransmitterVisibleFraction = mean(transmitterVisible);
audit.ReceiverVisibleFraction = mean(receiverVisible);
audit.AltitudeDatumStatus = config.AltitudeDatumStatus;
audit.AppliedAltitudeOffset_m = altitudeOffset_m;

end

function visible = localEllipsoidLineOfSight(endpoint, target, ellipsoid)

axes_m = [ellipsoid.SemimajorAxis, ellipsoid.SemimajorAxis, ...
    ellipsoid.SemiminorAxis];
startPoint = endpoint ./ axes_m;
endPoint = target ./ axes_m;
direction = endPoint - startPoint;
denominator = sum(direction .^ 2, 2);
projection = -sum(startPoint .* direction, 2) ./ denominator;
projection = min(max(projection, 0.0), 1.0);
nearestPoint = startPoint + projection .* direction;
minimumScaledRadius = vecnorm(nearestPoint, 2, 2);
visible = minimumScaledRadius >= 1.0 - 1e-12;

end
