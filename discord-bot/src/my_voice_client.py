from discord import VoiceClient


__voice_client: VoiceClient | None = None


def get_voice_client():
    global __voice_client
    return __voice_client


def set_voice_client(client: VoiceClient | None):
    global __voice_client
    __voice_client = client
