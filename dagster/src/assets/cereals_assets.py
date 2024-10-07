import csv
import requests

from dagster import asset, MaterializeResult, MetadataValue


@asset(group_name='cereals_insights_assets')
def cereals():
    """A dataset of cereal nutritional information."""
    response = requests.get("https://docs.dagster.io/assets/cereal.csv")
    lines = response.text.split("\n")
    cereals = [row for row in csv.DictReader(lines)]
    
    return cereals


@asset(group_name='cereals_insights_assets')
def highest_calorie_cereal(cereals):
    """The cereal with the highest calorie count."""
    sorted_cereals = list(sorted(cereals, key=lambda cereal: cereal["calories"]))
    return sorted_cereals[-1]


@asset(group_name='cereals_insights_assets')
def highest_protein_cereal(cereals):
    """The cereal with the highest protein count."""
    sorted_cereals = list(sorted(cereals, key=lambda cereal: cereal["protein"]))
    return sorted_cereals[-1]


@asset(group_name='cereals_insights_assets')
def results(highest_calorie_cereal, highest_protein_cereal):
    """Metadata about the highest calorie and protein cereals."""
    return MaterializeResult(
        metadata={
            "most_caloric_cereal": MetadataValue.md(highest_calorie_cereal["name"]),
            "highest_calorie_count": MetadataValue.md(highest_calorie_cereal["calories"]),
            "most_protein_rich_cereal": MetadataValue.md(highest_protein_cereal["name"]),
            "highest_protein_count": MetadataValue.md(highest_protein_cereal["protein"])
        }
    )
