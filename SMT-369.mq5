//+------------------------------------------------------------------+
//|                                                SmartMoneyTry.mq5 |
//|                                 Copyright 2024, AlgoJupiter Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, AlgoJupiter Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

input ENUM_TIMEFRAMES default_timeframe=PERIOD_M1;
input int lookback=2;
input int shift=0;
input int atr_period=14;
input int cci_period=20;
input int bb_period=20;
input double bb_deviation=2.0;

string	default_symbol=Symbol();

CTrade trade;

int cciHandle;
int obvHandle;
int bbHandle;
int atrHandle;

double cciValue[];
double obvValue[];
double bbValue[];
double atrValue[];

int OnInit()
  {
//---
	cciHandle=iCCI(default_symbol, default_timeframe, cci_period, _AppliedTo);
	obvHandle=iOBV(default_symbol, default_timeframe, VOLUME_TICK);
	bbHandle=iBands(default_symbol, default_timeframe, bb_period, shift, bb_deviation, _AppliedTo);
	atrHandle=iATR(default_symbol, default_timeframe, atr_period);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
	Print("Bye", reason);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(CopyBuffer(obvHandle, 0, shift, lookback, obvValue) <= 0){
   		return ;
   }
   
   if(CopyBuffer(cciHandle, 0, shift, lookback, cciValue) <= 0){
   		return ;
   }
   
   if(CopyBuffer(bbHandle, 0, shift, lookback, bbValue) <= 0){
   		return ;
   }
   
   if(CopyBuffer(atrHandle, 0, shift, lookback, atrValue) <= 0){
   		return ;
   } 
   
   //bool buySignal=
   //bool sellSignal=
   
   
// onticker function ends here
}
//+------------------------------------------------------------------+

// other functions

//double lotPartializer(double lotSize, int count){
//	return NormalizeDouble(lotSize / count, 2);
//}
//
//void fiboSequentialArray(double & emptyArray[], double start=0.116, double end=5.786, int count=5, int digits=3){
//	double step = (end - start) / (count - 1);
//	double array[];
//	for(int i=0; i < count; i++){;
//		array.Push(NormalizeDouble(start + i * step, digits));
//	}
//}
//
//int magicCounter(uint & magic) { 
//	static int count;
//	count++; 
//	if(count%100==0){
//		Print("Function Counter has been called ",count," times");
//	}
//	return count; 
//}