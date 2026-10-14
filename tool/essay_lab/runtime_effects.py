"""I/O drivers for the single existing Worker state machine; no evaluator fork."""
import inspect


def callback(worker, name):
    if name == 'transport':
        return lambda request, timeout: worker.transport(request, timeout=timeout)
    return worker.provider.evaluate if name == 'provider.evaluate' else getattr(worker, name)


def drive_sync(steps, worker):
    value = None
    error = None
    while True:
        try:
            name, args = steps.throw(error) if error is not None else steps.send(value)
        except StopIteration as done:
            return done.value
        error = None
        try:
            value = callback(worker, name)(*args)
        except Exception as exc:
            error = exc


async def drive_async(steps, worker):
    value = None
    error = None
    while True:
        try:
            name, args = steps.throw(error) if error is not None else steps.send(value)
        except StopIteration as done:
            return done.value
        error = None
        try:
            value = callback(worker, name)(*args)
            if inspect.isawaitable(value):
                value = await value
        except Exception as exc:
            error = exc
