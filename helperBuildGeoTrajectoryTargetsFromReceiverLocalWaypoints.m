function targets = helperBuildGeoTrajectoryTargetsFromReceiverLocalWaypoints( ...
    waypoints, options)
%HELPERBUILDGEOTRAJECTORYTARGETSFROMRECEIVERLOCALWAYPOINTS Convert ENU input.
%
%   TARGETS = HELPERBUILDGEOTRAJECTORYTARGETSFROMRECEIVERLOCALWAYPOINTS(
%   WAYPOINTS) converts a receiver-local waypoint table into the
%   GeoTrajectoryTargets structure accepted by the echo generator.
%
%   WAYPOINTS must have Time_s, North_m, East_m, and Altitude_m columns.

arguments
    waypoints table
    options.ReceiverLla_deg_m (1,3) double {mustBeFinite}
    options.TargetId (1,1) string = "FIELD_DEMO_TARGET_1"
    options.IcaoHex (1,1) string = "FIELD01"
    options.Callsign (1,1) string = "SYNTH01"
    options.EchoGainDB (1,1) double {mustBeFinite} = -18.0
end

requiredVariables = [ ...
    "Time_s", "North_m", "East_m", "Altitude_m"];
availableVariables = string(waypoints.Properties.VariableNames);
missingVariables = setdiff(requiredVariables, availableVariables);

if ~isempty(missingVariables)
    error("helperBuildGeoTrajectoryTargetsFromReceiverLocalWaypoints:Variables", ...
        "Waypoint table is missing: %s.", strjoin(missingVariables, ", "));
end

if height(waypoints) < 2
    error("helperBuildGeoTrajectoryTargetsFromReceiverLocalWaypoints:Count", ...
        "Waypoint table requires at least two rows.");
end

time_s = double(waypoints.Time_s(:));
north_m = double(waypoints.North_m(:));
east_m = double(waypoints.East_m(:));
altitude_m = double(waypoints.Altitude_m(:));
numericValues = [time_s, north_m, east_m, altitude_m];

if any(~isfinite(numericValues), "all") || ...
        any(time_s < 0.0) || any(diff(time_s) <= 0.0)
    error("helperBuildGeoTrajectoryTargetsFromReceiverLocalWaypoints:Values", ...
        "Waypoint values must be finite with strictly increasing nonnegative time.");
end

range_m = hypot(north_m, east_m);
azimuth_deg = mod(atan2d(east_m, north_m), 360.0);
[latitude_deg, longitude_deg] = reckon( ...
    options.ReceiverLla_deg_m(1), options.ReceiverLla_deg_m(2), ...
    range_m, azimuth_deg, wgs84Ellipsoid("meter"));

targets = struct( ...
    target_id=options.TargetId, ...
    icao_hex=options.IcaoHex, ...
    callsign=options.Callsign, ...
    echo_gain_db=options.EchoGainDB, ...
    waypoints_lla_deg_m=[latitude_deg(:), longitude_deg(:), altitude_m], ...
    time_of_arrival_s=time_s);

end
