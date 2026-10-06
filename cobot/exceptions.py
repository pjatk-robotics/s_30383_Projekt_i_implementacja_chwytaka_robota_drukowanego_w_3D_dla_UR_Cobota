class CobotError(Exception):
    pass


class CobotConnectionError(CobotError):
    pass


class CobotNotConnectedError(CobotError):
    pass


class InvalidPoseError(CobotError):
    pass