WITH clipped_lines AS (
  SELECT ST_Collect(ST_Intersection(l.geom, a.geom)) AS clipped_geom
  FROM islington_lines l, islington_aoi a
  WHERE ST_Intersects(l.geom, a.geom)
  GROUP BY a.geom
),
clipped_polygons AS (
  SELECT geom
  FROM islington_polygons
  WHERE (ST_Contains((SELECT ST_Union(geom) FROM islington_aoi), geom)
     OR ST_Touches((SELECT ST_Boundary(geom) FROM islington_aoi), geom)
     OR (ST_Area(ST_Intersection(geom, (SELECT ST_Union(geom) FROM islington_aoi))) / ST_Area(geom)) >= 0.5)
     AND (tags->>'leisure' IS NULL OR tags->>'leisure' NOT IN ('park', 'swimming_pool','playground', 'common', 'pitch', 'garden','sports_centre'))
	 AND (tags->>'landuse' IS NULL OR tags->>'landuse' NOT IN ('grass', 'military','meadow', 'farmyard', 'greenfield', 'forest','greenhouse_hoticulture','recreation_ground'))
	 AND (tags->>'highway' IS NULL OR tags->>'highway' NOT IN ('path','footway' ))
	 AND (tags->>'parking' IS NULL OR tags->>'parking' NOT IN ('surface' ))
	AND (tags->>'traffic_calming' IS NULL OR tags->>'traffic_calming' NOT IN ('island' ))
	AND (tags->>'aminity' IS NULL OR tags->>'aminity' NOT IN ('bus_station'))
	AND (tags->>'water' IS NULL OR tags->>'water' NOT IN ('river','pond' ))
	AND (tags->>'natural' IS NULL OR tags->>'natural' NOT IN ('water','wood','grassland'))
     AND (tags->>'surface' IS NULL OR tags->>'surface' != 'grass')
)
SELECT ST_Union(boundary.geom, cl.clipped_geom) AS combined_geom
FROM (SELECT ST_Boundary(geom) AS geom FROM islington_aoi) AS boundary
CROSS JOIN clipped_lines cl
UNION
SELECT geom AS combined_geom
FROM clipped_polygons;


SELECT geom
FROM islington_lines
WHERE tags->>'highway' IN ('primary', 'subway', 'motorway');

SELECT ST_Buffer(geom::geography, 1.7) AS polygon_geom
FROM islington_lines
WHERE tags->>'highway' IN ('primary', 'subway', 'motorway');


select geom from islington_aoi;

-- intersection
SELECT ST_Intersection(highways.polygon_geom, aoi.geom) AS intersection_geom
FROM (
    SELECT ST_Buffer(geom::geography, 1.7) AS polygon_geom
    FROM islington_lines
    WHERE tags->>'highway' IN ('primary', 'subway', 'motorway')
) AS highways, islington_aoi AS aoi
WHERE ST_Intersects(highways.polygon_geom, aoi.geom);

-- union
SELECT ST_Union(highways.polygon_geom) AS union_geom
FROM (
    SELECT ST_Buffer(geom::geography, 1.7)::geometry AS polygon_geom
    FROM islington_lines
    WHERE tags->>'highway' IN ('primary', 'subway', 'motorway')
) AS highways, islington_aoi AS aoi
WHERE ST_Intersects(highways.polygon_geom, aoi.geom)
GROUP BY aoi.geom;


SELECT geom FROM islington_lines WHERE tags->>'highway' IN ('primary', 'subway', 'motorway')
UNION
SELECT geom FROM islington_aoi;

SELECT ST_Union(lines.geom) AS union_geom
FROM islington_lines AS lines, islington_aoi AS aoi
WHERE lines.tags->>'highway' IN ('primary', 'subway', 'motorway')
  AND ST_Intersects(lines.geom, aoi.geom)
UNION
SELECT geom FROM islington_aoi;



SELECT ST_Difference(lines.geom, aoi.geom) AS difference_geom
FROM islington_lines AS lines, islington_aoi AS aoi
WHERE lines.tags->>'highway' IN ('primary', 'subway', 'motorway')
  AND ST_Intersects(lines.geom, aoi.geom);
  
--   compliment
SELECT ST_Difference(aoi.geom, lines.geom) AS complement_geom
FROM islington_aoi AS aoi, islington_lines AS lines
WHERE lines.tags->>'highway' IN ('primary', 'subway', 'motorway')
  AND ST_Intersects(lines.geom, aoi.geom);


SELECT (ST_Dump(ST_Polygonize(lines.geom))).geom AS polygon_geom
FROM (
  SELECT ST_Collect(geom) AS geom
  FROM islington_lines
  WHERE tags->>'highway' IN ('primary', 'subway', 'motorway')
) AS lines;


SELECT (ST_Dump(ST_Polygonize(lines.geom))).geom AS polygon_geom
FROM (
  SELECT ST_LineMerge(ST_Collect(geom)) AS geom
  FROM islington_lines
  WHERE tags->>'highway' IN ('primary', 'subway', 'motorway')
) AS lines;


