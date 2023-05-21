SELECT * FROM polygonized_roads;
SELECT * FROM polygonized_roads;
SELECT * FROM filtered_features;
SELECT * FROM house_count_of_poly;

CREATE TABLE house_count_above_10 AS
SELECT *
FROM house_count_of_poly
WHERE house_count >= 10;


SELECT kmeans.*
FROM (
  SELECT ST_ClusterKMeans(polygon_geom, 15) OVER () AS cluster_id, polygon_geom, house_count
  FROM house_count_above_10
) kmeans;


-- CREATE TABLE house_count_of_poly AS
SELECT p.geom AS polygon_geom, COUNT(f.combined_geom) AS house_count, ARRAY_AGG(f.combined_geom) AS building_polygons
FROM polygonized_roads p
JOIN filtered_features f ON ST_Within(f.combined_geom, p.geom)
GROUP BY p.geom;


SELECT ARRAY_AGG(f.combined_geom) AS building_polygons, p.geom AS polygon_geom, COUNT(f.combined_geom) AS house_count
FROM polygonized_roads p
JOIN filtered_features f ON ST_Within(f.combined_geom, p.geom)
GROUP BY p.geom;


CREATE TABLE building_count_with_building_geom AS
SELECT ARRAY_AGG(f.combined_geom) AS building_polygons, p.geom AS polygon_geom, COUNT(f.combined_geom) AS house_count
FROM polygonized_roads p
JOIN filtered_features f ON ST_Within(f.combined_geom, p.geom)
GROUP BY p.geom;

SELECT polygon_geom FROM building_count_with_building_geom;


-- CREATE TABLE house_count_of_poly AS
SELECT p.geom AS polygon_geom, COUNT(f.combined_geom) AS house_count, ARRAY_AGG(f.combined_geom) AS building_polygons
FROM polygonized_roads p
JOIN filtered_features f ON ST_Within(f.combined_geom, p.geom)
GROUP BY p.geom;

-- //////////


CREATE TABLE building_count_with_building_geom AS
SELECT ARRAY_AGG(f.combined_geom) AS building_polygons, p.geom AS polygon_geom, COUNT(f.combined_geom) AS house_count
FROM polygonized_roads p
JOIN filtered_features f ON ST_Within(f.combined_geom, p.geom)
GROUP BY p.geom;



CREATE TABLE clusters (
  cluster_id SERIAL PRIMARY KEY,
  cluster_geom geometry(Polygon)
);


INSERT INTO clusters (cluster_geom)
SELECT (ST_ClusterDBSCAN(building_polygons, eps := 0.001, minpoints := 2)).geom
FROM (
  SELECT ST_Collect(building_geom) AS building_polygons
  FROM building_count_with_building_geom
  WHERE house_count > 10
) sub;


