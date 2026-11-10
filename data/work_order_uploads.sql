/*
Track when data was uploaded by supervisors

This will let us isolate data per upload and
also clean up stale data as necessary.
*/

CREATE TABLE labs.work_order_uploads (
    uid smallserial PRIMARY KEY,
    upload_time timestamp DEFAULT NOW()
);

ALTER TABLE labs.work_order_uploads OWNER TO flashcrow;
