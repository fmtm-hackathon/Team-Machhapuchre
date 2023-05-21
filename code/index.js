console.log("file is working");

const { Pool } = require("pg");
const pool = new Pool({
  user: "postgres",
  host: "localhost",
  database: "initialdb",
  password: "laxu",
  port: 5432, // Change the port if necessary
});

pool.connect((err, client, release) => {
  if (err) {
    return console.error("Error acquiring client", err.stack);
  }
  console.log("Connected to PostgreSQL database");

  //   let query = `
  //     WITH clipped_lines AS (
  //   SELECT ST_Collect(ST_Intersection(l.geom, a.geom)) AS clipped_geom
  //   FROM islington_lines l, islington_aoi a
  //   WHERE ST_Intersects(l.geom, a.geom)
  //   GROUP BY a.geom
  // ),
  // clipped_polygons AS (
  //   SELECT ST_AsText(geom) AS geom
  //   FROM islington_polygons
  //   WHERE (ST_Contains((SELECT ST_Union(geom) FROM islington_aoi), geom)
  //      OR ST_Touches((SELECT ST_Boundary(geom) FROM islington_aoi), geom)
  //      OR (ST_Area(ST_Intersection(geom, (SELECT ST_Union(geom) FROM islington_aoi))) / ST_Area(geom)) >= 0.5)
  //      AND (tags->>'leisure' IS NULL OR tags->>'leisure' NOT IN ('park', 'swimming_pool','playground', 'common', 'pitch', 'garden','sports_centre'))
  //      AND (tags->>'landuse' IS NULL OR tags->>'landuse' NOT IN ('grass', 'military','meadow', 'farmyard', 'greenfield', 'forest','greenhouse_hoticulture','recreation_ground'))
  //      AND (tags->>'highway' IS NULL OR tags->>'highway' NOT IN ('path','footway' ))
  //      AND (tags->>'parking' IS NULL OR tags->>'parking' NOT IN ('surface' ))
  //      AND (tags->>'traffic_calming' IS NULL OR tags->>'traffic_calming' NOT IN ('island' ))
  //      AND (tags->>'aminity' IS NULL OR tags->>'aminity' NOT IN ('bus_station'))
  //      AND (tags->>'water' IS NULL OR tags->>'water' NOT IN ('river','pond' ))
  //      AND (tags->>'natural' IS NULL OR tags->>'natural' NOT IN ('water','wood','grassland'))
  //      AND (tags->>'surface' IS NULL OR tags->>'surface' != 'grass')
  // )
  // SELECT ST_AsText(ST_Union(boundary.geom, cl.clipped_geom)) AS combined_geom
  // FROM (SELECT ST_Boundary(geom) AS geom FROM islington_aoi) AS boundary
  // CROSS JOIN clipped_lines cl
  // UNION
  // SELECT geom AS combined_geom
  // FROM clipped_polygons`;

  let query = `WITH clipped_lines AS (
  SELECT ST_Collect(ST_Intersection(l.geom, a.geom)) AS clipped_geom
  FROM islington_lines l, islington_aoi a
  WHERE ST_Intersects(l.geom, a.geom)
  GROUP BY a.geom
),
clipped_polygons AS (
  SELECT ST_AsText(geom) AS geom
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
SELECT ST_AsGeoJSON(ST_Union(boundary.geom, cl.clipped_geom)) AS combined_geom
FROM (SELECT ST_Boundary(geom) AS geom FROM islington_aoi) AS boundary
CROSS JOIN clipped_lines cl
UNION
SELECT ST_AsGeoJSON(geom) AS combined_geom
FROM clipped_polygons;
`;

  client.query(query, (err, result) => {
    release();
    if (err) {
      return console.error("Error executing query", err.stack);
    }
    const values = result.rows;
    console.log(result.rows.map((item) => item.combined_geom));
  });
});



SELECT ARRAY_AGG(f.combined_geom) AS building_polygons, p.geom AS polygon_geom, COUNT(f.combined_geom) AS house_count
FROM polygonized_roads p
JOIN filtered_features f ON ST_Within(f.combined_geom, p.geom)
GROUP BY p.geom;
