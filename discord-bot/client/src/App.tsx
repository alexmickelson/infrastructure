import { CurrentSong } from "./components/CurrentSong";
import { PlaybackInfo } from "./components/PlaybackInfo";
import { SongQueue } from "./components/SongQueue";

export const App = () => {
  return (
    <div className="container mt-5">
      <h1 className="text-center">Discord Music</h1>
      <CurrentSong />
      <SongQueue />
      <PlaybackInfo />
    </div>
  );
};
