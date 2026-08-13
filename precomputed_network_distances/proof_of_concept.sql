WITH pairs AS (
    SELECT DISTINCT ON (a.intersection_id, b.intersection_id)
        a.intersection_id AS from_node,
        b.intersection_id AS to_node,
        round(st_distance(
            st_transform(a.geom, 2952),
            st_transform(b.geom, 2952)
        ))::smallint AS distance_m
    FROM gis_core.centreline_intersection_point_latest AS a
    JOIN gis_core.centreline_intersection_point_latest AS b
        ON a.intersection_id < b.intersection_id
        AND st_dwithin(
            st_transform(a.geom, 2952),
            st_transform(b.geom, 2952),
            1000
        )
    WHERE
        a.municipality = 'EAST YORK'
        AND b.municipality = 'EAST YORK'
),

sources AS (
    SELECT
        from_node,
        array_agg(to_node) AS target_ids
    FROM pairs
    GROUP BY from_node
    ORDER BY from_node
    LIMIT 100
),

paths AS (
    SELECT
        s.from_node AS start_vid,
        d.*
    FROM sources AS s
    CROSS JOIN LATERAL pgr_dijkstra(
        'select id, source, target, cost_length::float8 as cost
         from gis_core.routing_centreline_directional',
        s.from_node,
        s.target_ids,
        directed := TRUE
    ) AS d
),

assembled AS (
    SELECT
        p.start_vid,
        p.end_vid,
        st_union(
            st_linemerge(e.geom)
            ORDER BY p.path_seq
        ) AS geom
    FROM paths AS p
    JOIN gis_core.routing_centreline_directional AS e ON p.edge = e.id
    WHERE p.edge <> -1
    GROUP BY p.start_vid, p.end_vid
)

SELECT
    pr.from_node,
    pr.to_node,
    pr.distance_m,
    a.geom
FROM pairs AS pr
JOIN sources AS s ON pr.from_node = s.from_node
LEFT JOIN assembled AS a
    ON pr.from_node = a.start_vid
    AND pr.to_node = a.end_vid
ORDER BY pr.from_node, pr.to_node;