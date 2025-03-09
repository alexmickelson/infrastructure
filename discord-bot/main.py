import os
from pprint import pprint
from typing import Set
import discord
from discord.ext import commands
from dotenv import load_dotenv
from fastapi.concurrency import asynccontextmanager
from pydantic import BaseModel
import asyncio
import websockets
import json
from src.models import BotResponse
from src.my_voice_client import get_voice_client, set_voice_client
from src.playback_service import (
    handle_message,
    handle_new_song_on_queue,
    pause_song,
)
from src.song_queue import add_to_queue

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

async def websocket_handler(websocket: websockets.WebSocketServerProtocol):
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

@bot.command(name="url")
async def url(ctx: commands.Context):
    await ctx.send("http://server.alexmickelson.guru:5677/")

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

async def start_websocket_server():
    print("Starting WebSocket server...")
    async with websockets.serve(websocket_handler, "0.0.0.0", 5678, ):
        await asyncio.Future()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Start WebSocket and Discord bot in managed background tasks
    websocket_task = asyncio.create_task(start_websocket_server())
    bot_task = asyncio.create_task(bot.start(os.getenv("DISCORD_SECRET")))

    app.state.websocket_task = websocket_task
    app.state.bot_task = bot_task

    yield

    app.state.websocket_task.cancel()
    app.state.bot_task.cancel()
    await asyncio.gather(app.state.websocket_task, app.state.bot_task, return_exceptions=True)

app = FastAPI(lifespan=lifespan)

app.mount("/", StaticFiles(directory="./client", html=True), name="static")