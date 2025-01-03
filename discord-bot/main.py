from enum import Enum
import os
from pprint import pprint
from typing import Optional, Set
import discord
from discord.ext import commands
from threading import Thread
from dotenv import load_dotenv
from fastapi.concurrency import asynccontextmanager
from pydantic import BaseModel
import asyncio
import websockets
import json
import time
from src.models import BotResponse, BotStatus, MessageType, PlaybackInformation
from src.my_voice_client import get_voice_client, set_voice_client
from src.playback_service import (
    get_filename_and_starttime,
    get_status,
    handle_message,
    handle_new_song_on_queue,
    pause_song,
    play_current_song,
    start_time_now,
)
from src.song_queue import add_to_queue, get_current_metadata, handle_song_end, has_current_song, move_to_last_song_in_queue

load_dotenv()

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles


bot = commands.Bot(command_prefix="!", intents=discord.Intents.all())
connected_clients: Set[websockets.WebSocketServerProtocol] = set()

async def broadcast_bot_response(response: BotResponse):
    if connected_clients:
        await asyncio.wait(
            [
                asyncio.create_task(client.send(response.model_dump_json()))
                for client in connected_clients
            ]
        )
    else:
        raise TypeError("Passing coroutines is forbidden, use tasks explicitly.")

async def send_response_message(
    websocket: websockets.WebSocketServerProtocol, response: BotResponse
):
    await websocket.send(response.model_dump_json())

async def websocket_handler(websocket: websockets.WebSocketServerProtocol, path: str):
    connected_clients.add(websocket)
    try:
        async for message in websocket:
            data = json.loads(message)
            response = handle_message(data)
            await send_response_message(websocket, response)

    except websockets.ConnectionClosedError as e:
        print(f"Connection closed with error: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")
        raise e
    finally:
        connected_clients.remove(websocket)
        print("WebSocket connection closed")

@bot.event
async def on_ready():
    print("Bot is ready")

@bot.command(name="play", pass_context=True)
async def play(ctx: commands.Context, url: str):
    print("playing", url)
    channel = ctx.message.author.voice.channel

    if ctx.voice_client is None:
        set_voice_client(await channel.connect())
    add_to_queue(url)
    handle_new_song_on_queue()

@bot.command(pass_context=True)
async def stop(ctx: commands.Context):
    voice_client = get_voice_client()
    if voice_client and voice_client.is_playing():
        voice_client.stop()
        await voice_client.disconnect()
        await ctx.send("Stopped playing")

@bot.command(pass_context=True)
async def pause(ctx: commands.Context):
    pause_song()

def run_websocket():
    print("started websocket")
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    start_server = websockets.serve(websocket_handler, "0.0.0.0", 5678)
    loop.run_until_complete(start_server)
    loop.run_forever()



@asynccontextmanager
async def lifespan(app: FastAPI):
    Thread(target=run_websocket).start()
    Thread(target=lambda: bot.run(os.getenv("DISCORD_SECRET"))).start()
    yield

app = FastAPI(lifespan=lifespan)

app.mount("/", StaticFiles(directory="./client", html=True), name="static")