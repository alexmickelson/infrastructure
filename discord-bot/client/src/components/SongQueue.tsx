import { useWebSocket } from "../contexts/useWebSocket";
import classes from "./SongQueue.module.scss";

export const SongQueue = () => {
  const { songQueue, sendMessage } = useWebSocket();

  return (
    <div>
      {songQueue && (
        <div>
          <ul className="list-group">
            {songQueue.song_file_list.map((s, i) => {
              const isCurrent = i === songQueue.position;
              return (
                <li
                  key={i}
                  className={` list-group-item m-0 p-0 ${
                    isCurrent && "bg-primary-subtle"
                  } ${classes.songListItem}`}
                >
                  <div className="row h-100">
                    <div className="col-1 text-end my-auto">
                      {!isCurrent && (
                        <i
                          className="bi bi-play-circle text-primary fs-3 "
                          role="button"
                          onClick={() => {
                            sendMessage({
                              action: "set_position",
                              position: i,
                            });
                          }}
                        ></i>
                      )}
                      {isCurrent && (
                        <i
                          className="bi bi-pause-circle text-primary fs-3 "
                          role="button"
                          onClick={() => {
                            // send pause message
                            // sendMessage({
                            //   action: "set_position",
                            //   position: i,
                            // });
                          }}
                        ></i>
                      )}
                    </div>
                    <div className="col my-auto">
                      {s.filename
                        .substring(s.filename.lastIndexOf("/") + 1)
                        .replace(".mp3", "")}
                    </div>
                  </div>
                </li>
              );
            })}
          </ul>
        </div>
      )}
    </div>
  );
};
