import os
import requests
import json
from dotenv import load_dotenv

load_dotenv()

# Set your Jellyfin server address and API key here
server_address = "https://jellyfin.alexmickelson.guru"
api_key = os.environ["JELLYFIN_TOKEN"]

# Set the API endpoints to get all songs and create a playlist
songs_endpoint = (
    "/Users/b30951b36b37400498dbfd182d49a42e/Items"
    + "?SortBy=DateCreated,SortName"
    + "&SortOrder=Descending"
    + "&IncludeItemTypes=Audio"
    + "&Recursive=true"
    + "&Fields=AudioInfo,ParentId"
    + "&StartIndex=0"
    + "&ImageTypeLimit=1"
    + "&EnableImageTypes=Primary"
    + "&Limit=100"
    + "&ParentId=7e64e319657a9516ec78490da03edccb"
)
songs_endpoint = "/Users/b30951b36b37400498dbfd182d49a42e/Items"

# Set the parameters for the API request to get all songs
params = {
    "api_key": api_key,
    "SortBy": "SortName",
    "ParentId": "7e64e319657a9516ec78490da03edccb",
}

# Make the API request to get all songs
response = requests.get(server_address + songs_endpoint, params=params)
# Parse the JSON response
data = json.loads(response.text)
# # Loop through the songs and print their names
for song in data["Items"]:
    print(song["Name"], song["Id"])


# Create a list of all song IDs
song_ids = [song["Id"] for song in data["Items"]]
ids = ",".join(song_ids)
# print(ids)
playlist_data = {
    "Name": "All Songs",
    "UserId": "b30951b36b37400498dbfd182d49a42e",
    "Ids": ids,
    "MediaType": "Audio",
}
headers = {"Content-type": "application/json"}
params = {"api_key": api_key}
playlist_endpoint = "/Playlists"
# https://jellyfin.alexmickelson.guru/Playlists?Name=test playlist&Ids=f78ddd409c5ebb2405f5477d15e8e23c&userId=b30951b36b37400498dbfd182d49a42e
response = requests.post(
    server_address + playlist_endpoint,
    headers=headers,
    params=params,
    data=json.dumps(playlist_data),
)
# print(response.text)
playlist_id = response.json()["Id"]




# add_song_url = f"/Playlists/{playlist_id}/Items"
# params = {"api_key": api_key}
# body = {
#     "Ids": ids,
#     "UserId": "b30951b36b37400498dbfd182d49a42e",
#     "MediaType": "Audio",
# }

# response = requests.post(
#     server_address + add_song_url, headers=headers, params=params, json=body
# )
# print(response.text)
# print(response.status_code)
# print(response.headers)

# jellyfin_service.logout()