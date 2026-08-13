CREATE TABLE labs.sr_meta (
    batch_id int NOT NULL REFERENCES labs.sr_batches (batch_id),
    wonum int NOT NULL REFERENCES labs.service_requests (wonum),
    batch_sequence smallint NOT NULL,
    tags text[],
    PRIMARY KEY (batch_id, wonum)
);
