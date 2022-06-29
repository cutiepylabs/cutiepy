import time

import cutiepy

registry = cutiepy.Registry(broker_url="http://localhost:4000")


@registry.job
def fast():
    time.sleep(0.1)


@registry.job
def slow():
    time.sleep(1)


@registry.job
def fail():
    raise RuntimeError("Oppsie woopsies.")


if __name__ == "__main__":
    job_id = fast.enqueue()
    print(f"Enqueued a `fast` job with ID {job_id}")
    job_id = slow.enqueue()
    print(f"Enqueued a `slow` job with ID {job_id}")
    job_id = fail.enqueue()
    print(f"Enqueued a `fail` job with ID {job_id}")
