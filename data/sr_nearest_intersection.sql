CREATE OR REPLACE VIEW labs.sr_nearest_intersection AS

SELECT
    service_requests.wonum,
    nearest.centreline_id
FROM labs.service_requests
CROSS JOIN LATERAL (
    SELECT
        centreline_id,
        geom,
        -- this transformation is indexed on the intersections side
        ST_Transform(service_requests.geom, 2952) <-> ST_Transform(intersections.geom, 2952) AS dist
    FROM centreline2.intersections
    ORDER BY dist
    LIMIT 1
) AS nearest
WHERE service_requests.geom IS NOT NULL;
