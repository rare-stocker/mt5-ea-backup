//+------------------------------------------------------------------+
//|                                                 hft_breakout.mq5 |
//|                                 Copyright 2024, AlgoJupiter Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, AlgoJupiter Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description	"An Algo Based Programme!"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
//#include <Math\Alglib\matrix.mqh>
#include <Trade\SymbolInfo.mqh>
//#include <Arrays\Array.mqh>
//#include <Arrays\ArrayList.mqh>
#include <Generic\HashMap.mqh>

input	ENUM_TIMEFRAMES	default_timeframe=PERIOD_CURRENT;

input	int   position_limit = 2;
input	double    volume_limit = 0.02;
input	int		atr_period = 14;
input	double atr_multiplier = 1.0;
input   double reward_pct = 2.40;
input   double risk_pct = 1.20;
input	bool multi_trade_takeprofit = true;
input	bool trailing_stoploss = true;

string comments[] = {"Great job!","Well done!","Nice work!","Marvellous!","Awesome!","Excellent!","Very Nice!","Surprising!","Impressive!","Incredible!","Wonderful!","Sensational!","Magnificent!","Brilliant!","Very Cool!","Extraordinary!","Fantastic work!","Keep it up!","Amazing!","Interesting!","Spectacular!","Fascinating!","Charming!","Shocking!","Unimaginable!","Fabulous!","Attractive!","Mind-blowing!","Smashing!","Inspiring","Greatful!","Congrats!","Unbelievable!","Very Beautiful!","Superb!","Mysterious!","Brave!","Stunning!","Glorious!","Splendid!","Stentorian!"};

double fib_sequenses[]= {0.236, 0.382, 0.5, 0.618, 0.786, 1.386, 1.618, 2.0, 2.414, 2.786, 3.0};

int getRandomRangeInteger(int start, int end)
{
    return start + MathRand() % end;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ulong getRandomMagic()
{
    return	getRandomRangeInteger(100000, 999999);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getRandomComment()
{
    return comments[getRandomRangeInteger(0, ArraySize(comments))];
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getInfo(string symbol)
{
    int calc_mode=(int)SymbolInfoInteger(symbol, SYMBOL_TRADE_CALC_MODE);
    string str_calc_mode="Unknown";
    switch(calc_mode) {
    case SYMBOL_CALC_MODE_FOREX:
        str_calc_mode="Forex";
        break;
    case SYMBOL_CALC_MODE_FOREX_NO_LEVERAGE:
        str_calc_mode="Forex no leverage";
        break;
    case SYMBOL_CALC_MODE_FUTURES:
        str_calc_mode="Futures";
        break;
    case SYMBOL_CALC_MODE_CFD:
        str_calc_mode="CFD";
        break;
    case SYMBOL_CALC_MODE_CFDINDEX:
        str_calc_mode="CFD for indices";
        break;
    case SYMBOL_CALC_MODE_CFDLEVERAGE:
        str_calc_mode="CFD at leverage trading";
        break;
    case SYMBOL_CALC_MODE_EXCH_STOCKS:
        str_calc_mode="trading securities on a stock exchange";
        break;
    case SYMBOL_CALC_MODE_EXCH_FUTURES:
        str_calc_mode="trading futures contracts on a stock exchange";
        break;
    case SYMBOL_CALC_MODE_EXCH_FUTURES_FORTS:
        str_calc_mode="trading futures contracts on FORTS";
        break;
    case SYMBOL_CALC_MODE_EXCH_BONDS:
        str_calc_mode="Bonds";
        break;
    case SYMBOL_CALC_MODE_EXCH_BONDS_MOEX:
        str_calc_mode="Bonds moex";
        break;
    case SYMBOL_CALC_MODE_EXCH_OPTIONS_MARGIN:
        str_calc_mode="Options margin";
        break;
    case SYMBOL_CALC_MODE_EXCH_STOCKS_MOEX:
        str_calc_mode="Stock moex";
        break;
    case SYMBOL_CALC_MODE_SERV_COLLATERAL:
        str_calc_mode="Serv collatral";
        break;
    }
    return str_calc_mode+" - "+symbol;
}

void marketBuy(string symbol, double volume, double risk=NULL, double reward=NULL, ulong magic=NULL){

	double ask=SymbolInfoDouble(symbol, SYMBOL_ASK);
	double bid=SymbolInfoDouble(symbol, SYMBOL_BID);
	double stopLevel=(int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
	double spread=(int)SymbolInfoInteger(symbol, SYMBOL_SPREAD);
	int digits=(int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double point=SymbolInfoDouble(symbol, SYMBOL_POINT);
    double contractSize=SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    double tickSize=SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
	
	MqlTradeRequest request={};
	MqlTradeResult  result={};
	
	if(!reward){
		reward=reward_pct;
	}
	
	if(!risk){
		risk=risk_pct;
	}
	
	double tp=ask + reward * point;
	double sl=bid - risk * point;
	
	request.symbol=symbol;
	request.action=TRADE_ACTION_DEAL;
	request.deviation=20;
	request.volume=volume;
	request.type=ORDER_TYPE_BUY;
	request.type_time=ORDER_TIME_GTC;
	request.type_filling=ORDER_FILLING_FOK;
	request.price=ask;
	request.tp=NormalizeDouble(tp + (stopLevel + spread) * point, digits);
	request.sl=NormalizeDouble(sl - (stopLevel + spread) * point, digits);
	request.magic=magic || getRandomMagic();
	request.comment=getRandomComment();
	
	if(!OrderSend(request, result)){
		printf("Buy Order Cancelled", result.retcode);
	}
}

void marketSell(string symbol, double volume, double risk=NULL, double reward=NULL, ulong magic=NULL){

	double ask=SymbolInfoDouble(symbol, SYMBOL_ASK);
	double bid=SymbolInfoDouble(symbol, SYMBOL_BID);
	double stopLevel=(int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
	double spread=(int)SymbolInfoInteger(symbol, SYMBOL_SPREAD);
	int digits=(int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double point=SymbolInfoDouble(symbol, SYMBOL_POINT);
    double contractSize=SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    double tickSize=SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
	
	MqlTradeRequest request={};
	MqlTradeResult  result={};
	
	if(!reward){
		reward=reward_pct;
	}
	
	if(!risk){
		risk=risk_pct;
	}
	
	double tp=bid + reward * point;
	double sl=ask - risk * point;
	
	request.symbol=symbol;
	request.action=TRADE_ACTION_DEAL;
	request.deviation=20;
	request.volume=volume;
	request.type=ORDER_TYPE_SELL;
	request.type_time=ORDER_TIME_GTC;
	request.type_filling=ORDER_FILLING_FOK;
	request.price=bid;
	request.tp=NormalizeDouble(tp + (stopLevel + spread) * point, digits);
	request.sl=NormalizeDouble(sl - (stopLevel + spread) * point, digits);
	request.magic=magic || getRandomMagic();
	request.comment=getRandomComment();
	
	if(!OrderSend(request, result)){
		printf("Sell Order Cancelled", result.retcode);
	}
}

void modifySLTP(string symbol, ulong ticket, string type, double risk=NULL, double reward=NULL){
	double ask=SymbolInfoDouble(symbol, SYMBOL_ASK);
	double bid=SymbolInfoDouble(symbol, SYMBOL_BID);
	double stopLevel=(int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
	double spread=(int)SymbolInfoInteger(symbol, SYMBOL_SPREAD);
	int digits=(int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double point=SymbolInfoDouble(symbol, SYMBOL_POINT);
    double contractSize=SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
    double tickSize=SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
	
	MqlTradeRequest request={};
	MqlTradeResult  result={};
	
	request.symbol=symbol;
	request.action=TRADE_ACTION_SLTP;
	request.order=ticket;
	//request.sl=sl;
	//request.tp=tp;
	
	if(!OrderSend(request, result)){
		printf("Modify Order Cancelled", result.retcode);
	}
}

CTrade trade;
CSymbolInfo symbolInfo;
CPositionInfo positionInfo;

//double lotPartializer(double lotSize, int count){
//	return NormalizeDouble(lotSize / count, 2);
//}

//void fibSequentialArray(double start=0.116, double end=5.786, int count=5, int digits=3){
//	double step = (end - start) / (count - 1);
//	double fibArray[];
//	for(int i=0; i < count; i++){;
//		fibArray.Push(NormalizeDouble(start + i * step, digits));
//	}
//}

//void setMagicList(string symbol){
//	
//	int magicLst[];
//    for(int i=0; i < PositionsTotal(); i++) {
//        if(PositionGetSymbol(i) == symbol) {
//            //ulong ticket = PositionGetTicket(i);
//            ulong magic = (int)PositionGetInteger(POSITION_MAGIC);
//            magicLst.Push(magic);
//        }
//    }
//}

//void setFrequencyOfMagicArray(ulong &array[]){
//	CHashMap<ulong, int> frequency;
//	int v=0;
//	for(int i=0; i<ArraySize(array); i++){
//		if(!frequency.ContainsKey(array[i])){
//			frequency.TrySetValue(array[i], 0);
//		}
//		v+=1;
//		frequency.TrySetValue(array[i], v);
//	}
//}

int		lookback=60;
int     shift=0;
int     lastBreakOut;

MqlRates	candle[];
int		atrHandle;
double		atrBuffer[];

double upper[];
double lower[];

datetime previous_bar_time;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
    printf("Welcome");
    
//---
    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//---
    printf("Okay Bye!", reason);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
{
//---
    double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    bid = NormalizeDouble(bid, _Digits);

    double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    ask = NormalizeDouble(ask, _Digits);

    int stopLevel = (int)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL);
    int spread = (int)SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
    int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);

    double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);

    double contractSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE);
    double tickSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
    
    CopyRates(Symbol(), default_timeframe, 0, lookback, candle);
    ArraySetAsSeries(candle, true);
    
    atrHandle = iATR(Symbol(), default_timeframe, atr_period);
    
    CopyBuffer(atrHandle, 1, 0, lookback, atrBuffer);
    ArraySetAsSeries(atrBuffer, true);
    
    for(int i=0; i > ArraySize(atrBuffer); i++){
    	lower[i]=candle[i].close - atrBuffer[i] * atr_multiplier;
    	upper[i]=candle[i].close + atrBuffer[i] * atr_multiplier;
    }
    
    datetime current_bar_time=candle[0].time;
    
    int spaceBetweenPositions=position_limit - PositionsTotal();
    
    if(current_bar_time != previous_bar_time){
    	previous_bar_time = current_bar_time;
    	Alert("New Candle Appear!");
    	// that multiple tp based on fib stratagy cames here...
		if(candle[0].low <= lower[0] && candle[0].close > candle[0].low && spaceBetweenPositions >= 0) {
		    printf("Buy");
		    lastBreakOut = 1;
		
		    double	tp = ask + reward_pct * point;
		    tp = NormalizeDouble(tp + (stopLevel + spread) * point, digits);
		
		    double sl = bid - risk_pct * point;
		    sl = NormalizeDouble(sl - (stopLevel + spread) * point, digits);
		    
			//marketBuy(Symbol(), volume_limit, risk_pct, reward_pct);
		    trade.Buy(volume_limit, Symbol(), ask, sl, tp, getRandomComment());
		    
		}else if(candle[0].high >= upper[0] && candle[0].close < candle[0].high && spaceBetweenPositions >= 0) {
		    printf("Sell");
		    lastBreakOut = -1;
		
		    double	tp = bid - reward_pct * point;
		    tp = NormalizeDouble(tp - (stopLevel + spread) * point, digits);
		
		    double sl = ask + risk_pct * point;
		    sl = NormalizeDouble(sl + (stopLevel + spread) * point, digits);
		    
		    //marketSell(Symbol(), volume_limit, risk_pct, reward_pct);
		    trade.Sell(volume_limit, Symbol(), bid, sl, tp, getRandomComment());

	    }
	}

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

                    double	tp = ask + reward_pct * point;
                    tp = NormalizeDouble(tp + (stopLevel + spread) * point, digits);

                    double sl = bid - risk_pct * point;
                    sl = NormalizeDouble(sl - (stopLevel + spread) * point, digits);

                    if(positionInfo.PriceCurrent() > positionInfo.PriceOpen() && positionInfo.StopLoss() < sl) {
                    	//return;
                        trade.PositionModify(positionInfo.Ticket(), sl, positionInfo.TakeProfit());
                    }else if((!positionInfo.StopLoss() || !positionInfo.TakeProfit()) && (tp > positionInfo.PriceOpen() || sl < positionInfo.PriceOpen())) {
                        trade.PositionModify(positionInfo.Ticket(), sl, tp);
                    }
                    // else if there is sell positions.
                } else if(positionInfo.PositionType() == POSITION_TYPE_SELL) {

                    double	tp = bid - reward_pct * point;
                    tp = NormalizeDouble(tp - (stopLevel + spread) * point, digits);

                    double sl = ask + risk_pct * point;
                    sl = NormalizeDouble(sl + (stopLevel + spread) * point, digits);

                    if(positionInfo.PriceCurrent() < positionInfo.PriceOpen() && positionInfo.StopLoss() > sl) {
                    	//return;
                        trade.PositionModify(positionInfo.Ticket(), sl, positionInfo.TakeProfit());
                    }else if( (!positionInfo.StopLoss() || !positionInfo.TakeProfit()) && (tp < positionInfo.PriceOpen() || sl > positionInfo.PriceOpen())) {
                        trade.PositionModify(positionInfo.Ticket(), sl, tp);
                    }
                }
            }
        }

    }

    Comment("\nStopLevel: ", stopLevel, "\nSpread: ", spread, "\nContractSize: ", contractSize, "\nTickSize: ",tickSize, "\nPoint: ", point, "\nInfo: ", getInfo(_Symbol), "\nComment: ",getRandomComment());

}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
//void OnTrade()
//  {
////---
//   
//  }
//+------------------------------------------------------------------+
//| BookEvent function                                               |
//+------------------------------------------------------------------+
//void OnBookEvent(const string &symbol)
//  {
//---
//   
//  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
//---
	printf(trans.deal, trans.order);
   
  }
//+-----------------------------------------------------------------