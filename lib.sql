CREATE OR REPLACE FUNCTION simplify (str text) RETURNS text
AS $$
	import unicodedata

	s = str.decode('UTF-8')

	s = s.replace('ß'.decode('UTF-8'), 'ss'.decode('UTF-8'))
	s = s.replace('-'.decode('UTF-8'), ' '.decode('UTF-8'))
	s = ''.join(
		c for c
		in unicodedata.normalize('NFKD', s)
		if unicodedata.combining(c) == 0
	)

	return s.lower().encode('UTF-8')
$$ LANGUAGE plpythonu IMMUTABLE;


CREATE OR REPLACE FUNCTION plainto_tsquery_or (regconfig, text) RETURNS tsquery AS $$
BEGIN

	return to_tsquery('simple',
		replace(replace(
			plainto_tsquery($1, $2)::text
		, '''', ''), ' & ', ' | ')
	);

END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;


CREATE OR REPLACE FUNCTION tsvector2query (tsvector) RETURNS tsquery AS $$
DECLARE
	t text;
BEGIN

	t := regexp_replace(
		''':1A ' || $1::text || ':1A ''',
		E'''.*? ''',
		' ',
		'g'
	);
	return plainto_tsquery_or('simple', t);

END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;


CREATE OR REPLACE FUNCTION text2bigint (text, int) RETURNS bigint AS $$
DECLARE
	t text;
BEGIN
	t := substr(
		regexp_replace($1, '[^0-9]+', '', 'g'),
		1,
		$2
	);
	
	IF char_length(t) > 0 THEN
	
		RETURN t::bigint;
	END IF;
	
	RETURN 0;

END;
$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION strrpos (text, text) RETURNS int AS $$
DECLARE
	i int;
BEGIN

	i := char_length($1) - char_length($2) + 1;
	
	LOOP
		IF strpos(substr($1, i), $2) = 1 THEN
			return i;
		END IF;
		IF i = 0 THEN
			exit;
		END IF;
		i := i - 1;
	END LOOP;
	
	RETURN 0;

END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;