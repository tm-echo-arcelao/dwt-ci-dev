from dagster import job

from src.ops.cereals import (
    display_results,
    find_highest_calorie_cereal,
    find_highest_protein_cereal,
    retrieve_cereals,
)


@job
def cereal_insights():
    cereals = retrieve_cereals()
    display_results(
        most_calories=find_highest_calorie_cereal(cereals),
        most_protein=find_highest_protein_cereal(cereals),
    )
