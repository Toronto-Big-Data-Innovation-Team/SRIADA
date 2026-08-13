-- ============================================================
-- Approximate + real network distance, plus route geometry,
-- between centreline intersections within 1000m straight-line.
-- ============================================================

DROP TABLE IF EXISTS whalabi.centreline_network_distance;

CREATE TABLE whalabi.centreline_network_distance (
    from_node integer NOT NULL,
    to_node integer NOT NULL,
    distance_m smallint NOT NULL,
    network_distance_m smallint,
    geom geometry,
    PRIMARY KEY (from_node, to_node)
);

COMMENT ON TABLE whalabi.centreline_network_distance IS
'distance_m: straight-line, always populated. network_distance_m and geom: real routed
distance/path via pgr_dijkstra, null until step 2 runs, do not treat null as 0 or as
distance_m. Symmetric (one row per unordered pair) though the network is directed, so a
real A-to-B and B-to-A distance can differ from what is stored here.';

-- ------------------------------------------------------------
-- Step 1: every pair within 1000m, straight-line distance.
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- Step 2: real routed distance + path per pair. Grouped by
-- from_node so each pgr_dijkstra call only targets its own
-- nearby candidates. Resumable via "where network_distance_m is
-- null". LEFT JOIN + no edge filter: agg_cost must be maxed over
-- all rows (including edge = -1) since that row holds the true
-- final total; filtering it out before aggregating undercounts.
-- ------------------------------------------------------------
WITH sources AS (
    SELECT
        from_node,
        array_agg(to_node) AS target_ids
    FROM whalabi.centreline_network_distance
    WHERE network_distance_m IS NULL
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
        max(p.agg_cost) AS network_distance_m,
        st_union(
            st_linemerge(e.geom)
            ORDER BY p.path_seq
        ) AS geom
    FROM paths AS p
    LEFT JOIN gis_core.routing_centreline_directional AS e ON p.edge = e.id
    GROUP BY p.start_vid, p.end_vid
)

UPDATE whalabi.centreline_network_distance d
SET
    network_distance_m = round(a.network_distance_m)::smallint,
    geom = a.geom
FROM assembled AS a
WHERE
    d.from_node = a.start_vid
    AND d.to_node = a.end_vid;