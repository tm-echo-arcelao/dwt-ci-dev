from dagster import repository, Definitions

from src.jobs.cereals import cereal_insights
from src.jobs.say_hello import say_hello_job
from src.schedules.my_hourly_schedule import my_hourly_schedule
from src.sensors.my_sensor import my_sensor
from src.assets.cereals_assets import (
    cereals,
    highest_calorie_cereal,
    highest_protein_cereal,
    results
)


defs = Definitions(
    assets=[
        cereals,
        highest_calorie_cereal,
        highest_protein_cereal,
        results
    ],
    jobs=[
        say_hello_job,
        cereal_insights,
    ],
    schedules=[
        my_hourly_schedule,
    ],
    sensors=[
        my_sensor,
    ],
)
