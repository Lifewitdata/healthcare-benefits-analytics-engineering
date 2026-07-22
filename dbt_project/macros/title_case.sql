{% macro title_case(column_name) %}
    concat(
        upper(substr({{ column_name }}, 1, 1)),
        lower(substr({{ column_name }}, 2, length({{ column_name }})))
    )
{% endmacro %}
