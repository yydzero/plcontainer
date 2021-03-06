-- Creating PL/Container trusted language

CREATE OR REPLACE FUNCTION plcontainer_call_handler()
RETURNS LANGUAGE_HANDLER
AS '$libdir/plcontainer' LANGUAGE C;

CREATE FUNCTION plcontainer_inline_handler(internal)
RETURNS VOID
AS '$libdir/plcontainer' LANGUAGE C STRICT;

CREATE FUNCTION plcontainer_validator(oid)
RETURNS VOID
AS '$libdir/plcontainer' LANGUAGE C STRICT;

CREATE TRUSTED LANGUAGE plcontainer 
HANDLER plcontainer_call_handler
INLINE plcontainer_inline_handler
VALIDATOR plcontainer_validator;

-- Defining container configuration management functions

CREATE OR REPLACE FUNCTION plcontainer_show_local_config() RETURNS text
AS '$libdir/plcontainer', 'show_plcontainer_config'
LANGUAGE C VOLATILE;

CREATE OR REPLACE FUNCTION plcontainer_refresh_local_config(verbose bool) RETURNS text
AS '$libdir/plcontainer', 'refresh_plcontainer_config'
LANGUAGE C VOLATILE;

CREATE TYPE container_summary_type AS ("SEGMENT_ID" text, "CONTAINER_ID" text, "UP_TIME" text, "OWNER" text, "MEMORY_USAGE(KB)" text);

CREATE OR REPLACE VIEW plcontainer_show_config as
    select gp_segment_id, plcontainer_show_local_config()
        from (
            select gp_segment_id
                from gp_dist_random('pg_namespace')
                group by 1
            ) as segments
    union all
    select -1, plcontainer_show_local_config();

CREATE OR REPLACE VIEW plcontainer_refresh_config as
    select gp_segment_id, plcontainer_refresh_local_config(false)
        from (
            select gp_segment_id
                from gp_dist_random('pg_namespace')
                group by 1
            ) as segments
    union all
    select -1, plcontainer_refresh_local_config(false);

CREATE OR REPLACE FUNCTION plcontainer_containers_summary() RETURNS setof container_summary_type
AS '$libdir/plcontainer', 'containers_summary'
LANGUAGE C VOLATILE;