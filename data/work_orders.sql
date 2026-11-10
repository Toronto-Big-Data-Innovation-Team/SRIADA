/*
Table for uploaded work order data
*/

CREATE TABLE labs.work_orders (
    upload_uid smallint NOT NULL REFERENCES labs.work_order_uploads (uid),
    wonum integer NOT NULL,
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
    latitudey numeric NOT NULL,
    longitudex numeric NOT NULL,
    cotward text,
    PRIMARY KEY (upload_uid, wonum)
);

ALTER TABLE labs.work_orders OWNER TO flashcrow;
