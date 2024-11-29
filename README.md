# Trend Following by Multi Moving Average with Money Management

## Overview

This MetaTrader 4 (MT4) Expert Advisor (EA) implements a trend-following strategy using multiple moving averages (MA). It calculates buy and sell signals based on the relationship between short-term and long-term moving averages and incorporates money management, trailing stops, and automated order execution.

## Features

1. **General Settings**
   - Configurable magic number, slippage, and execution delay.
2. **Buy/Sell Settings**
   - Adjustable stop loss, take profit, and trailing stop values calculated based on Average True Range (ATR).
3. **Multi-MA Signal Logic**
   - Signals generated using a hierarchy of moving averages:
     - **Buy**: Shorter MAs are above longer MAs, and the price is above the longest MA.
     - **Sell**: Shorter MAs are below longer MAs, and the price is below the longest MA.
4. **Money Management (MM)**
   - Dynamic lot size calculation based on account balance and risk percentage.
   - Fixed lot size option is also available.
5. **Trailing Stop**
   - Adjusts stop loss dynamically based on price movement and ATR.
6. **Order Management**
   - Ensures no duplicate buy/sell orders are placed.
   - Modifies existing orders to apply trailing stops.

## Inputs

### General Settings
- **MagicNumber**: Unique identifier for the EA (Example: 20201609).
- **Slippage**: Maximum price slippage allowed (default: 3).
- **TimeDelay**: Delay between retries for failed orders (default: 1000 ms).

### Buy Settings
- **Buy_StopLoss**: Stop loss distance in ATR (default: 2.0).
- **Buy_TakeProfit**: Take profit distance in ATR (default: 5.0).
- **Buy_Trailing**: Trailing stop distance in ATR (default: 2.0).

### Sell Settings
- **Sell_StopLoss**: Stop loss distance in ATR (default: 2.0).
- **Sell_TakeProfit**: Take profit distance in ATR (default: 5.0).
- **Sell_Trailing**: Trailing stop distance in ATR (default: 3.5).

### Moving Average (MA) Settings
- **MA_TF**: Timeframe for MA calculations (default: H1).
- **MA1_Prd, MA2_Prd, MA3_Prd, MA4_Prd**: Periods for the moving averages (default: 3, 5, 7, and 100, respectively).
- **MA_Method**: Method for MA calculation (default: EMA).
- **MA_Price**: Price applied for MA calculation (default: close price).

### Money Management Settings
- **USE_MM**: Enables dynamic lot size calculation (default: true).
- **Risk**: Percentage of account balance at risk per trade (default: 2.0%).
- **Buy_Lots, Sell_Lots**: Fixed lot sizes for buy and sell orders if MM is disabled (default: 0.01).

## Core Functions

1. **Signal Generation**
   - `GetSignal()` evaluates MA relationships to determine buy (1), sell (-1), or no trade (0).
2. **Order Execution**
   - `OpenBuy()` and `OpenSell()` place buy and sell orders with calculated stop loss and take profit levels.
3. **Money Management**
   - `CalLotSize()` dynamically calculates lot size based on risk percentage and ATR.
4. **Trailing Stop**
   - `TrailingStop()` modifies stop loss levels to secure profits as the market moves favorably.
5. **Order Tracking**
   - `CounrOrderBuy()` and `CounrOrderSell()` count active buy and sell orders for the symbol.

## Requirements

- **Platform**: MetaTrader 4 (MT4).
- **Symbol**: Any trading instrument.
- **Timeframe**: Configurable based on the MA_TF input.

## Usage

1. Load the EA on a chart in MT4.
2. Configure the input parameters as desired.
3. Allow the EA to manage orders based on the defined strategy.

## Disclaimer

This EA is intended for educational purposes. Use at your own risk. Proper backtesting and risk management are recommended before live trading.
