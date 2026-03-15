#!/usr/bin/env python3
"""
Telegram bot that forwards messages to the local LiteLLM proxy.
Prerequisites:
  pip install python-telegram-bot requests
Usage:
  source .env && python telegram_bot.py
"""

import os
import logging
import pathlib
import requests

# Load .env from the same directory as this script
_env_path = pathlib.Path(__file__).parent / ".env"
if _env_path.exists():
    for _line in _env_path.read_text().splitlines():
        _line = _line.strip()
        if _line and not _line.startswith("#") and "=" in _line:
            _key, _, _val = _line.partition("=")
            os.environ.setdefault(_key.strip(), _val.strip())
from telegram import Update
from telegram.ext import ApplicationBuilder, CommandHandler, MessageHandler, ContextTypes, filters

logging.basicConfig(level=logging.INFO)

TELEGRAM_BOT_TOKEN = os.environ["TELEGRAM_BOT_TOKEN"]
LITELLM_MASTER_KEY  = os.environ["LITELLM_MASTER_KEY"]
LITELLM_URL         = os.environ.get("OPENCLAW_API_BASE", "http://localhost:4444") + "/chat/completions"
MODEL               = os.environ.get("MODEL", "gpt-4")


def ask_model(prompt: str) -> str:
    response = requests.post(
        LITELLM_URL,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {LITELLM_MASTER_KEY}",
        },
        json={
            "model": MODEL,
            "messages": [{"role": "user", "content": prompt}],
            "max_tokens": 400,
        },
        timeout=90,
    )
    response.raise_for_status()
    return response.json()["choices"][0]["message"]["content"]


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    await update.message.reply_text(f"Ready. Model: {MODEL}\nProxy: {LITELLM_URL}")


async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    user_text = update.message.text or ""
    try:
        reply = ask_model(user_text)
    except Exception as error:
        reply = f"Error: {error}"
    await update.message.reply_text(reply[:4096])


app = ApplicationBuilder().token(TELEGRAM_BOT_TOKEN).build()
app.add_handler(CommandHandler("start", start))
app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))

if __name__ == "__main__":
    print(f"Bot started — model: {MODEL}, proxy: {LITELLM_URL}")
    app.run_polling()
