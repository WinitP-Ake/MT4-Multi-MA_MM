//+------------------------------------------------------------------+
//|                                  Trend Following by Multi MA.mq4 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input string _1                  =     "------------General Setting-------------";

input int MagicNumber            =     20201609;
input int Slippage               =     3;
input int TimeDelay              =     1000;

input string _2                  =     "------------Buy Setting-------------";

input double Buy_StopLoss        =     2.0; //Buy_StopLoss (ATR)
input double Buy_TakeProfit      =     5.0; //Buy_TakeProfit (ATR)
input double Buy_Trailing        =     2.0; //Buy_Trailing (ATR)

input string _3                  =     "------------Sell Setting-------------";

input double Sell_StopLoss       =     2.0; //Sell_StopLoss (ATR)
input double Sell_TakeProfit     =     5.0; //Sell_TakeProfit (ATR)
input double Sell_Trailing       =     3.5; //Sell_Trailing (ATR)

input string _4                  =     "------------RSI Setting-------------";

input ENUM_TIMEFRAMES MA_TF      =     PERIOD_H1;
input int MA1_Prd                =     3;
input int MA2_Prd                =     5;
input int MA3_Prd                =     7;
input int MA4_Prd                =     100;
input ENUM_MA_METHOD MA_Method   =     MODE_EMA;
input ENUM_APPLIED_PRICE MA_Price=     PRICE_CLOSE;


input string _5               =     "------------MM Setting-------------";

input bool USE_MM             =     true;
input double Risk             =     2.0;  //%Risk

input double Buy_Lots         =     0.01;
input double Sell_Lots        =     0.01; 

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
int old_bars = 0;
double atr = 0;

void OnTick()
{
   //+------------------------------------------------------------------+
   atr = iATR(Symbol(),MA_TF,10,0);
   //+------------------------------------------------------------------+
   if(old_bars != Bars)
   {
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
   //+------------------------------------------------------------------+
   TrailingStop();
   //+------------------------------------------------------------------+
}
//+------------------------------------------------------------------+
double CalLotSize(double sl, int type)
{
   double lot = 0;
   //+------------------------------------------------------------------+
   if(USE_MM == true)
   {
      double ruin = 0.01*Risk*AccountBalance();
      double loss = (sl/Point())*MarketInfo(Symbol(),MODE_TICKVALUE);
      lot = ruin/loss;   
   }
   else
   {
      if(type == OP_BUY)
      {
         lot = Buy_Lots;
      }
      else if(type ==OP_SELL)
      {
         lot = Sell_Lots;
      }
   }
   //+------------------------------------------------------------------+
   double max_lot = MarketInfo(Symbol(),MODE_MAXLOT);
   double min_lot = MarketInfo(Symbol(),MODE_MINLOT);
   
   if(lot > max_lot)
   {
      lot = max_lot;
   }
   else if(lot < min_lot)
   {
      lot = min_lot;
   }
   
   lot = NormalizeDouble(lot,2);
   //+------------------------------------------------------------------+
   return lot;
}
//+------------------------------------------------------------------+
void OpenBuy()
{
   //+------------------------------------------------------------------+
   double sl=0,tp=0;
   //+------------------------------------------------------------------+
   if(Buy_StopLoss != 0)   sl = Ask - Buy_StopLoss*atr;  
   if(Buy_TakeProfit != 0) tp = Ask + Buy_TakeProfit*atr;
   //+------------------
   //MM
   //+------------------
   //open price = Ask;
   //stop loss = Ask - Buy_StopLoss*atr; 
   //SL Point = (open price - stop loss)/Point();
   //SL Point = (Ask - (Ask - Buy_StopLoss*atr))/Point()
   //SL Point = (Ask - Ask + Buy_StopLss*atr)/Point()
   //Sl Point = (Buy_StopLoss*atr)/Point();
   double lots = CalLotSize(Buy_StopLoss*atr,OP_BUY);
   //+------------------
   int ticket = OrderSend(Symbol(),OP_BUY,lots,Ask,Slippage,sl,tp,"Buy",MagicNumber,0,clrNONE);
   //+------------------------------------------------------------------+
   if(ticket < 0)
   {
      for(int i=1; i<=5; i++)
      {
         Sleep(TimeDelay);
         ticket = OrderSend(Symbol(),OP_BUY,lots,Ask,Slippage,sl,tp,"Buy",MagicNumber,0,clrNONE);
         if(ticket > 0)
         {
            break;
         }
      }
   }
   //+------------------------------------------------------------------+
}
//+------------------------------------------------------------------+
void OpenSell()
{
   //+------------------------------------------------------------------+
   double sl=0,tp=0;
   //+------------------------------------------------------------------+
   if(Sell_StopLoss != 0)   sl = Bid + Sell_StopLoss*atr; 
   if(Sell_TakeProfit != 0) tp = Bid - Sell_TakeProfit*atr;
   //+------------------   
   //MM
   //+------------------
   double lots = CalLotSize(Sell_StopLoss*atr,OP_SELL);
   //+------------------   
   int ticket = OrderSend(Symbol(),OP_SELL,lots,Bid,Slippage,sl,tp,"Sell",MagicNumber,0,clrNONE);
   
   if(ticket < 0)
   {
      for(int i=1; i<=5; i++)
      {
         Sleep(TimeDelay);
         ticket = OrderSend(Symbol(),OP_SELL,lots,Bid,Slippage,sl,tp,"Sell",MagicNumber,0,clrNONE);
         if(ticket > 0)
         {
            break;
         }
      }
   }
   //+------------------------------------------------------------------+
}
//+------------------------------------------------------------------+
int CounrOrderBuy()
{
   int cnt = 0;
   //+------------------------------------------------------------------+
   for(int i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == true)
      {
         if(OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol())
         {
            if(OrderType() == OP_BUY)
            {
               cnt = cnt + 1;
            }
         }
      }
   }
   //+------------------------------------------------------------------+
   return cnt;
}
//+------------------------------------------------------------------+
int CounrOrderSell()
{
   int cnt = 0;
   //+------------------------------------------------------------------+
   for(int i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == true)
      {
         if(OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol())
         {
            if(OrderType() == OP_SELL)
            {
               cnt = cnt + 1;
            }
         }
      }
   }
   //+------------------------------------------------------------------+
   return cnt;
}
//+------------------------------------------------------------------+
int GetSignal()
{
   int sig = 0;
   //+------------------------------------------------------------------+
   double ma1 = iMA(Symbol(),MA_TF,MA1_Prd,0,MA_Method,MA_Price,1);
   double ma2 = iMA(Symbol(),MA_TF,MA2_Prd,0,MA_Method,MA_Price,1);
   double ma3 = iMA(Symbol(),MA_TF,MA3_Prd,0,MA_Method,MA_Price,1);
   double ma4 = iMA(Symbol(),MA_TF,MA4_Prd,0,MA_Method,MA_Price,1);
   //+---------------
   //Buy
   //+---------------
   bool buy1 = (ma1 > ma2) && (ma2 > ma3);
   bool buy2 = Ask > ma4;
   
   if(buy1 && buy2)
   {
      sig = 1;
   }
   //+---------------
   //Sell
   //+---------------
   bool sell1 = (ma1 < ma2) && (ma2 < ma3);
   bool sell2 = Bid < ma4;
   
   if(sell1 && sell2)
   {
      sig = -1;
   }   
   
   //+------------------------------------------------------------------+
   return sig;
}
//+------------------------------------------------------------------+

void TrailingStop()
{
   //+------------------------------------------------------------------+
   for(int i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == true)
      {
         if(OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol())
         {
            //+------------------------------------------------------------------+
            if(OrderType() == OP_BUY)
            {
               if(Bid >= OrderOpenPrice() + Buy_Trailing*atr)
               {
                  if(OrderStopLoss() < Bid - Buy_Trailing*atr)
                  {
                     bool cmdMod = OrderModify(OrderTicket(),OrderOpenPrice(),Bid - Buy_Trailing*atr,OrderTakeProfit(),0,clrNONE);
                  }
               }
            }
            //+------------------------------------------------------------------+
            else if(OrderType() == OP_SELL)
            {
               if(Ask <= OrderOpenPrice() - Sell_Trailing*atr)
               {
                  if((OrderStopLoss() > Ask + Sell_Trailing*atr) || (OrderStopLoss() == 0))
                  {
                     bool cmdMod = OrderModify(OrderTicket(),OrderOpenPrice(),Ask + Sell_Trailing*atr,OrderTakeProfit(),0,clrNONE);
                  }
               }            
            }
            //+------------------------------------------------------------------+
         }
      }   
   }
   //+------------------------------------------------------------------+
}
//+------------------------------------------------------------------+