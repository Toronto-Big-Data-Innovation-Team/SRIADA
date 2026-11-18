/*
   Batches contain a set of work orders distinct to an upload
   They are contained within a district, though this is enforced
   only at the client level
*/

CREATE TABLE labs.wo_batches (
    batch_id serial PRIMARY KEY,
    upload_uid smallint REFERENCES labs.work_order_uploads (uid) ON DELETE CASCADE,
    district text,
    created timestamp DEFAULT NOW()
);

ALTER TABLE labs.wo_batches OWNER TO flashcrow;
