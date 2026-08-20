DROP FUNCTION bitem."translation"(int4, _int4);

CREATE OR REPLACE FUNCTION bitem.translation(current_id integer, languages integer[])
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
    return_translation TEXT;
    final_translation  TEXT;
    lan                INT;
    lan_label          TEXT;
    crm_class          TEXT;

BEGIN
    SELECT oa.cidoc_class_code
    FROM model.entity e
        JOIN model.openatlas_class oa ON e.openatlas_class_name = oa.name
    WHERE e.id = current_id INTO crm_class;
    CASE
        WHEN crm_class = 'E55'
            THEN SELECT '{ "name":"' || replace(replace(replace(e.name, '', '\'), '"', '\"'), '{', '\{') ||
                        '", "id": ' || current_id::TEXT
                 FROM model.entity e
                 WHERE e.id = current_id
                 INTO final_translation;

        ELSE SELECT '{ "name":"' || replace(replace(replace(e.name, '', '\'), '"', '\"'), '{', '\{') || '"'::TEXT
             FROM model.entity e
             WHERE e.id = current_id
             INTO final_translation;
        END CASE;
    FOREACH lan IN ARRAY languages
        LOOP

            SELECT null INTO lan_label;
            SELECT null INTO return_translation;
            SELECT description FROM model.entity WHERE id = lan INTO lan_label;
            SELECT replace(replace(replace(l.description, '', '\'), '"', '\"'), '{', '\{')
            FROM model.link l
            WHERE l.domain_id = lan
              AND l.range_id = current_id
            INTO return_translation;

            CASE
                WHEN return_translation IS NOT NULL
                    THEN SELECT final_translation || ',"' || lan_label || '":"' || return_translation || '"'
                         INTO final_translation;

                ELSE SELECT final_translation INTO final_translation;
                END CASE;
        END LOOP;


    SELECT final_translation || '}' INTO final_translation;

    RETURN (SELECT final_translation::JSONB);
END;
$function$
;



DROP FUNCTION bitem.find_root_type(int4, text);

CREATE OR REPLACE FUNCTION bitem.find_root_type(entity_id integer, _property_code text)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    root_id integer;
    class   TEXT;
BEGIN
    SELECT oa.cidoc_class_code
    FROM model.entity e
        JOIN model.openatlas_class oa ON e.openatlas_class_name = oa.name
    WHERE e.id = current_id INTO class;;
    IF _property_code NOT IN ('P2', 'P127') THEN
        -- Return NULL if _property_code is not in the specified values
        RETURN NULL;
    END IF;

    IF _property_code = 'P2' THEN SELECT 'P127' INTO _property_code; END IF;

    -- Check if class is not 'E55' and return NULL
    IF class != 'E55' THEN
        RETURN NULL;
    END IF;

    -- Find the direct parent of the entity_id with the given property code
    SELECT range_id
    INTO root_id
    FROM model.link
    WHERE domain_id = entity_id
      AND property_code = _property_code;

    -- If a direct parent is found, recursively call the function to find its root parent
    IF root_id IS NOT NULL THEN
        RETURN bitem.find_root_type(root_id, _property_code);
    END IF;

    -- If no direct parent is found, return the original entity_id as it is the root
    RETURN entity_id;
END;
$function$
;
