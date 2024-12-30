from typing import List

from pydantic import BaseModel
import yt_dlp

from src.models import SongItem, SongQueueStatus


song_file_list: List[SongItem] = []
current_position = -1
current_song_start_time = 0


def __download_url(url: str):
    fileName = ""

    def yt_dlp_monitor(d):
        nonlocal fileName
        final_filename = d.get("info_dict").get("_filename")
        fileName = final_filename

    ydl_opts = {
        "extract_audio": True,
        "format": "bestaudio/best",
        "outtmpl": "./songs/%(title)s.mp3",
        "progress_hooks": [yt_dlp_monitor],
    }
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        res = ydl.extract_info(url)
        song_duration = res["duration"]
    return fileName, song_duration


def add_to_queue(url: str):
    global current_song_start_time, song_file_list, current_position
    filename, duration = __download_url(url)
    song = SongItem(filename=filename, duration=duration)
    song_file_list.append(song)


def has_current_song():
    global current_song_start_time, song_file_list, current_position
    if not song_file_list:
        return False
    if len(song_file_list) == current_position:
        return False
    if current_position == -1:
        return False
    return True


def get_current_metadata():
    global current_song_start_time, song_file_list, current_position
    if not has_current_song():
        print("cannot request metadata when no current song")
        return None

    return (
        song_file_list[current_position].filename,
        song_file_list[current_position].duration,
        current_song_start_time,
    )


def set_current_song_start_time(start_time: float):
    global current_song_start_time, song_file_list, current_position
    current_song_start_time = start_time


def handle_song_end():
    global current_song_start_time, song_file_list, current_position
    print("handling song end ", current_position, len(song_file_list))
    if current_position == -1:
        return
    if current_position == (len(song_file_list) - 1):
        print("last song ended, reseting position")
        current_position = -1
        return
    print("song ended, moving to next song")
    current_position += 1


def move_to_last_song_in_queue():
    global current_song_start_time, song_file_list, current_position
    current_position = len(song_file_list) - 1


def get_queue_status():
    global current_song_start_time, song_file_list, current_position
    return SongQueueStatus(song_file_list=song_file_list, position=current_position)


def set_queue_position(position: int):
    global current_song_start_time, song_file_list, current_position
    current_position = position
