/*
Reprojects uploaded work order data on the fly.
When the client is fetching work order data from the
server it should always come through this view.
*/

CREATE OR REPLACE VIEW labs.work_orders_projected AS

SELECT
    *,
    ST_Transform(
        ST_SetSRID(
            ST_MakePoint(work_orders.longitudex, work_orders.latitudey),
            102113 -- web mercator inputs
            ),
        4326 -- unprojected lat/lon outputs
    ) AS geom
FROM labs.work_orders;
