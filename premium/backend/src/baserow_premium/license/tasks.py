from datetime import timedelta

from django.db import transaction

from baserow.config.celery import app


@app.task(bind=True, queue="export")
def license_check(self):
    """
    Disabled periodic task for checking licenses.
    """

    return



# noinspection PyUnusedLocal
@app.on_after_finalize.connect
def setup_periodic_tasks(sender, **kwargs):
    sender.add_periodic_task(timedelta(hours=1), license_check.s())
