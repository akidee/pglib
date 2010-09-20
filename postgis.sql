\i /usr/share/postgresql/8.3/contrib/postgis.sql
\i /usr/share/postgresql/8.3/contrib/spatial_ref_sys.sql


CREATE OR REPLACE FUNCTION ST_Includes (geometry, geometry) RETURNS boolean AS $$
BEGIN
	return 
		ST_Covers($1, $2) 
		AND NOT ST_Equals($1, $2);

END;
$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION ST_EnvelopeNoLineString (geometry) RETURNS geometry AS $$
DECLARE
	env geometry;
	typ text;
BEGIN

	env := ST_Envelope($1);
	typ := GeometryType(env);
	
	IF typ = 'POLYGON' THEN
	
		return env;
	END IF;
	
	IF typ = 'POINT' THEN
	
		return ST_expand(env, .0003);
	END IF;
	
	return ST_MakePolygon(
		ST_AddPoint(
			ST_AddPoint(env, ST_PointN(env, 2)),
			ST_PointN(env, 1)
		)
	);

END;
$$ LANGUAGE 'plpgsql';