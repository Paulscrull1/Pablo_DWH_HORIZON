{% macro generate_hashdiff(column_list) %}
    lower(hex(MD5(arrayStringConcat([{{ column_list | join(', ') }}], '|'))))
{% endmacro %}
