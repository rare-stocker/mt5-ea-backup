//+------------------------------------------------------------------+
//|                                                        TestA.mq5 |
//|                                 Copyright 2024, AlgoJupiter Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, AlgoJupiter Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
CTrade trade;

input int   position_limit = 1;
input double    volume_limit = 0.12;

string getInfo(string symbol){
	int calc_mode=(int)SymbolInfoInteger(symbol, SYMBOL_TRADE_CALC_MODE);
	string str_calc_mode="Unknown";
	switch(calc_mode){
	      case SYMBOL_CALC_MODE_FOREX:str_calc_mode="Forex";break;
	      case SYMBOL_CALC_MODE_FOREX_NO_LEVERAGE:str_calc_mode="Forex no leverage";break;
	      case SYMBOL_CALC_MODE_FUTURES:str_calc_mode="Futures";break;
	      case SYMBOL_CALC_MODE_CFD:str_calc_mode="CFD";break;
	      case SYMBOL_CALC_MODE_CFDINDEX:str_calc_mode="CFD for indices";break;
	      case SYMBOL_CALC_MODE_CFDLEVERAGE:str_calc_mode="CFD at leverage trading";break;
	      case SYMBOL_CALC_MODE_EXCH_STOCKS:str_calc_mode="trading securities on a stock exchange";break;
	      case SYMBOL_CALC_MODE_EXCH_FUTURES:str_calc_mode="trading futures contracts on a stock exchange";break;
	      case SYMBOL_CALC_MODE_EXCH_FUTURES_FORTS:str_calc_mode="trading futures contracts on FORTS";break;
	      case SYMBOL_CALC_MODE_EXCH_BONDS:str_calc_mode="Bonds";break;
	      case SYMBOL_CALC_MODE_EXCH_BONDS_MOEX:str_calc_mode="Bonds moex";break;
	      case SYMBOL_CALC_MODE_EXCH_OPTIONS_MARGIN:str_calc_mode="Options margin";break;
	      case SYMBOL_CALC_MODE_EXCH_STOCKS_MOEX:str_calc_mode="Stock moex";break;
	      case SYMBOL_CALC_MODE_SERV_COLLATERAL:str_calc_mode="Serv collatral";break;
	}
	return str_calc_mode+" - "+symbol;
}

//+------------------------------------------------------------------+
//| Script program start function                                    |
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
////---

   double reward_pct = 0.300;
   double risk_pct = 0.100;

   for(int i=PositionsTotal()-1; i >= 0; i--){
   		if(PositionGetSymbol(i) == Symbol()){
	   		ulong ticket = PositionGetTicket(i);
	        CPositionInfo positionInfo;
	        if(positionInfo.SelectByTicket(ticket)){
	        
	        	//printf(getInfo(positionInfo.Symbol()));
	        	
	        	double ask = SymbolInfoDouble(positionInfo.Symbol(), SYMBOL_ASK);
	    	    double bid = SymbolInfoDouble(positionInfo.Symbol(), SYMBOL_BID);
	    	    
			    int stopLevel = (int)SymbolInfoInteger(positionInfo.Symbol(), SYMBOL_TRADE_STOPS_LEVEL);
			    int spread = (int)SymbolInfoInteger(positionInfo.Symbol(), SYMBOL_SPREAD);
			    
			    double contractSize = SymbolInfoDouble(positionInfo.Symbol(), SYMBOL_TRADE_CONTRACT_SIZE);
			    double tickSize = SymbolInfoDouble(positionInfo.Symbol(), SYMBOL_TRADE_TICK_SIZE);
				    
	            if(positionInfo.PositionType() == POSITION_TYPE_BUY){
	            	
				    double tp = NormalizeDouble(ask + reward_pct + (spread + stopLevel) * _Point, _Digits);
				    double sl = NormalizeDouble(bid - risk_pct - (spread + stopLevel) * _Point, _Digits);
	                
	                if(positionInfo.PriceCurrent() > positionInfo.PriceOpen() && positionInfo.StopLoss() < sl){
	                    trade.PositionModify(positionInfo.Ticket(), sl, positionInfo.TakeProfit());
	                }else if( (!positionInfo.StopLoss() || !positionInfo.TakeProfit()) && (tp > positionInfo.PriceOpen() || sl < positionInfo.PriceOpen()) ){
	                    trade.PositionModify(positionInfo.Ticket(), sl, tp);
	                }
	            }else if(positionInfo.PositionType() == POSITION_TYPE_SELL){
	    		    
				    double tp = NormalizeDouble(bid - reward_pct - (spread + stopLevel) * _Point, _Digits);
				    double sl = NormalizeDouble(ask + risk_pct - (spread + stopLevel) * _Point, _Digits);
	                
	                if(positionInfo.PriceCurrent() < positionInfo.PriceOpen() && positionInfo.StopLoss() > sl){
	                    trade.PositionModify(positionInfo.Ticket(), sl, positionInfo.TakeProfit());
	                }else if( (!positionInfo.StopLoss() || !positionInfo.TakeProfit()) && (tp < positionInfo.PriceOpen() || sl > positionInfo.PriceOpen()) ){
	                    trade.PositionModify(positionInfo.Ticket(), sl, tp);
	                }
	            }
	        }
   		}
   }
   
  }
////+------------------------------------------------------------------+
