/*
Stores work-order-level attributes specific to batches

Due to historical changes, there are two ways this is accessed
- First, it references work orders by a uid that is distinct within uploads
  This allows for a cascading delete if uploads are deleted
- Second, it references wonums within batches. Wonums will be distinct within
  batches, because batches are unique to uploads. The client is naive of 
  what here is being called work_order_uid so it references in this second way
*/

CREATE TABLE labs.wo_meta (
    work_order_uid int NOT NULL REFERENCES labs.work_orders (uid) ON DELETE CASCADE,
    batch_id int NOT NULL REFERENCES labs.wo_batches (batch_id) ON DELETE CASCADE,
    wonum int NOT NULL,
    batch_sequence smallint NOT NULL,
    tags text[],
    PRIMARY KEY (batch_id, wonum)
);

ALTER TABLE labs.wo_meta OWNER TO flashcrow;
