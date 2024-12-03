//+------------------------------------------------------------------+
//|                                                 TrailingMoon.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

CTrade trade;
CPositionInfo positionInfo;

input double trailingDistance=10.0;

void trailingMon(){
    for(int i=0; i<PositionsTotal(); i++){
        if(PositionGetSymbol(i) == Symbol()) {
            ulong ticket = PositionGetTicket(i);
            //ulong magic = (int)PositionGetInteger(POSITION_MAGIC);
            if(positionInfo.SelectByTicket(ticket)) {
            	SymbolSelect(positionInfo.Symbol(), true);
   				double ask=SymbolInfoDouble(positionInfo.Symbol(), SYMBOL_ASK);
   				double bid=SymbolInfoDouble(positionInfo.Symbol(), SYMBOL_BID);
   				double stopLevel=(int)SymbolInfoInteger(positionInfo.Symbol(), SYMBOL_TRADE_STOPS_LEVEL);
   				double spread=(int)SymbolInfoInteger(positionInfo.Symbol(), SYMBOL_SPREAD);
   				int digits=(int)SymbolInfoInteger(positionInfo.Symbol(), SYMBOL_DIGITS);
   				double point=SymbolInfoDouble(positionInfo.Symbol(), SYMBOL_POINT);
   				//double contractSize=SymbolInfoDouble(positionInfo.Symbol(), SYMBOL_TRADE_CONTRACT_SIZE);
   				//double tickSize=SymbolInfoDouble(positionInfo.Symbol(), SYMBOL_TRADE_TICK_SIZE);
		    
                if(positionInfo.PositionType() == POSITION_TYPE_BUY) {

                    //double mintp = NormalizeDouble(ask + (stopLevel + spread) * point, digits);
                    double minsl = NormalizeDouble(bid - (stopLevel + spread) * point, digits);
                    
                    //double	tp = ask + trailingDistance * point;
                    //tp = NormalizeDouble(tp + (stopLevel + spread) * point, digits);
                    
                    double sl = bid - trailingDistance * point;
                    sl = NormalizeDouble(sl - (stopLevel + spread) * point, digits);
                    
                    //printf(tp, sl);
                    
                    if(sl > minsl){
                    	//printf("Buy Position That error!");
						   return ;
					      }

                	if( positionInfo.PriceCurrent() > positionInfo.PriceOpen() && (sl > positionInfo.StopLoss()||!positionInfo.StopLoss()) )
                	{
                     trade.PositionModify(positionInfo.Ticket(), sl, positionInfo.TakeProfit());
                  }
                } else if(positionInfo.PositionType() == POSITION_TYPE_SELL){
                
                    //double mintp = NormalizeDouble(bid - (stopLevel + spread) * point, digits);
                    double minsl = NormalizeDouble(ask + (stopLevel + spread) * point, digits);
                    
                    //double	tp = bid - trailingDistance * point;
                    //tp = NormalizeDouble(tp - (stopLevel + spread) * point, digits);
                    
                    double sl = ask + trailingDistance * point;
                    sl = NormalizeDouble(sl + (stopLevel + spread) * point, digits);
                    
                    //printf(tp, sl);
                    
                    if(sl < minsl){
                    	//printf("Sell Position That error!");
						   return ;
					         }
                    
                	if( positionInfo.PriceCurrent() < positionInfo.PriceOpen() && (sl < positionInfo.StopLoss()||!positionInfo.StopLoss() ) )
                	{
                     trade.PositionModify(positionInfo.Ticket(), sl, positionInfo.TakeProfit());
                  }
                }
            } // SelectByTicket(ticket)
         } // if position in it..
    } // for loop ends here...
}

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
void OnTick()
{
   trailingMon();
}
//+------------------------------------------------------------------+
