from enum import Enum
from typing import List, Optional
from pydantic import BaseModel


class BotStatus(str, Enum):
    PLAYING = "Playing"
    IDLE = "Idle"


class MessageType(str, Enum):
    PLAYBACK_INFORMATION = "PLAYBACK_INFORMATION"
    ERROR = "ERROR"
    MESSAGE = "MESSAGE"


class SongItem(BaseModel):
    filename: str
    duration: int


class SongQueueStatus(BaseModel):
    song_file_list: list[SongItem]
    position: int


class PlaybackInformation(BaseModel):
    file_name: str
    current_position: float
    duration: float


class BotResponse(BaseModel):
    message_type: MessageType
    status: BotStatus
    error: Optional[str] = None
    message: Optional[str] = None
    playback_information: Optional[PlaybackInformation] = None
    song_queue: Optional[SongQueueStatus] = None
