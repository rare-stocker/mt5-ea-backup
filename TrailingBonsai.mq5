//+------------------------------------------------------------------+
//|                                                  TrailerBonsai.mq5 |
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

string comments[] = {"Great job!","Well done!","Nice work!","Marvellous!","Awesome!","Excellent!","Very Nice!","Surprising!","Impressive!","Incredible!","Wonderful!","Sensational!","Magnificent!","Brilliant!","Very Cool!","Extraordinary!","Fantastic work!","Keep it up!","Amazing!","Interesting!","Spectacular!","Fascinating!","Charming!","Shocking!","Unimaginable!","Fabulous!","Attractive!","Mind-blowing!","Smashing!","Inspiring","Greatful!","Congrats!","Unbelievable!","Very Beautiful!","Superb!","Mysterious!","Brave!","Stunning!","Glorious!","Splendid!","Stentorian!"};

//-- functions
int getRandomRangeInteger(int start, int end)
{
    return start + MathRand() % end;
}

ulong getRandomMagic()
{
    return	getRandomRangeInteger(100000, 999999);
}

string getRandomComment()
{
    return comments[getRandomRangeInteger(0, ArraySize(comments))];
}

//-- inputs take from user
input	ENUM_TIMEFRAMES		default_timeframe=PERIOD_M1;
input	int			position_limit=1;
input	double		volume_limit=0.10;
input   double		reward_pct=2.40;
input   double		risk_pct=1.20;
input	int			atr_period=14;
input	double		atr_multiplier=1.0;
input	double		trailingDistance=0;
//input	bool		only_trail_sl=false;

//-- specified variables
int			lookback=161;
datetime	previous_bar_time;
int			shift=0;
bool		tradable_area=false;

//--- buffers arrays
double			atrBuffer[];
double			trailingUpperBuffer[];
double			trailingLowerBuffer[];
MqlRates		candles[];

//-- handlers
int			atrHandle;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
	printf("Welcome!");
	atrHandle = iATR(Symbol(), default_timeframe, atr_period);
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
	if(CopyBuffer(atrHandle, 0, shift, lookback, atrBuffer) <= 0){
		return ;
	}
	
	if(CopyRates(Symbol(), default_timeframe, shift, lookback, candles) <= 0){
		return ;
	}
	
	for(int i=0; i<ArraySize(atrBuffer); i++){
		
		ArrayResize(trailingUpperBuffer, i+1);
		trailingUpperBuffer[i]=candles[i].close + atrBuffer[i] * atr_multiplier;
		ArrayResize(trailingLowerBuffer, i+1);
		trailingLowerBuffer[i]=candles[i].close - atrBuffer[i] * atr_multiplier;
	}
	
	ArrayRemove(trailingUpperBuffer, 1, 1);
	ArrayRemove(trailingLowerBuffer, 1, 1);
//	
	ArraySetAsSeries(trailingUpperBuffer, true);
	ArraySetAsSeries(trailingLowerBuffer, true);
	ArraySetAsSeries(atrBuffer, true);
	ArraySetAsSeries(candles, true);
	
    datetime current_bar_time=candles[0].time;
    
    int spaceBetweenPositions=position_limit - PositionsTotal();
    
    bool buySignal=candles[0].low <= trailingLowerBuffer[0] && candles[0].close > candles[0].low;
    bool sellSignal=candles[0].high >= trailingUpperBuffer[0] && candles[0].close < candles[0].high;
	
    if(current_bar_time != previous_bar_time){
    	previous_bar_time = current_bar_time;
    	tradable_area = true;
    	
    }
	printf("New Candle Appear!");
	
	if(buySignal && spaceBetweenPositions >= 0 ){
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
        
        double	tp = trailingUpperBuffer[0] + trailingDistance * point;
        double	sl = trailingLowerBuffer[0] - trailingDistance * point;

	    //double tp=ask + reward_pct * point;
		//double sl=bid - risk_pct * point;
		
	    tp=NormalizeDouble(tp + (stopLevel + spread) * point, digits);
	    sl=NormalizeDouble(sl - (stopLevel + spread) * point, digits);
	    
	    if(tp < mintp || sl > minsl){
	    	printf("That error!");
			return ;
		}

		Alert("Buying Opertunity!");
		trade.Buy(volume_limit, Symbol(), ask, sl, tp, getRandomComment());
//    		//trade.SetExpertMagicNumber(getRandomMagic());
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
        
        double	tp = trailingLowerBuffer[0] - trailingDistance * point;
        double	sl = trailingUpperBuffer[0] + trailingDistance * point;
	 
	    //double tp=bid - reward_pct * point;
		//double sl=ask + risk_pct * point;
		
	    tp=NormalizeDouble(tp + (stopLevel + spread) * point, digits);
	    sl=NormalizeDouble(sl - (stopLevel + spread) * point, digits);
	    
	    if(tp > mintp || sl < minsl){
	    	printf("That error!");
			return ;
		}

		Alert("Selling Opertunity!");
		trade.SetExpertMagicNumber(getRandomMagic());
		trade.Sell(volume_limit, Symbol(), bid, sl, tp, getRandomComment());
//    		
    	}
    // automated positions modifying activities goes here...
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
                    
                    double	tp = trailingUpperBuffer[0] + trailingDistance * point;
                    tp = NormalizeDouble(tp + (stopLevel + spread) * point, digits);
                    
                    double sl = trailingLowerBuffer[0] - trailingDistance * point;
                    sl = NormalizeDouble(sl - (stopLevel + spread) * point, digits);
                    
                    //printf(tp, sl);
                    
                    if(tp < mintp || sl > minsl){
                    	//printf("Buy Position That error!");
						return ;
					}

                	if(positionInfo.PriceCurrent() > positionInfo.PriceOpen() && (sl > positionInfo.StopLoss() || tp > positionInfo.TakeProfit())) {
                    	//return;
                    	//if(!only_trail_sl){
                    	//	tp=positionInfo.TakeProfit();
                    	//}
                        trade.PositionModify(positionInfo.Ticket(), sl, tp);
                    } else if((!positionInfo.StopLoss() || !positionInfo.TakeProfit()) && (tp > positionInfo.PriceOpen() || sl < positionInfo.PriceOpen())) {
                        trade.PositionModify(positionInfo.Ticket(), sl, tp);
                    }
                } else if(positionInfo.PositionType() == POSITION_TYPE_SELL){
                
                    double mintp = NormalizeDouble(bid - (stopLevel + spread) * point, digits);
                    double minsl = NormalizeDouble(ask + (stopLevel + spread) * point, digits);
                    
                    double	tp = trailingLowerBuffer[0] - trailingDistance * point;
                    tp = NormalizeDouble(tp - (stopLevel + spread) * point, digits);
                    
                    double sl = trailingUpperBuffer[0] + trailingDistance * point;
                    sl = NormalizeDouble(sl + (stopLevel + spread) * point, digits);
                    
                    //printf(tp, sl);
                    
                    if(tp > mintp || sl < minsl){
                    	//printf("Sell Position That error!");
						return ;
					}
                    
                	if( positionInfo.PriceCurrent() < positionInfo.PriceOpen() && (sl < positionInfo.StopLoss() || tp < positionInfo.TakeProfit()) ) {
                    	//return;
                    	//if(!only_trail_sl){
                    	//	tp=positionInfo.TakeProfit();
                    	//}
                        trade.PositionModify(positionInfo.Ticket(), sl, tp);
                    } else if( (!positionInfo.StopLoss() || !positionInfo.TakeProfit()) && (tp < positionInfo.PriceOpen() || sl > positionInfo.PriceOpen()) ) {
                        trade.PositionModify(positionInfo.Ticket(), sl, tp);
                    }
                }
            }
         }
    }

}