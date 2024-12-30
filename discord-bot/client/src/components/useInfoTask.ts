import { useEffect } from "react";

const updateInterval = 100;

const getPlaybackInfo = (ws: WebSocket) => {
  ws.send(JSON.stringify({ action: "get_playback_info" }));
};
export const useInfoTask = (websocket?: WebSocket) => {
  useEffect(() => {
    const interval = setInterval(() => {
      if(websocket)
        getPlaybackInfo(websocket);
    }, updateInterval);

    return () => clearInterval(interval);
  }, [websocket]);
};
