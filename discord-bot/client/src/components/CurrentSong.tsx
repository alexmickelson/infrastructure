import { useWebSocket } from "../contexts/useWebSocket";
import { Slider } from "./Slider";

export const CurrentSong = () => {
  const { ws, playbackInfo, sendMessage } = useWebSocket();
  return (
    <>
      {playbackInfo && (
        <div className="rounded border p-3 my-5 bg-body-tertiary bg-opacity-50">
          <h2>Playing Song</h2>
          <h5>{playbackInfo.file_name}</h5>
          {ws && (
            <Slider
              min={0}
              max={playbackInfo.duration}
              current={playbackInfo.current_position}
              onChange={(v) => {
                sendMessage({ action: "set_playback", position: v });
              }}
            />
          )}
        </div>
      )}
    </>
  );
};
