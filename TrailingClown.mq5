//+------------------------------------------------------------------+
//|                                                  BandTrailer.mq5 |
//|                                 Copyright 2024, AlgoJupiter Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, AlgoJupiter Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "An AI Based Programme!"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

CTrade trade;
CPositionInfo positionInfo;

input ENUM_TIMEFRAMES default_timeframe=PERIOD_M1;
input	int			position_limit=1;
input	double		volume_limit=0.10;
input	int		lookback=2;
input   double		reward_pct=1.40;
input   double		risk_pct=1.20;
input	double		trailingExtDistance=0;

input	int		ma_period=20;

int obvHandle;
int ma20Handle;

double obv[];
double ma20[];
MqlRates candles[];

double trailingLevel;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
	printf("Welcome");
	obvHandle = iOBV(Symbol(), default_timeframe, VOLUME_TICK);
	ma20Handle = iMA(Symbol(), default_timeframe, ma_period, 0, MODE_SMA, PRICE_CLOSE);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
	printf("Bye!", reason);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
	if(CopyBuffer(obvHandle, 0, 0, lookback, obv) <= 0){
		return ;
	}
	
	if(CopyBuffer(ma20Handle, 0, 0, lookback, ma20) <= 0){
		return ;
	}
	
	if(CopyRates(Symbol(), default_timeframe, 0, lookback, candles) <= 0){
		return ;
	}
	
	ArraySetAsSeries(obv, true);
	ArraySetAsSeries(candles, true);
	ArraySetAsSeries(ma20, true);
	
	bool isGreen=candles[0].close > candles[0].open;
	
	if(isGreen){
		trailingLevel = candles[0].close + (candles[0].low - candles[0].close) / 2;
	}else{
		trailingLevel = candles[0].close - (candles[0].close - candles[0].high) / 2;
	}
	
	bool buyConformation=obv[0] > obv[1];
	bool sellConformation=obv[0] < obv[1];
	
	bool buyWhen=candles[0].close < ma20[0];
	bool sellWhen=candles[0].close > ma20[0];
	
	bool buySignal=isGreen && buyConformation;
	bool sellSignal=!isGreen && sellConformation;
	
	int spaceBetweenPositions=position_limit-PositionsTotal();
	
	if(buySignal && spaceBetweenPositions >= 0){
		double ask=SymbolInfoDouble(Symbol(), SYMBOL_ASK);
		double bid=SymbolInfoDouble(Symbol(), SYMBOL_BID);
		double stopLevel=(int)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL);
		double spread=(int)SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
		int digits=(int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
	    double point=SymbolInfoDouble(Symbol(), SYMBOL_POINT);
	    //double contractSize=SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE);
	    //double tickSize=SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
	    
	    double mintp = NormalizeDouble(ask + (stopLevel + spread) * point, digits);
      	double minsl = NormalizeDouble(bid - (stopLevel + spread) * point, digits);

        //double	tp = trailingLevel + trailingExtDistance * point;
        double	sl = trailingLevel - trailingExtDistance * point;

	    double tp=ask + reward_pct * point;
		//double sl=bid - risk_pct * point;
		
	    tp=NormalizeDouble(tp + (stopLevel + spread) * point, digits);
	    sl=NormalizeDouble(sl - (stopLevel + spread) * point, digits);
	    
	    if(tp < mintp || sl > minsl){
	    	printf("That error!");
			return ;
		}
		//bulkClose(Symbol(), POSITION_TYPE_SELL);
		trade.Buy(volume_limit, Symbol(), ask, sl);
	}else if(sellSignal && spaceBetweenPositions >= 0){
		double ask=SymbolInfoDouble(Symbol(), SYMBOL_ASK);
		double bid=SymbolInfoDouble(Symbol(), SYMBOL_BID);
		double stopLevel=(int)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL);
		double spread=(int)SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
		int digits=(int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
	    double point=SymbolInfoDouble(Symbol(), SYMBOL_POINT);
	    //double contractSize=SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE);
	    //double tickSize=SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
	    
	    double mintp = NormalizeDouble(bid - (stopLevel + spread) * point, digits);
        double minsl = NormalizeDouble(ask + (stopLevel + spread) * point, digits);

        //double	tp = trailingLevel - trailingExtDistance * point;
        double	sl = trailingLevel + trailingExtDistance * point;
	 
	    double tp=bid - reward_pct * point;
		//double sl=ask + risk_pct * point;
		
	    tp=NormalizeDouble(tp + (stopLevel + spread) * point, digits);
	    sl=NormalizeDouble(sl - (stopLevel + spread) * point, digits);
	    
	    if(tp > mintp || sl < minsl){
	    	printf("That error!");
			return ;
		}
		//bulkClose(Symbol(), POSITION_TYPE_BUY);
		trade.Sell(volume_limit, Symbol(), bid, sl);
	}
	
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

                    double mintp = NormalizeDouble(ask + (stopLevel + spread) * point, digits);
                    double minsl = NormalizeDouble(bid - (stopLevel + spread) * point, digits);
                    
                    double	tp = trailingLevel + trailingExtDistance * point;
                    tp = NormalizeDouble(tp + (stopLevel + spread) * point, digits);
                    
                    double sl = trailingLevel - trailingExtDistance * point;
                    sl = NormalizeDouble(sl - (stopLevel + spread) * point, digits);
                    
                    //printf(tp, sl);
                    
     //               if(tp < mintp || sl > minsl){
     //               	printf("Buy Position That error!");
					//	return ;
					//}

                	if(positionInfo.PriceCurrent() > positionInfo.PriceOpen() && (sl > positionInfo.StopLoss() || tp > positionInfo.TakeProfit())) {
                        trade.PositionModify(positionInfo.Ticket(), sl, positionInfo.TakeProfit());
                    }
                } else if(positionInfo.PositionType() == POSITION_TYPE_SELL){
                
                    double mintp = NormalizeDouble(bid - (stopLevel + spread) * point, digits);
                    double minsl = NormalizeDouble(ask + (stopLevel + spread) * point, digits);
                    
                    double	tp = trailingLevel - trailingExtDistance * point;
                    tp = NormalizeDouble(tp - (stopLevel + spread) * point, digits);
                    
                    double sl = trailingLevel + trailingExtDistance * point;
                    sl = NormalizeDouble(sl + (stopLevel + spread) * point, digits);
                    
                    //printf(tp, sl);
                    
     //               if(tp > mintp || sl < minsl){
     //               	printf("Sell Position That error!");
					//	return ;
					//}
                    
                	if( positionInfo.PriceCurrent() < positionInfo.PriceOpen() && (sl < positionInfo.StopLoss() || tp < positionInfo.TakeProfit()) ) {
                        trade.PositionModify(positionInfo.Ticket(), sl, positionInfo.TakeProfit());
                    }
                }
            }
         }
    }
}
//+------------------------------------------------------------------+