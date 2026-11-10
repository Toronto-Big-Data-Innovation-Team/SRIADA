/*
Stores work-order-level attributes specific to batches
*/

CREATE TABLE labs.wo_meta (
    work_order_uid int REFERENCES labs.work_orders (uid) ON DELETE CASCADE,
    batch_id int NOT NULL REFERENCES labs.wo_batches (batch_id) ON DELETE CASCADE,
    wonum int NOT NULL,
    batch_sequence smallint NOT NULL,
    tags text[],
    PRIMARY KEY (batch_id, wonum)
);

ALTER TABLE labs.wo_meta OWNER TO flashcrow;
