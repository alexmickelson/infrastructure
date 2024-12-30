from jellyfin import jellyfin_service


if __name__ == "__main__":
    all_songs = jellyfin_service.get_all_songs()
    print("total songs", len(all_songs))
    playlist_songs = jellyfin_service.get_songs_in_playlist(
        jellyfin_service.all_songs_playlist_id
    )
    print("songs already in playlist", len(playlist_songs))
    playlist_ids = [s.Id for s in playlist_songs]

    for song in all_songs:
        if song.Id not in playlist_ids:
            print(f"adding song {song.Name} to playlist")
            jellyfin_service.add_song_to_playlist(
                song.Id, jellyfin_service.all_songs_playlist_id
            )

    jellyfin_service.logout()