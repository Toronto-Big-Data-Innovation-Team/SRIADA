CREATE TABLE labs.wo_meta (
    batch_id int NOT NULL REFERENCES labs.wo_batches (batch_id) ON DELETE CASCADE,
    wonum int NOT NULL REFERENCES labs.work_orders (wonum),
    batch_sequence smallint NOT NULL,
    tags text[],
    PRIMARY KEY (batch_id, wonum)
);
