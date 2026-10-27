{#
  Por defecto dbt arma el nombre del schema como "<schema del profile>_<schema custom>"
  (por ejemplo public_staging). Con esta macro el schema queda tal cual:
  staging, normalizado, intermedio, consultas.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
