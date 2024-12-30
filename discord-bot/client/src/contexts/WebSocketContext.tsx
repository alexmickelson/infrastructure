import {
  FC,
  ReactNode,
  useEffect,
  useState,
} from "react";
import { BotResponse, PlaybackInfoData, SongQueue } from "../models";
import { WebSocketContext } from "./useWebSocket";

export const WebSocketProvider: FC<{ children: ReactNode }> = ({
  children,
}) => {
  const [ws, setWs] = useState<WebSocket | undefined>();
  const [playbackInfo, setPlaybackInfo] = useState<
    PlaybackInfoData | undefined
  >();
  const [songQueue, setSongQueue] = useState<SongQueue | undefined>();
  const [error, setError] = useState<string>("");
  const [message, setMessage] = useState("");
  const [botStatus, setBotStatus] = useState<string | undefined>();

  useEffect(() => {
    const websocket = new WebSocket(`ws://server.alexmickelson.guru:5678/`);
    // const websocket = new WebSocket(`ws://${window.location.hostname}:5678/`);

    setWs(websocket);

    websocket.onopen = () => {
      console.log("websocket connected");
      websocket.send(JSON.stringify({ action: "get_playback_info" }));
    };

    websocket.onmessage = (event) => {
      const response: BotResponse = JSON.parse(event.data);
      setBotStatus(response.status);
      if (response.message_type === "ERROR") {
        setError(response.error ?? "");
      } else if (response.message_type === "MESSAGE") {
        setMessage(response.message ?? "");
      } else if (response.message_type === "PLAYBACK_INFORMATION") {
        setPlaybackInfo(response.playback_information);
        setSongQueue(response.song_queue);
      }
    };

    websocket.onerror = (event: Event) => {
      console.log(event);
      setError("WebSocket error occurred.");
    };

    websocket.onclose = () => {
      console.log("WebSocket connection closed");
    };

    return () => {
      setWs(undefined);
      websocket.close();
    };
  }, []);

  const sendMessage = (message: unknown) => {
    if (ws) {
      ws.send(JSON.stringify(message));
    }
  };

  return (
    <WebSocketContext.Provider
      value={{
        ws,
        error,
        message,
        botStatus,
        playbackInfo,
        songQueue,
        sendMessage,
      }}
    >
      {children}
    </WebSocketContext.Provider>
  );
};
