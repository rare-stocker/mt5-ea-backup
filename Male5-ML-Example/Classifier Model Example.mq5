//+------------------------------------------------------------------+
//|                                      Classifier Model Sample.mq5 |
//|                                     Copyright 2023, Omega Joctan |
//|                        https://www.mql5.com/en/users/omegajoctan |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Omega Joctan"
#property link      "https://www.mql5.com/en/users/omegajoctan"
#property version   "1.00"

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

#include <MALE5\Decision Tree\tree.mqh>
#include <MALE5\preprocessing.mqh>
#include <MALE5\MatrixExtend.mqh> //helper functions for for data manipulations
#include <MALE5\metrics.mqh> //fo measuring the performance

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

CTrade trade;
CPositionInfo positionInfo;

input ENUM_TIMEFRAMES default_timeframe=PERIOD_M1;
input int bars_lookback=14;
input int bars_shift=1;
input int data_size = 50;
input	int   position_limit=6;
input	double   volume_limit=3.0;
input   double reward_pct=100.20;
input   double risk_pct=20.20;

input bool require_trailing=true;
input double trailingDistance=20.20;

StandardizationScaler scaler; //standardization scaler from preprocessing.mqh
CDecisionTreeClassifier *decision_tree; //a decision tree classifier model

MqlRates rates[];

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
  
//--- Model selection
   
     decision_tree = new CDecisionTreeClassifier(2, 5); //a decision tree classifier from DecisionTree class
     
//---

     vector time, open, high, low, close;
     
//--- Getting the open, high, low and close values for the past 1000 bars, starting from the recent closed bar of 1
     
     time.CopyRates(Symbol(), default_timeframe, COPY_RATES_TIME, bars_shift, data_size);
     open.CopyRates(Symbol(), default_timeframe, COPY_RATES_OPEN, bars_shift, data_size);
     high.CopyRates(Symbol(), default_timeframe, COPY_RATES_HIGH, bars_shift, data_size);
     low.CopyRates(Symbol(), default_timeframe, COPY_RATES_LOW, bars_shift, data_size);
     close.CopyRates(Symbol(), default_timeframe, COPY_RATES_CLOSE, bars_shift, data_size);
     
     matrix X(data_size, 3); //creating the x matrix 
   
//--- Assigning the open, high, and low price values to the x matrix 
     X.Col(time, 0);
     X.Col(open, 1);
     X.Col(high, 2);
     X.Col(low, 3);
     
//--- Since we are using the x variables to predict y, we choose the close price to be the target variable 
   
     vector y(data_size); 
     for (int i=0; i<data_size; i++)
       {
         if (close[i]>open[i]) //a bullish candle appeared
           y[i] = 1; //buy signal
         else
           {
             y[i] = 0; //sell signal
           } 
       }

//--- We split the data into training and testing samples for training and evaluation
 
     matrix X_train, X_test;
     vector y_train, y_test;
     
     double train_size = 0.7; //70% of the data should be used for training the rest for testing
     int random_state = 42; //we put a random state to shuffle the data so that a machine learning model understands the patterns and not the order of the dataset, this makes the model durable
      
     MatrixExtend::TrainTestSplitMatrices(X, y, X_train, y_train, X_test, y_test, train_size, random_state); // we split the x and y data into training and testing samples         
     

//--- Normalizing the independent variables
   
     X_train = scaler.fit_transform(X_train); // we fit the scaler on the training data and transform the data alltogether
     X_test = scaler.transform(X_test); // we transform the new data this way
     

//--- Training the  model
     
     decision_tree.fit(X_train, y_train); //The training function 
     
//--- Measuring predictive accuracy 
   
     vector train_predictions = decision_tree.predict_bin(X_train);
     
     Print("Training results classification report");
     Metrics::classification_report(y_train, train_predictions);

//--- Evaluating the model on out-of-sample predictions
     
     vector test_predictions = decision_tree.predict_bin(X_test);
     
     Print("Testing results classification report");
     Metrics::classification_report(y_test, test_predictions); 
     
//---

    ArraySetAsSeries(rates, true);
        

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
    delete (decision_tree); //We have to delete the AI model object from the memory
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // tailing mon
   if(require_trailing){
      trailingMon();
   }

//--- Making predictions live from the market 
   
   CopyRates(Symbol(), default_timeframe, 0, bars_lookback, rates); //Get the very recent information from the market
   
   vector x = {(double)rates[0].time, rates[0].open, rates[0].high, rates[0].low}; //Assigning data from the recent candle in a similar way to the training data
   
   x = scaler.transform(x);
   int signal = (int)decision_tree.predict_bin(x);
   
   double ask=SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double bid=SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double stopLevel=(int)SymbolInfoInteger(positionInfo.Symbol(), SYMBOL_TRADE_STOPS_LEVEL);
   double spread=(int)SymbolInfoInteger(positionInfo.Symbol(), SYMBOL_SPREAD);
   int digits=(int)SymbolInfoInteger(positionInfo.Symbol(), SYMBOL_DIGITS);
   double point=SymbolInfoDouble(positionInfo.Symbol(), SYMBOL_POINT);
   //double contractSize=SymbolInfoDouble(positionInfo.Symbol(), SYMBOL_TRADE_CONTRACT_SIZE);
   //double tickSize=SymbolInfoDouble(positionInfo.Symbol(), SYMBOL_TRADE_TICK_SIZE);
   int spaceBetweenPositions=position_limit - PositionsTotal();
   
   Comment("Signal = ",signal==1?"BUY":"SELL");  //Ternary operator for checking if the signal is either buy or sell
   
   if( signal==1 && spaceBetweenPositions >=0 ){
      double   tp = ask + reward_pct * point;
      double	sl = bid - risk_pct * point;
	   tp=NormalizeDouble(tp + (stopLevel + spread) * point, digits);
	   sl=NormalizeDouble(sl - (stopLevel + spread) * point, digits);
      trade.Buy(volume_limit, Symbol(), ask, sl, tp, getRandomComment());
   }else if(signal==0 && spaceBetweenPositions >=0 ){
	   double   tp=bid - reward_pct * point;
		double   sl=ask + risk_pct * point;
	   tp=NormalizeDouble(tp - (stopLevel + spread) * point, digits);
	   sl=NormalizeDouble(sl + (stopLevel + spread) * point, digits);
      trade.Sell(volume_limit, Symbol(), bid, sl, tp, getRandomComment());
   }
   
   // it all
  }
//+------------------------------------------------------------------+
