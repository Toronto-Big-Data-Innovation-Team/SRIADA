CREATE TABLE labs.wo_batches (
    batch_id serial PRIMARY KEY,
    district text,
    created timestamp DEFAULT NOW()
);
