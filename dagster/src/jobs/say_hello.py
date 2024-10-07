from dagster import job

from src.ops.hello import hello


@job
def say_hello_job():
    """
    A job definition. This example job has a single op.

    See our documentation overview on Jobs:
    https://docs.dagster.io/concepts/ops-jobs-graphs/jobs-graphs
    """
    hello()
