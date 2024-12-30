export enum BotStatus {
  PLAYING = "Playing",
  Idle = "Idle",
}

export interface PlaybackInfoData {
  file_name: string;
  current_position: number;
  duration: number;
}

export interface SongQueue {
  song_file_list: {
    filename: string;
    duration: number;
  }[];
  position: number;
}

export interface BotResponse {
  message_type: "PLAYBACK_INFORMATION" | "ERROR" | "MESSAGE";
  status: BotStatus;
  error?: string;
  message?: string;
  playback_information?: PlaybackInfoData;
  song_queue?: SongQueue;
}