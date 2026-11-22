"""Bounded transport observations only; never request/response/error contents."""
KINDS = frozenset({'timeout', 'network', 'body_read', 'response_too_large', 'http_status'})
PHASES = frozenset({'request', 'response_body'})
FIELDS = frozenset({'kind', 'phase', 'elapsed_ms', 'deadline_ms', 'http_status'})


def validate_transport_diagnostic(value):
    if type(value) is not dict or set(value) != FIELDS:
        raise ValueError('INVALID_TRANSPORT_DIAGNOSTIC')
    if value['kind'] not in KINDS or value['phase'] not in PHASES:
        raise ValueError('INVALID_TRANSPORT_DIAGNOSTIC')
    for field, maximum in (('elapsed_ms', 86400000), ('deadline_ms', 120000)):
        if type(value[field]) is not int or not (0 <= value[field] <= maximum):
            raise ValueError('INVALID_TRANSPORT_DIAGNOSTIC')
    if not value['deadline_ms']:
        raise ValueError('INVALID_TRANSPORT_DIAGNOSTIC')
    status = value['http_status']
    if status is not None and (type(status) is not int or not 100 <= status <= 599):
        raise ValueError('INVALID_TRANSPORT_DIAGNOSTIC')
    return dict(value)


def attach_transport_diagnostic(error, value):
    error.transport_diagnostic = validate_transport_diagnostic(value)
    return error


class FetchFailure(Exception):
    def __init__(self, diagnostic):
        self.transport_diagnostic = validate_transport_diagnostic(diagnostic)
        super().__init__('FETCH_TRANSPORT_FAILURE')
