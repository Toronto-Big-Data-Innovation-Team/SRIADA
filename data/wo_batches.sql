CREATE TABLE labs.wo_batches (
    batch_id serial PRIMARY KEY,
    upload_uid smallint REFERENCES labs.work_order_uploads (uid) ON DELETE CASCADE,
    district text,
    created timestamp DEFAULT NOW()
);

ALTER TABLE labs.wo_batches OWNER TO flashcrow;
