/*
This is a placeholder since we don't really know the eventual table structure
*/

CREATE TABLE labs.service_requests (
    wonum integer PRIMARY KEY,
    description text,
    location text,
    failurecode text,
    problemcode text,
    status text,
    supervisor text,
    ownergroup text,
    worktype text,
    wopriority text,
    reportdate text,
    targstartdate text,
    siteid text,
    statusdate text,
    assignedownergroup text,
    latitudey numeric,
    longitudex numeric,
    cotward text,
    geom geometry(Point,4326)
);
