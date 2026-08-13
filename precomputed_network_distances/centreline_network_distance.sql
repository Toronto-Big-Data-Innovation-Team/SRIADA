-- ============================================================
-- Approximate network distance + route geometry between
-- centreline intersections, within 1000m 
-- ============================================================

DROP TABLE IF EXISTS whalabi.centreline_network_distance;

CREATE TABLE whalabi.centreline_network_distance (
    from_node integer NOT NULL,
    to_node integer NOT NULL,
    distance_m smallint NOT NULL,
    geom geometry,
    PRIMARY KEY (from_node, to_node)
);

COMMENT ON TABLE whalabi.centreline_network_distance IS
'Straight-line (Euclidean) distance between centreline intersections within 1000m.
distance_m is NOT a network distance, it is a fast approximation for sorting or
TSP-heuristic use. geom, where populated, is the actual routed street path between
the two nodes (ignores turn restrictions). Symmetric by construction: one row per
unordered pair, so A-to-B and B-to-A share a row even though the underlying network
is directed and could differ.';


-- Step 1: populate distance_m for every pair within 1000m,
-- using the transformed-geometry GiST index.

INSERT INTO whalabi.centreline_network_distance (from_node, to_node, distance_m)
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
ON CONFLICT (from_node, to_node) DO NOTHING;


-- Step 2: populate geom for every pair above with the actual
-- routed path. Grouped by from_node so each pgr_dijkstra call
-- gets a small, already-filtered target list, not the full
-- node set (avoids the earlier memory error). Resumable:
-- "where geom is null" means a rerun only picks up unfinished
-- rows.

WITH sources AS (
    SELECT
        from_node,
        array_agg(to_node) AS target_ids
    FROM whalabi.centreline_network_distance
    WHERE geom IS NULL
    GROUP BY from_node
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

UPDATE whalabi.centreline_network_distance d
SET geom = a.geom
FROM assembled AS a
WHERE
    d.from_node = a.start_vid
    AND d.to_node = a.end_vid;