SELECT w.*, n.latitude, n.longitude, s.state FROM openstreetmap_public_dataset.planet_ways w
cross join unnest (all_tags) t
cross join unnest (nodes) wn
JOIN openstreetmap_public_dataset.planet_nodes n ON (n.id = wn.id)
CROSS JOIN bigquery-public-data.geo_us_boundaries.states s
WHERE (t.key = "bridge:structure" OR t.key = "bridge:name")
AND (ST_COVEREDBY(ST_GEOGPOINT(n.longitude, n.latitude), s.state_geom))
-- LIMIT 100
