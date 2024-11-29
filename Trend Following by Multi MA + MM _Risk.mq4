//+------------------------------------------------------------------+
//|                                  Trend Following by Multi MA.mq4 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

// General settings for the expert advisor
input string _1                  =     "------------General Setting-------------";

input int MagicNumber            =     20201609; // Unique identifier for orders
input int Slippage               =     3;        // Maximum slippage allowed for orders
input int TimeDelay              =     1000;     // Delay in milliseconds for retrying failed orders

// Buy order settings
input string _2                  =     "------------Buy Setting-------------";

input double Buy_StopLoss        =     2.0; // Stop loss for buy orders (in ATR multiples)
input double Buy_TakeProfit      =     5.0; // Take profit for buy orders (in ATR multiples)
input double Buy_Trailing        =     2.0; // Trailing stop for buy orders (in ATR multiples)

// Sell order settings
input string _3                  =     "------------Sell Setting-------------";

input double Sell_StopLoss       =     2.0; // Stop loss for sell orders (in ATR multiples)
input double Sell_TakeProfit      =     5.0; // Take profit for sell orders (in ATR multiples)
input double Sell_Trailing       =     3.5; // Trailing stop for sell orders (in ATR multiples)

// Moving Average settings
input string _4                  =     "------------RSI Setting-------------";

input ENUM_TIMEFRAMES MA_TF      =     PERIOD_H1;  // Timeframe for moving averages
input int MA1_Prd                =     3;         // Period for MA1
input int MA2_Prd                =     5;         // Period for MA2
input int MA3_Prd                =     7;         // Period for MA3
input int MA4_Prd                =     100;       // Period for MA4
input ENUM_MA_METHOD MA_Method   =     MODE_EMA;  // Method for calculating MAs
input ENUM_APPLIED_PRICE MA_Price=     PRICE_CLOSE; // Price type for MAs

// Money management settings
input string _5               =     "------------MM Setting-------------";

input bool USE_MM             =     true;       // Enable/disable money management
input double Risk             =     2.0;        // Risk percentage per trade

input double Buy_Lots         =     0.01;       // Fixed lot size for buy orders
input double Sell_Lots        =     0.01;       // Fixed lot size for sell orders

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Initialization logic
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // Cleanup logic
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
int old_bars = 0;   // Tracks the number of bars for processing new ones
double atr = 0;     // Average True Range (ATR) value

void OnTick()
{
   // Calculate ATR
   atr = iATR(Symbol(),MA_TF,10,0);
   
   // Process new bars
   if(old_bars != Bars)
   {
      // Check for buy or sell signals and open trades if conditions are met
      if(GetSignal() == 1 && CounrOrderBuy() == 0)
      {
         OpenBuy();
      }
      else if(GetSignal() == -1 && CounrOrderSell() == 0)
      {
         OpenSell();
      }
      old_bars = Bars;
   }
   
   // Apply trailing stop logic
   TrailingStop();
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk or fixed values                 |
//+------------------------------------------------------------------+
double CalLotSize(double sl, int type)
{
   double lot = 0;
   
   // If money management is enabled, calculate lot size based on risk
   if(USE_MM == true)
   {
      double ruin = 0.01 * Risk * AccountBalance(); // Risk amount
      double loss = (sl / Point()) * MarketInfo(Symbol(),MODE_TICKVALUE); // Potential loss
      lot = ruin / loss;
   }
   else
   {
      // Use fixed lot size for buy or sell orders
      lot = (type == OP_BUY) ? Buy_Lots : Sell_Lots;
   }
   
   // Ensure lot size is within allowable limits
   double max_lot = MarketInfo(Symbol(),MODE_MAXLOT);
   double min_lot = MarketInfo(Symbol(),MODE_MINLOT);
   lot = MathMin(MathMax(lot, min_lot), max_lot);
   return NormalizeDouble(lot, 2);
}

//+------------------------------------------------------------------+
//| Open a buy order                                                 |
//+------------------------------------------------------------------+
void OpenBuy()
{
   double sl = Ask - Buy_StopLoss * atr; // Calculate stop loss
   double tp = Ask + Buy_TakeProfit * atr; // Calculate take profit
   double lots = CalLotSize(Buy_StopLoss * atr, OP_BUY); // Calculate lot size

   int ticket = OrderSend(Symbol(), OP_BUY, lots, Ask, Slippage, sl, tp, "Buy", MagicNumber, 0, clrNONE);
   
   // Retry if the order fails
   for(int i=1; i<=5 && ticket < 0; i++)
   {
      Sleep(TimeDelay);
      ticket = OrderSend(Symbol(), OP_BUY, lots, Ask, Slippage, sl, tp, "Buy", MagicNumber, 0, clrNONE);
   }
}

//+------------------------------------------------------------------+
//| Open a sell order                                                |
//+------------------------------------------------------------------+
void OpenSell()
{
   double sl = Bid + Sell_StopLoss * atr; // Calculate stop loss
   double tp = Bid - Sell_TakeProfit * atr; // Calculate take profit
   double lots = CalLotSize(Sell_StopLoss * atr, OP_SELL); // Calculate lot size

   int ticket = OrderSend(Symbol(), OP_SELL, lots, Bid, Slippage, sl, tp, "Sell", MagicNumber, 0, clrNONE);
   
   // Retry if the order fails
   for(int i=1; i<=5 && ticket < 0; i++)
   {
      Sleep(TimeDelay);
      ticket = OrderSend(Symbol(), OP_SELL, lots, Bid, Slippage, sl, tp, "Sell", MagicNumber, 0, clrNONE);
   }
}

//+------------------------------------------------------------------+
//| Count the number of active buy orders                           |
//+------------------------------------------------------------------+
int CounrOrderBuy()
{
   int cnt = 0;
   for(int i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol() && OrderType() == OP_BUY)
      {
         cnt++;
      }
   }
   return cnt;
}

//+------------------------------------------------------------------+
//| Count the number of active sell orders                          |
//+------------------------------------------------------------------+
int CounrOrderSell()
{
   int cnt = 0;
   for(int i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol() && OrderType() == OP_SELL)
      {
         cnt++;
      }
   }
   return cnt;
}

//+------------------------------------------------------------------+
//| Generate trade signal based on moving averages                  |
//+------------------------------------------------------------------+
int GetSignal()
{
   double ma1 = iMA(Symbol(),MA_TF,MA1_Prd,0,MA_Method,MA_Price,1);
   double ma2 = iMA(Symbol(),MA_TF,MA2_Prd,0,MA_Method,MA_Price,1);
   double ma3 = iMA(Symbol(),MA_TF,MA3_Prd,0,MA_Method,MA_Price,1);
   double ma4 = iMA(Symbol(),MA_TF,MA4_Prd,0,MA_Method,MA_Price,1);

   // Check for buy conditions
   if((ma1 > ma2) && (ma2 > ma3) && Ask > ma4)
      return 1;

   // Check for sell conditions
   if((ma1 < ma2) && (ma2 < ma3) && Bid < ma4)
      return -1;

   return 0; // No signal
}

//+------------------------------------------------------------------+
//| Apply trailing stop logic                                       |
//+------------------------------------------------------------------+
void TrailingStop()
{
   for(int i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol())
      {
         if(OrderType() == OP_BUY && Bid >= OrderOpenPrice() + Buy_Trailing * atr && OrderStopLoss() < Bid - Buy_Trailing * atr)
         {
            OrderModify(OrderTicket(), OrderOpenPrice(), Bid - Buy_Trailing * atr, OrderTakeProfit(), 0, clrNONE);
         }
         else if(OrderType() == OP_SELL && Ask <= OrderOpenPrice() - Sell_Trailing * atr && OrderStopLoss() > Ask + Sell_Trailing * atr)
         {
            OrderModify(OrderTicket(), OrderOpenPrice(), Ask + Sell_Trailing * atr, OrderTakeProfit(), 0, clrNONE);
         }
      }
   }
}
