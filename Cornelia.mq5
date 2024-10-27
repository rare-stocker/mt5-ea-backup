//+------------------------------------------------------------------+
//|                                                     Cornelia.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

input ENUM_TIMEFRAMES default_timeframe=PERIOD_M1;
MqlRates candle[];
input int lookback=2;
input int shifting=0;
string	default_symbol=Symbol();
input double trailingDistance=0.0;

input double volume_limit=0.10;
input int position_limit=1;

CTrade trade;
CPositionInfo positionInfo;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Print("Welcome!");
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Print("Bye");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
   {
   
   CopyRates(default_symbol, default_timeframe, shifting, lookback, candle);
   
   bool buyAt=candle[0].open < hlc3(0);// || candle[1].open < hlc3(0));
   bool sellAt=candle[0].open > hlc3(0);// || candle[1].open > hlc3(0));
   
   bool buySignal=buyAt && isGreen() && candle[0].open > candle[0].low;
   bool sellSignal=sellAt && !isGreen() && candle[0].open <candle[0].high;
   
   if(buySignal && PositionsTotal() < position_limit){
      double ask=SymbolInfoDouble(default_symbol, SYMBOL_ASK);
      trade.Buy(volume_limit, default_symbol, ask);
   }else if(sellSignal && PositionsTotal() < position_limit){
      double bid=SymbolInfoDouble(default_symbol, SYMBOL_BID);
      trade.Sell(volume_limit, default_symbol, bid);
   }
   
   // Positions handling
    for(int i=0; i < PositionsTotal(); i++) {
        if(PositionGetSymbol(i) == Symbol()) {
            ulong ticket = PositionGetTicket(i);
            int magic = (int)PositionGetInteger(POSITION_MAGIC);
            //printf(IntegerToString(magic));
            if(positionInfo.SelectByTicket(ticket)) {

                SymbolSelect(positionInfo.Symbol(), true);

                double ask = SymbolInfoDouble(positionInfo.Symbol(), SYMBOL_ASK);
                double bid = SymbolInfoDouble(positionInfo.Symbol(), SYMBOL_BID);

                int stopLevel = (int)SymbolInfoInteger(positionInfo.Symbol(), SYMBOL_TRADE_STOPS_LEVEL);
                int spread = (int)SymbolInfoInteger(positionInfo.Symbol(), SYMBOL_SPREAD);
                int digits = (int)SymbolInfoInteger(positionInfo.Symbol(), SYMBOL_DIGITS);

                double point = SymbolInfoDouble(positionInfo.Symbol(), SYMBOL_POINT);

                double contractSize = SymbolInfoDouble(positionInfo.Symbol(), SYMBOL_TRADE_CONTRACT_SIZE);
                double tickSize = SymbolInfoDouble(positionInfo.Symbol(), SYMBOL_TRADE_TICK_SIZE);
                // if there is buy positions.
                if(positionInfo.PositionType() == POSITION_TYPE_BUY) {

                    double	tp = ask + 0.0 * point;
                    tp = NormalizeDouble(tp + (stopLevel + spread) * point, digits);

                    double sl = bid - 0.0 * point;
                    sl = NormalizeDouble(sl - (stopLevel + spread) * point, digits);

                    if(positionInfo.StopLoss() < sl || !positionInfo.StopLoss()) {
                    	//return;
                        trade.PositionModify(positionInfo.Ticket(), sl, positionInfo.TakeProfit());
                    }
                    // else if there is sell positions.
                } else if(positionInfo.PositionType() == POSITION_TYPE_SELL) {

                    double	tp = bid - 0.0 * point;
                    tp = NormalizeDouble(tp - (stopLevel + spread) * point, digits);

                    double sl = ask + 0.0 * point;
                    sl = NormalizeDouble(sl + (stopLevel + spread) * point, digits);

                    if(positionInfo.StopLoss() > sl || !positionInfo.StopLoss()) {
                    	//return;
                        trade.PositionModify(positionInfo.Ticket(), sl, positionInfo.TakeProfit());
                    }
                }
            }
        }

    }

    //Comment("\nStopLevel: ", stopLevel, "\nSpread: ", spread, "\nContractSize: ", contractSize, "\nTickSize: ",tickSize, "\nPoint: ", point, "\nInfo: ", getInfo(_Symbol), "\nComment: ",getRandomComment());

}
//+------------------------------------------------------------------+

double hlc3(int shift){
   return (candle[shift].high + candle[shift].low + candle[shift].close) / 3;
}

bool isGreen(){
   return candle[0].close > candle[0].open;
}