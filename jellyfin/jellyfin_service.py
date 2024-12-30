from functools import lru_cache
import os
from pprint import pprint
from typing import List, Optional
from pydantic import BaseModel, Field

import requests
from dotenv import load_dotenv

load_dotenv()


server_address = "https://jellyfin.alexmickelson.guru"
# api_key = os.environ["JELLYFIN_TOKEN"]
username = os.environ["JELLYFIN_USER"]
password = os.environ["JELLYFIN_PASSWORD"]
alex_user_id = "b30951b36b37400498dbfd182d49a42e"
all_songs_playlist_id = "2e176c02e7cc7f460c40bb1510723510"
unindexed_playlist_id = "2f191b23f0a49e70d6f90e9d82e408c6"


class Song(BaseModel):
    Id: str
    Name: str
    Album: Optional[str] = Field(default=None)
    Artists: Optional[List[str]] = Field(default=None)


class PlaylistSong(BaseModel):
    Id: str
    PlaylistItemId: str
    Name: str
    Album: Optional[str] = Field(default=None)
    Artists: Optional[List[str]] = Field(default=None)


class Playlist(BaseModel):
    Id: str
    Name: str
    Songs: List[PlaylistSong]


@lru_cache(maxsize=10)
def get_token():
    auth_endpoint = f"{server_address}/Users/AuthenticateByName"
    body = {"Username": username, "Pw": password}
    response = requests.post(
        auth_endpoint,
        json=body,
        headers={
            "Content-Type": "application/json",
            "Authorization": 'MediaBrowser Client="scriptclient", Device="script", DeviceId="testscriptasdfasdfasdf", Version="1.0.0", Token=""',
        },
    )
    return response.json()["AccessToken"]


def get_auth_headers():
    token = get_token()
    return {
        "Authorization": f'MediaBrowser Client="scriptclient", Device="script", DeviceId="asdfasdfasdfasdfasdf", Version="1.0.0", Token="{token}"'
    }


def get_all_songs():
    songs_endpoint = (
        f"{server_address}/Users/{alex_user_id}/Items"
        # + "?SortBy=DateCreated,SortName"
        # + "&SortOrder=Descending"
        + "?IncludeItemTypes=Audio"
        + "&Recursive=true"
        # + "&Fields=AudioInfo,ParentId"
        # + "&StartIndex=0"
        # + "&ImageTypeLimit=1"
        # + "&EnableImageTypes=Primary"
        # + "&Limit=100"
        + "&ParentId=7e64e319657a9516ec78490da03edccb"
    )
    params = {
        "SortBy": "SortName",
    }
    response = requests.get(songs_endpoint, params=params, headers=get_auth_headers())
    if not response.ok:
        print(response.status_code)
        print(response.text)
    data = response.json()

    songs = [Song(**song) for song in data["Items"]]
    return songs


def add_song_to_playlist(song_id: str, playlist_id: str):
    add_song_endpoint = f"{server_address}/Playlists/{playlist_id}/Items"
    params = {"ids": song_id, "userId": alex_user_id}
    response = requests.post(
        add_song_endpoint, params=params, headers=get_auth_headers()
    )
    if not response.ok:
        print(response.status_code)
        print(response.text)


def remove_song_from_playlist(song_playlist_id: str, playlist_id: str):
    url = f"{server_address}/Playlists/{playlist_id}/Items"
    params = {
        "EntryIds": song_playlist_id,
        "userId": alex_user_id,
    }  # , "apiKey": api_key}
    response = requests.delete(url, params=params, headers=get_auth_headers())
    if not response.ok:
        print(response.status_code)
        print(response.text)
        print(response.url)
        print(song_playlist_id)
        print(playlist_id)
        print(response.content)
        pprint(response.request.headers)


def get_songs_in_playlist(playlist_id: str):
    url = f"{server_address}/Playlists/{playlist_id}/Items"
    params = {"userId": alex_user_id}
    response = requests.get(url, params=params, headers=get_auth_headers())
    if not response.ok:
        print(response.status_code)
        print(response.text)
        raise Exception(f"Error getting songs in playlist: {playlist_id}")
    data = response.json()

    songs = [PlaylistSong.parse_obj(song) for song in data["Items"]]
    return songs


def get_all_playlists():
    url = f"{server_address}/Users/{alex_user_id}/Items"
    params = {
        "IncludeItemTypes": "Playlist",
        "Recursive": True,
        "ParentId": "29772619d609592f4cdb3fc34a6ec97d",
    }
    response = requests.get(url, params=params, headers=get_auth_headers())
    if not response.ok:
        print(response.status_code)
        print(response.text)
        raise Exception("Error getting all playlists")

    data = response.json()
    print("got all playlists", len(data["Items"]))
    playlists: List[Playlist] = []
    for playlist in data["Items"]:
        songs = get_songs_in_playlist(playlist["Id"])
        playlist_object = Playlist(
            Id=playlist["Id"], Name=playlist["Name"], Songs=songs
        )
        playlists.append(playlist_object)

    return playlists


def logout():
    url = f"{server_address}/Sessions/Logout"
    response = requests.post(url, headers=get_auth_headers())
    print("ending session: " + str(response.status_code))
