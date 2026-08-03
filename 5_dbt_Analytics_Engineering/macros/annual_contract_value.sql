{#
    Revenue is recognised only on filled vacancies, annualised from the
    monthly fee. This rule appears in several models, so it lives in one
    macro — change the recognition policy here and every mart follows.
#}
{% macro annual_contract_value(monthly_fee_column, is_filled_column) %}
    case
        when {{ is_filled_column }}
        then round({{ monthly_fee_column }} * 12, 2)
        else 0
    end
{% endmacro %}
