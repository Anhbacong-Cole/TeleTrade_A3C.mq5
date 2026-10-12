# TeleTrade_A3C.mq5

An automated MetaTrader 5 (MT5) Expert Advisor bridging the trading platform with **Telegram Bot API**. Enables real-time position monitoring, dynamic pending order parsing via chat commands, and low-latency risk management.

---

## 📌 Key Features

- **Two-Factor Access & Security (AllowList Auth):**
  - Granular access filtering via `chat_id`, `from_id`, and `from_username`.
  - Automated unauthorized access rejection with randomized dynamic warning responses.
- **Dynamic Command & Token Parser:**
  - Case-insensitive message tokenization (`BUY`, `SELL`, `ENTRY`, `SL`, `TP`).
  - Flexible risk parameter configuration supporting fixed cash amount (`RISKU`) and balance percentage (`RISKP`).
- **Automated Risk Management Execution:**
  - **Volume-Weighted Break-Even (BE):** Automatically calculates volume-weighted average entry prices for multi-position clusters and moves Stop Loss to safety margins compliant with broker stop levels (`SYMBOL_TRADE_STOPS_LEVEL`).
  - **Emergency Liquidation:** Async bulk position closure (`/close`) and pending order purge (`/clear`, `/delete`) using `SetAsyncMode(true)` for minimal latency.
- **Interactive Visual Monitoring:**
  - Real-time chart and account dashboard snapshot generation (`/screenshot`) pushed directly to Telegram.
  - Interactive bot command suite (`/info`, `/info2`, `/help`, `/be`, `/close`).

---

## 🛠 Tech Stack

- **Language:** MQL5 (MetaQuotes Language 5)
- **Platform:** MetaTrader 5 (MT5)
- **Architecture:** Asynchronous Order Execution, Event-Driven Timer (`OnTimer`), String Tokenization, Dynamic Array Buffers.
- **External Integration:** Telegram Bot API (`TelegramLite.mqh`)

---

## 📖 Message Syntax Examples

```text
# Fixed USD Risk:
BUY 2450.0 SL 2435.0 TP 2470.0 OFFSET 50 RISKU 100

# Percentage Risk (%):
BUY 2450.0 SL 2435.0 TP 2470.0 RISKP 2.5

# Basic Order:
SELL 2465.0 SL 2480.0


Quick Controls:

/be : Move Stop Loss to volume-weighted break-even point.

/close : Close all active positions immediately.

/screenshot : Capture chart view and send image to chat.

/delete : Interactive pending order deletion by index.

⚠️ Disclaimer
Built for system automation research and execution logic testing. Configure inp_tele_token and inp_tele_chat_id in a demo environment prior to live deployment.
