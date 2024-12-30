from pprint import pprint
from jellyfin import jellyfin_service

if __name__ == "__main__":
    all_songs = jellyfin_service.get_all_songs()
    playlists = jellyfin_service.get_all_playlists()
    song_ids_in_playlist = list(
        set(
            song.Id
            for playlist in playlists
            for song in playlist.Songs
            if playlist.Id != jellyfin_service.unindexed_playlist_id
            and playlist.Id != jellyfin_service.all_songs_playlist_id
        )
    )
    unindexed_playlist = next(
        p for p in playlists if p.Id == jellyfin_service.unindexed_playlist_id
    )
    unindexed_songs_ids = [song.Id for song in unindexed_playlist.Songs]
    for song in all_songs:
        if song.Id not in song_ids_in_playlist:
            if song.Id not in unindexed_songs_ids:
                print(f"adding {song.Name} to unindexed playlist")
                jellyfin_service.add_song_to_playlist(
                    song.Id, jellyfin_service.unindexed_playlist_id
                )
    for song in unindexed_playlist.Songs:
        if song.Id in song_ids_in_playlist:
            print(f"removing {song.Name} from unindexed playlist")
            # pprint(song)
            jellyfin_service.remove_song_from_playlist(
                song.PlaylistItemId, jellyfin_service.unindexed_playlist_id
            )
    jellyfin_service.logout()
