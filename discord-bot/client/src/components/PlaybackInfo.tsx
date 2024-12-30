import React from "react";
import { useInfoTask } from "./useInfoTask";
import { useWebSocket } from "../contexts/useWebSocket";

export const PlaybackInfo: React.FC = () => {
  const { ws, error, message, botStatus } = useWebSocket();

  useInfoTask(ws);

  return (
    <div className="row justify-content-end my-3">
      <div className="col-auto">
        <div className="border rounded-3 p-3 bg-secondary-subtle">
          <h5 className="text-center">Status Messages</h5>
          {botStatus && <div>status: {botStatus}</div>}
          {error && <div>error: {error}</div>}
          {message && <div>message: {message}</div>}
        </div>
      </div>
    </div>
  );
};
