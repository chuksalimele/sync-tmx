//+------------------------------------------------------------------+
//|                                              SyncClientX.mq4 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <stdlib.mqh> 
#include <Arrays/List.mqh> 
#include <Object.mqh> 
 
#include <Strings/String.mqh>
#include <Controls/Dialog.mqh>
#include <Controls/Button.mqh>
#include <Controls/Label.mqh>
#include <Controls/ListView.mqh>
#include <Controls/Edit.mqh>

#define VERSION "13.0.0"

#define COPIED_TRADE_MAGIC_NUMBER 114455


#import "SyncTradeConnector.dll"

    bool IsSocketConnected(void);
   
    bool Connect(string host, int port);
   
    void CloseSocket(void);

    int Send(string data);
   
    int SendChars(char& data[]);
    
    int DataLength(void);
      
    void PacketReceived(char& buffer[], int buff_len); 
      
    int GetData(void);
   
    int GetSyncLastError(void);
   
    void GetSyncLastErrorDesc(char& error[], int len);
   
   

#import

//+------------------------------------------------------------------+
//| Class definition for a Printer       |
//+------------------------------------------------------------------+
class Printer {
   private:
      string _once_data;
      string _start_id;
      string _end_id;
public:
   Printer(){};
   ~Printer(){};
   
   void init(){
      _once_data = "";
      _start_id = "";
      _end_id = "";
   };
   void printOnce(string data){
      if(_once_data != data){
         Print(data);
         _once_data = data;
      }
   };
   void print(string data){
      if(_start_id != _end_id){
         Print(data);
      }
   };

   void start(string start_id){
      _start_id = start_id;
   };
   void end(string end_id){
      _end_id = end_id;
   }; 
   void start(int start_id){
      _start_id = IntegerToString(start_id);
   };
   void end(int end_id){
      _end_id = IntegerToString(end_id);
   };        
};

int ExtConnection=-1;

int UNDEFINED = -1;

enum AdjustableExitSpreadStrategy{
      NO_SPREAD,
      LOWEST_SPREAD,
      AVERAGE_SPREAD,
      HIGHEST_SPREAD,
};

enum ExitClearanceFactor{
     _0_PERCENT,
     _30_PERCENT,
     _50_PERCENT,
     _80_PERCENT,
     _100_PERCENT,
};

class VirtualSync: public CObject{
      public: ulong own_ticket;
      public: ulong peer_ticket;
      public: double peer_stoploss;
      public: double peer_spread_point;
      public: bool IsHitPeerStoploss;
      
                  
      public: VirtualSync(void){};                          
              ~VirtualSync(void){};                                              
};        
  
input bool EnableManualStoplossAdjustion = false;  // TESTING!!! EnableManualStoplossAdjustion

bool SyncCopyManualEntry = false;// Sync copy manual entry
ExitClearanceFactor exitClearanceFactor = _30_PERCENT;// Exit clearance factor
bool OnlyTradeWithCredit = false;// Only trade with credit.


enum TradeMode{
      PACKET,
      LIVE
};

//int ExtConnection=-1;
struct MarketPrice {
   string symbol;
   double bid;
   double ask;
};

struct TradePacket{
   string command;
   string command_id;
   string action;
   string uuid;
   string force;
   string reason;
   string origin_ticket;
   
   string immediate;
   
   string peer_broker;
   string peer_account_number;
   
   ulong own_ticket;
   ulong peer_ticket;
   double peer_stoploss;
   double peer_spread_point;
      
   string symbol;
   ulong ticket;   
   string position;
   double lot_size;
   double open_price;
   long signal_time;
   long close_time;
   long open_time;
   double target;//target price
   double stoploss;//stoploss price
   double spread_point;
   string copy_type;
   
   double floating_balance;
   double account_balance;
   
   double partial_closed_lot_fraction;
   
   string sync_state_paird_id;
};

struct ChangeStats{

   bool TradeCountChanged;
   bool TradeCountIncreased;
   bool TradeModified;
   bool TradeSwapChanged;

};

string Host = "localhost";
int Port = 4000;
double EXIT_CLEARANCE_FACTOR = 0.3;
MarketPrice prices [47];
string PRICE_PIPE_PATH = "\\\\.\\pipe\\sync_trades_pipe";
bool isConnectionOpen = false;
const string NEW_LINE = "\n";
const string TAB = "\t";
double CumStoploss = 0;
double CumTarget = 0;
double CumSwap = 0;
int BuyCount = 0;
int BuyLimitCount = 0;
int BuyStopCount = 0;
int SellCount = 0;
int SellLimitCount = 0;
int SellStopCount = 0;
int HistoryTotal = 0;
string UnusedRecv = "";
bool PrintConnectionWaiting=true;
bool PrintEAIsStopped = true;
const string PING_PACKET = "ping=pong";
ulong ticketsOfSyncCopy [];
ulong ticketsOfSyncClose [];
ulong ticketsOfSyncModify [];
bool IsIntroRequired = true;
int RUN_INTERVAL = 200;
bool IsTimerRunning = false;
bool IsMarketClosed = false;
bool IsMarketJustOpen = false;
datetime lastKnownServerTime = 0;
int lastErrorCode = 0;
ulong ticketsOfPlacementOrder[];
double MyAccountBalance = 0;
double ExpectedHedgeProfit = 0;
double ExpectedHedgeProfitTomorrow = 0;
double AccountSwapPerDay = 0;
double AccountTradeCost = 0;
double AccountSwapCost = 0;
double AccountCommissionCost = 0;
bool WarnTickValueModified = false;
bool IsInitialSpreadFound = false;
int InitialSpreadTickCount = 0;
double ExitSpreadPoint = 0;
double PreSpreadPoint = 0;
long ExitSpreadLastTime = 0;
int NtTradeCount = 0;
double SpreadPointSum = 0;
int SpreadTickCount = 0;
bool Terminating = false;
bool IsTerminated = false;
double SpreadPoint = 0;
double LastAutoModifiedTarget = 0;
double PrevTickValue = 0;
double TickValueVariance = 0.00001;
double MAX_TICK_VALUES_VARIANCE = 0.001;
bool IsExitAtPeerStoplossEnabled = false;

CList *vSyncList = new CList;

double ExpectedExitProfit = 0; // profit if exit at peer stoploss
double ExpectedTargetProfit = 0;// profit if exit at main target
double ExpectedExitBalance = 0;// balance if exit at peer stoploss
double ExpectedTargetBalance = 0;// balance if exit at main target

string SyncStatePairID;

int lastPingTime = 0;
int PING_INTERVAL_IN_MINUTES = 15;

int MAX_ALLOW_TERMINAL_DISCONNECTED_MINUTE = 1; //TODO - configurable from the app gui

int WorkingPosition = -1;

string strRuning = "EA Running...";

int fialReadCount = 0;

bool debugPriceIsClosePrice = false;
int bugResolved = 0;

int PeerRealSymbolDigits = UNDEFINED; //We need this information to make sure both own and peer use the same symbol digit which ever is smaller

double PeerAccountMargin;
double PeerStopoutLevel;
double PeerAccountBalance;
double PeerAccountCredit;
double PeerTotalCommission;
double PeerTotalLotSize;
double PeerContractSize;
double PeerPosition;
double PeerBaseOpenPrice;
double PeerTotalSwap;
double PeerSafetySpread;

double TotalCommission = 0;
double TotalLotSize = 0;
double TotalSwap = 0;
string Position = "";

string SymbolForMarginReqirement = "";

datetime lastConnectionAvailsbleTime = 0;
bool isWillRestartTerminalSent = false;
bool isPrintAboutToRestart = false;

Printer buysltpPrinter;
Printer sellsltpPrinter;


CDialog dialog;
CListView lstPeerTicketsView;
CButton btn;
CLabel lblBalance;
CLabel labelBalance;
CLabel lblExpectedProfitRange;
CLabel labelExpectedProfitRange;
CLabel lblExpectedBalanceRange;
CLabel labelExpectedBalanceRange;

CLabel labelExitDescription;
CLabel lblSymbol;
CLabel lblPeerStoploss;
CLabel lblActualExit;
CLabel labelActualExit;
CLabel labelLessPeerSpread;

CLabel lblAlert;

CPanel panelTop;
CPanel panelCenter;
CPanel panelBottom;


//+------------------------------------------------------------------+
void computeStoploss()
{

     if(EnableManualStoplossAdjustion){
         return;
     }
     
     if(OrdersTotal() == 0){
         LastAutoModifiedTarget = 0;
         return;
     }
     
     double StopLossAtStopOut = 0;
     
     int total_orders = OrdersTotal();
     string symbol = "";
     double total_lots = 0; 
     double total_commission = 0;
     double total_swap = 0;
     double open_price = 0;
     for(int i = 0; i < total_orders; i++){
     
     
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
            return; //just leave - no room for error
        }
        
        if(i == 0){//just use the open price of the first order - that is the best we can do
         open_price = OrderOpenPrice();        
        }
        
        symbol = OrderSymbol();
        total_lots += OrderLots();
        total_commission += OrderCommission();
        total_swap += OrderSwap();
     
     }
     
     
     double BuyStopLossAtStopOut = determinePriceAtOwnStopout(OP_BUY, open_price, symbol, total_lots, total_commission, total_swap);
     double SellStopLossAtStopOut = determinePriceAtOwnStopout(OP_SELL, open_price, symbol, total_lots, total_commission, total_swap);
     
     if(BuyStopLossAtStopOut == open_price || SellStopLossAtStopOut == open_price){
         //This is possible in some symbols of certain broker e.g HK50 in Blueberry
         //where the symbol tick value is zero most of the time
         return;
     }
     
     
     for(int i = 0; i < total_orders; i++){
     
     
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
            return; //just leave - no room for error
        }                                        
        
        int SymbolDigits = ensureSameSymboDigitsWithPeer();
        
        if(SymbolDigits == UNDEFINED){
            return;
        }
                                 
        double order_lots = OrderLots();// chuks - added to avoid strange division by zero - see comment below 
                                 
        if(order_lots == 0)// chuks - added to avoid strange division by zero - see comment below 
        {
           return;
        }
                         
        /*@Deprecated - replace by if block below
         if(order_lots * 1000 < AccountBalance()/1000){
           return; //skip since the lot size is too small
        }*/
        
        if(order_lots < SymbolInfoDouble(OrderSymbol(), SYMBOL_VOLUME_MIN)){
            return; //skip since the lot size is too small
        }                         
                           
        if(((OrderType()==OP_BUY)))
        {      
           WorkingPosition =  OP_BUY;
           
          //NOTE: in the case of BUY position NO NEED TO compensate for exit spread since the exit price is at BID price
          //so we always expect the stoploss price to be hit. Note this is not the case for SELL side which can cause 
          //premature hunting of the stoploss price since the Ask price is hit which is before the actual stoploss
           StopLossAtStopOut = BuyStopLossAtStopOut;
           if(StopLossAtStopOut == 0){
               return;
           }    
           if(IsMarketJustOpen || NormalizeDouble(StopLossAtStopOut, SymbolDigits) !=  NormalizeDouble(OrderStopLoss(), SymbolDigits))
           {                 
              if(OrderModify(OrderTicket(),OrderOpenPrice(),StopLossAtStopOut,OrderTakeProfit(),0,0))
              {
                 sendData(stoplossPacket(StopLossAtStopOut));    
              }else{                    
                 string error = ErrorDescription(GetLastError());
                 if(error == "market is closed")
                 {
                    IsMarketClosed = true;
                 }                       
              }
           }   
        }
                                
        if(((OrderType()==OP_SELL)))
        {
            WorkingPosition =  OP_SELL;
            

           StopLossAtStopOut = SellStopLossAtStopOut;
           if(StopLossAtStopOut == 0){
               return;
           }
           
           if(IsMarketJustOpen || NormalizeDouble(StopLossAtStopOut, SymbolDigits) !=  NormalizeDouble(OrderStopLoss(), SymbolDigits))
           {                          
           
              if(OrderModify(OrderTicket(),OrderOpenPrice(), StopLossAtStopOut,OrderTakeProfit(),0,0))
              {
                 sendData(stoplossPacket(StopLossAtStopOut));       
              }else{                    
                 string error = ErrorDescription(GetLastError());
                 if(error == "market is closed")
                 {
                    IsMarketClosed = true;
                 }                       
              }
           }  
        }
        
     }  
     
        
     WriteComment(open_price, StopLossAtStopOut, symbol, total_lots, total_commission, total_swap); 
     
}

void computeTakeProfit(){

     TradePacket trade;
     
     int total_orders   = OrdersTotal();

     double safety_spread_point = PeerSafetySpread * Point(); 

     for(int i = 0; i < total_orders; i++){
     
     
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
            return; //just leave - no room for error
        }                                        
                
        trade.ticket = OrderTicket();
        trade.symbol = OrderSymbol();
        trade.signal_time = TimeCurrent(); //come back
                
        int SymbolDigits = ensureSameSymboDigitsWithPeer();
        
        if(SymbolDigits == UNDEFINED){
            return;
        }
        
        string data = "";

        if(PeerPosition == OP_BUY)
        {                     
           double TargetAtPeerStopOut = determinePriceAtPeerStopout() + safety_spread_point; 
           
//Print("PeerSafetySpread= ",PeerSafetySpread, " safety_spread_point= ",safety_spread_point);           
           
           if(NormalizeDouble(TargetAtPeerStopOut, SymbolDigits) !=  NormalizeDouble(OrderStopLoss(), SymbolDigits))
           {                 
              if(OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(), TargetAtPeerStopOut,0,0))
              {
                  trade.target = TargetAtPeerStopOut; 
                  LastAutoModifiedTarget = TargetAtPeerStopOut;                     
                  data += modifyTakeProfitSuccessPacket(true, trade);                                        
              }else{                    
                  string error = ErrorDescription(GetLastError());                   
                  data += modifyTakeProfitSuccessPacket(false, trade, error);   
              }
           }   
        }
                                
        if(PeerPosition == OP_SELL)
        {
           double TargetAtPeerStopOut = determinePriceAtPeerStopout() - safety_spread_point;                                            
           
           if(NormalizeDouble(TargetAtPeerStopOut, SymbolDigits) !=  NormalizeDouble(OrderStopLoss(), SymbolDigits))
           {                                     
              if(OrderModify(OrderTicket(),OrderOpenPrice(), OrderStopLoss(), TargetAtPeerStopOut,0,0))
              {
                  trade.target = TargetAtPeerStopOut;
                  LastAutoModifiedTarget = TargetAtPeerStopOut;                     
                  data += modifyTakeProfitSuccessPacket(true, trade);                      
                    
              }else{                    
                  string error = ErrorDescription(GetLastError());                   
                  data += modifyTakeProfitSuccessPacket(false, trade, error);   
              }
           }  
        }

        if(data != ""){
            sendData(data);
        }        
        
     }
     


}

//--------------------------------------------------------------------------------------------------
//Get the base open price. That is the position with mininum open price for BUY and maximum for SELL
//---------------------------------------------------------------------------------------------------
double baseOpenPrice(){
        
      int total_orders = OrdersTotal();
        
      //base open price is the lowest of the trade for BUY and the Highest for SELL
      double base_buy_open_price = INT_MIN; 
      double base_sell_open_price = INT_MAX; 
      for(int i = 0; i < total_orders; i++){
     
     
         if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
             return 0; //just leave - no room for error
         }
           
         if(OrderType() == OP_BUY){
             //get the maximum
             if(OrderOpenPrice() > base_buy_open_price){ 
                  base_buy_open_price = OrderOpenPrice();
             }
           
         }else if(OrderType() == OP_SELL){
             //get the mininum
             if(OrderOpenPrice() < base_sell_open_price){
                 base_sell_open_price = OrderOpenPrice();
             }           
         }else{
            return 0;
         }
        
      }
   

      if(OrderType() == OP_BUY){           
         return base_buy_open_price;  
      }else if(OrderType() == OP_SELL){
         return base_sell_open_price;   
      }else{
         return 0;
      }
}

//-------------------------------------------------------------------------
//Suppose there are more than one position that are of different
//open price, he function calculate the number of pips 
//away from the first position (the base open price)
//-------------------------------------------------------------------------
double pipsPointDriftPerLot(double base_open_price){

      double total_drift = 0;
      int total_orders = OrdersTotal();
      double total_lots = 0;
            
      for(int i = 0; i < total_orders; i++){
     
     
         if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
             return 0; //just leave - no room for error
         }
           
         total_drift += OrderLots() * MathAbs(OrderOpenPrice() - base_open_price);  
         total_lots += OrderLots();          
        
     }
     
     
     
     double drift_per_lot = total_drift / total_lots;
     
//Print("base_open_price ",base_open_price," total_drift ", total_drift, " total_orders ", total_orders," drift_per_lot ",drift_per_lot);     
         
     return drift_per_lot;
}


double getTotalLotSize(){


      int total_orders = OrdersTotal();
      double total_lots = 0;
            
      for(int i = 0; i < total_orders; i++){
     
     
         if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
             return 0; //just leave - no room for error
         }
           
         total_lots += OrderLots();          
        
     }
     
     return total_lots;
}


double determinePriceAtOwnStopout(double pos, double open_price, string symbol, double total_lots, double total_commission, double total_swap){    
    

   double contract_size = MarketInfo(symbol, MODE_LOTSIZE);

   double base_open_price = baseOpenPrice();
   
   return determineStopout( AccountBalance(),
                            AccountCredit(), 
                            total_commission,
                            total_swap,
                            AccountMargin(), 
                            AccountStopoutLevel(),
                            getTotalLotSize(),
                            contract_size,
                            pos,
                            base_open_price);
   
}


double determinePriceAtPeerStopout(){    

   double base_open_price = PeerBaseOpenPrice;
   
   if(!isRegularSymbol(Symbol())){
   
      base_open_price = baseOpenPrice();
      
      Print("IMPORTANT NOTICE: "+Symbol()+" is a non-regular pair so "+base_open_price
            +" as open price on this broker was used for take profit computation"
            +" since price system of similar non-reguar symbols on different"
            +" brokers may be vary greatly");
  
   }
   
   
   return determineStopout( PeerAccountBalance,
                            PeerAccountCredit, 
                            PeerTotalCommission,
                            PeerTotalSwap,
                            PeerAccountMargin, 
                            PeerStopoutLevel,
                            PeerTotalLotSize,
                            PeerContractSize,
                            PeerPosition,
                            base_open_price);
   
}

double determineStopout(double account_balance,
                         double account_credit, 
                         double total_commission,
                         double total_swap,
                         double account_margin, 
                         double stopout_level,
                         double total_lot_size,
                         double contract_size,
                         double position,
                         double base_open_price){
    
   if(isGBPJPY()){
      contract_size = contract_size/100;
      Print("IMPORTANT NOTICE: "+Symbol()+" contract size is divided by 100 for correct SL and TP");
   } 
    

   double A = account_margin * stopout_level/100;
   double B = account_balance + account_credit + total_commission + total_swap; 
   double C = MathAbs(B - A);//checking first
   double D = total_lot_size * contract_size;    
   double E = C / D;   
   
   
   double stoploss = 0;
               
   if(position == OP_BUY){
      stoploss = base_open_price - E;   
   }else if(position == OP_SELL){   
      stoploss = base_open_price + E;
   }   
  
  
   
   string strPos = position == OP_BUY ? "BUY": "SELL";
   
   if(strPos == "BUY"){
      buysltpPrinter.start(strPos);
      buysltpPrinter.print("-------------------------------------------------- ");
      buysltpPrinter.print(strPos + " -> A= " + A);
      buysltpPrinter.print(strPos +  " -> B= " + B);
      buysltpPrinter.print(strPos +  " -> C= " + C);
      buysltpPrinter.print(strPos +  " -> D= " + D);
      buysltpPrinter.print(strPos +  " -> E= " + E);
      buysltpPrinter.print(strPos + " -> base_open_price= " + base_open_price);
      buysltpPrinter.print(strPos + " -> stoploss= " + stoploss);
      buysltpPrinter.print("-------------------------------------------------- ");
      buysltpPrinter.end(strPos);
   }else{
      sellsltpPrinter.start(strPos);
      sellsltpPrinter.print("-------------------------------------------------- ");
      sellsltpPrinter.print(strPos + " -> A= " + A);
      sellsltpPrinter.print(strPos +  " -> B= " + B);
      sellsltpPrinter.print(strPos +  " -> C= " + C);
      sellsltpPrinter.print(strPos +  " -> D= " + D);
      sellsltpPrinter.print(strPos +  " -> E= " + E);
      sellsltpPrinter.print(strPos + " -> base_open_price= " + base_open_price);
      sellsltpPrinter.print(strPos + " -> stoploss= " + stoploss);
      sellsltpPrinter.print("-------------------------------------------------- ");
      sellsltpPrinter.end(strPos); 
   }
   
   return stoploss;   
}

bool isGBPJPY(){
   
   if(!isRegularSymbol(Symbol())){
      return false;
   }
   string symbol = Symbol();
   StringToUpper(symbol);
   
   if(StringFind(symbol, "GBPJPY") != -1 
   || StringFind(symbol, "GBP/JPY") != -1 ){
      return true;
   }


   return false;
}

int ensureSameSymboDigitsWithPeer(){

    int OwnSymbolDigits = (int)MarketInfo(Symbol(), MODE_DIGITS);
    
    if(PeerRealSymbolDigits == UNDEFINED){   
         return UNDEFINED;
    }else if(PeerRealSymbolDigits < OwnSymbolDigits){
         return PeerRealSymbolDigits; // using the smaller digit
    }else{
         return OwnSymbolDigits;
    }        

}

//@Deprecated
double determinePriceAtStopout_OLD(double pos, double open_price, string symbol, double total_lots, double total_commission, double total_swap){    

    
   //BORROW IDEA HERE  
      
   double margin =  AccountMargin();
   double stopout_margin = margin * AccountStopoutLevel() / 100;    
   double stopout_loss = AccountBalance() + AccountCredit() + total_commission + total_swap - stopout_margin;   
   double stopout_pip_move = ammountToPips(stopout_loss, total_lots, symbol);    
   double stopout_points_move = stopout_pip_move * getUsableSymbolPoint(symbol);
   
   
   double base_open_price = baseOpenPrice();
   
   double pips_point_drift_per_lot = pipsPointDriftPerLot(base_open_price);   

//Print("pips_point_drift_per_lot ", pips_point_drift_per_lot);
      
   double stoploss = 0;
   
   if(pos == OP_BUY){
      stoploss = base_open_price - stopout_points_move - pips_point_drift_per_lot;   
   }else if(pos == OP_SELL){   
      stoploss = base_open_price + stopout_points_move + pips_point_drift_per_lot;
   }
      
   
   return stoploss;
}

//@Deprecated
double determinePriceAtStopout_OLDER(double pos, double open_price, string symbol, double total_lots, double total_commission, double total_swap){
   double margin =  AccountMargin();
   double stopout_margin = margin * AccountStopoutLevel() / 100;    
   double stopout_loss = AccountBalance() + AccountCredit() + total_commission + total_swap - stopout_margin;   
   double stopout_pip_move = ammountToPips(stopout_loss, total_lots, symbol);    
   double stopout_points_move = stopout_pip_move * getUsableSymbolPoint(symbol);
   double stoploss = 0;
   
   if(pos == OP_BUY){
      stoploss = open_price - stopout_points_move;   
   }else if(pos == OP_SELL){   
      stoploss = open_price + stopout_points_move;
   }
      
   
   return stoploss;
}

double ammountToPips(double amount, double lots, string symbol){

   double syb_tick_value = symbolTickValue(symbol); // MAY NOT BE NEEDED HERE
                                                    // SEE HACK SOLUTION BELOW
   
   if(syb_tick_value == 0){
      //This is possible in some symbols of certain broker e.g HK50 in Blueberry
      return 0;
   }
   
   syb_tick_value = 1; //This is a just hack solution. 
                       //Since we are using getUsuableSymbolPoint
                       //where the Tick size is Divided by the tick value it is
                       //reasonable to set the tick value to 1 for all symbols in
                       //just the case 
  
   double contract_size = MarketInfo(symbol, MODE_LOTSIZE);
   double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);   
   double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   
   double multiplier = contract_size * tick_size;   

   return amount /(lots * multiplier);
}


double symbolTickValue(string symbol){
   double value = MarketInfo(symbol, MODE_TICKVALUE);
   
   //NOTE: Because of a weird observation where the Tick Value changes very slightly
   //but approximately the same leading to unnecessary computation of Stoploss
   //and resulting in frequent triggering of stoploss_changed events we will simply return the
   //the last known tick value if the difference with the current tick value is negligibe
   //such as 0.00001
   
  
   
   double diff = MathAbs(value - PrevTickValue);
   
   if(PrevTickValue > 0 && diff <= TickValueVariance){   
      value = PrevTickValue;
   }else if(PrevTickValue > 0 && TickValueVariance < MAX_TICK_VALUES_VARIANCE){
      
      double prevTickValueVar = TickValueVariance;
      TickValueVariance *= 10;      
      
      PrintFormat("INCREASE TICK VALUES VARIANCE FROM %f to %f TO PREVENT FREQUENT STOPLOSS CHANGES", prevTickValueVar, TickValueVariance);
            
      
      if(diff <= TickValueVariance){
         value = PrevTickValue;       
      }                       
   }else if(PrevTickValue > 0){
      PrintFormat("ATTENTON NEEDED!!! RISK OF TOO FREQUENT STOPLOSS CHANGES DUE TO LARGE TICK VALUES VARIANCE WHICH MAY OVERWHELM BROKER SERVER. PLEASE REVIEW CODE!");      
      PrintFormat("CODE REVIEW NECESSARY. CONSIDER INCREASING THE TICK VALUES VARIANCES IF POSSIBLE OR NECCESSARY");      
   }
   
   PrevTickValue = value;
   
   /* //@Deprecated - causes problem for NAS100 - stoploss is incorrect
   if(value <= 0.1){
      value *= 10;
      if(!WarnTickValueModified){
         string WarningMsg = StringFormat("WARNING!!! EA has modified Ticket value of %s from %f to %f as what it expects it to be. Please verify correctness for yourself.", symbol ,value/10.0, value);
         lblAlert.Text(WarningMsg);
         Print(WarningMsg);
         WarnTickValueModified = true;
      }
   }
   */
   return value;
}

void WriteComment(double open_price, double stop_loss, string symbol, double total_lots, double total_commission, double total_swap){

     double symbol_point = getUsableSymbolPoint(symbol);

     Comment("MARGIN: ",AccountMargin(),
             "\nSTOPOUT: ",AccountStopoutLevel(),
             "\nLEVERAGE: ",AccountLeverage(),
             "\nACCOUNT BALANCE: ",AccountBalance(),
             "\nCREDIT VALUE:",AccountCredit(),
             "\nTOTAL SWAP: ",total_swap,
             "\nTICK VALUE: ",symbolTickValue(symbol),
             "\nSPREAD: ",MarketInfo(symbol,MODE_SPREAD),
             "\nUSING EXIT SPREAD: ",(int)(ExitSpreadPoint/symbol_point),
             "\nTOTAL LOT SIZE: ",total_lots,
             "\nTOTAL COMMISSION: ",total_commission,
             "\nFIRST ORDER OPEN PRICE: ",open_price,                                                     
             "\nORDER STOPLOSS: ", stop_loss);
             
}

string stoplossPacket(double stoploss)
{
          
  double symbol_point = getUsableSymbolPoint(OrderSymbol());   
                        
   return "ticket="+OrderTicket()+TAB
         + "stoploss_change_time="+(long)TimeCurrent()+TAB 
         + "stoploss_changed=true"+TAB           
         + "point="+symbol_point +TAB
         + "digits="+SymbolInfoInteger(OrderSymbol(), SYMBOL_DIGITS) +TAB
         + "stoploss="+stoploss+TAB;   
                      
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {    
      
      if(!IsExpertEnabled()){
         MessageBox("Failed to start EA becacuse it is not yet enabled!\n\nHint: Click on Auto Trading on client terminal", "FAILED", MB_ICONERROR);   
         return INIT_FAILED;
      }
      
      if(!IsDllsAllowed()){
         MessageBox("This EA uses DLL but DLL is not yet enabled!\n\nHint: Click on 'Allow DLL imports' on Expert Properties dialog", "FAILED", MB_ICONERROR);   
         return INIT_FAILED;
      }
   
      if(!IsTradeAllowed()){
         MessageBox("Live trading is not enabled. Please enable Allow Live Trading!\n\nHint: Ensure Allow Live Trading checkbox is checked on EA properties dialog!", "FAILED", MB_ICONERROR);   
         return INIT_FAILED;
      }
   
      if(exitClearanceFactor == _0_PERCENT){
         EXIT_CLEARANCE_FACTOR = 0;
      }else if(exitClearanceFactor == _30_PERCENT){
         EXIT_CLEARANCE_FACTOR = 0.3;
      }else if(exitClearanceFactor == _50_PERCENT){
         EXIT_CLEARANCE_FACTOR = 0.5;
      }else if(exitClearanceFactor == _80_PERCENT){
         EXIT_CLEARANCE_FACTOR = 0.8;
      }else if(exitClearanceFactor == _100_PERCENT){
         EXIT_CLEARANCE_FACTOR = 1;
      }
   
      MyAccountBalance = AccountBalance();
   
      //--- create timer
      RunTimerIfNot();
      
      //clear previous comments
      Comment("");
      
      if(SyncCopyManualEntry){
         MessageBox("You have chosen to sync copy manual entries.\nMake sure the pairing EA is also set to do the same otherwise manual entries will not sync copy.","ATTENTION!!!", MB_ICONEXCLAMATION);   
      }
      
      creatGUI();
      
      
      if(!validateExchangeRateSymbol()){
         MessageBox("Failed to start EA becacuse "+SymbolForMarginReqirement+" price which is required internally could not be determined. Kindly ensure a chart of "+SymbolForMarginReqirement+" is currently loaded on the trading platform!", "FAILED", MB_ICONERROR);   
         return INIT_FAILED;         
      }
      
      return (INIT_SUCCEEDED);
   }
   
   
  bool validateExchangeRateSymbol(){
           
       
         if(!isRegularSymbol(Symbol())){
            SymbolForMarginReqirement = Symbol();
            return iClose(SymbolForMarginReqirement,0,0) != 0;
         }
         
         string symbol = Symbol();
         int len = StringLen(symbol);
         
         int prefix_index = -1;
         int suffix_index = -1;
         bool has_slash = false;
         int prefix_count = 0;
         
         for( int i=0; i < len; i++){
            
            ushort c = StringGetChar(symbol, i);
            
            if(c == '/'){
               has_slash = true;
            }
                        
            
            if(c == '.' && prefix_index == -1){
               prefix_index = i;
               prefix_count++;
            }else if(c == '.' && prefix_index != -1){
               suffix_index = i;
               prefix_count++;
            }            
            
         }
         
         if(prefix_count == 1 && prefix_index >=6){
            suffix_index = prefix_index;
            prefix_index = -1;
         }
         
         int base_currency_index = prefix_index + 1;
         int quote_currency_index = base_currency_index + 3;
         
         if(has_slash){
            quote_currency_index++;
         }
         
         string base_currency =  StringSubstr(symbol, base_currency_index, 3);
         string quote_currency =  StringSubstr(symbol, quote_currency_index, 3);
         
         
         string up_case_base_currency = base_currency;
         StringToUpper(up_case_base_currency);
         
         if(up_case_base_currency == AccountCurrency()){
            //e.g USDJPY if Account currency is USD
            SymbolForMarginReqirement = Symbol();
            return iClose(SymbolForMarginReqirement,0,0) != 0;         
         }
         
         //At this point the base currency is not the AccountCurrency() usually USD
         
         //Now replace the quote currency with the Account Currency 
         char symbol_arr[];        
         StringToCharArray(symbol, symbol_arr);
         
         char quote_currency_arr[];        
         StringToCharArray(AccountCurrency(), quote_currency_arr);
                  
         for( int i = 0; i< 3; i++){
            symbol_arr[i + quote_currency_index] = quote_currency_arr[i];
         }
         
         symbol = CharArrayToString(symbol_arr);
         
         SymbolForMarginReqirement = symbol;
         if(iClose(symbol,0,0) != 0){
            return true;
         }
         
         //lets try symbols without prefix
         int start_index = prefix_index + 1;
         int end_index = has_slash ? 7 : 6;
         symbol =  StringSubstr(symbol, start_index, end_index);
         
         
         SymbolForMarginReqirement = symbol;
         if(iClose(symbol,0,0) != 0){            
            return true;
         }
         
           
     return false;       
  }

  
 void startUpEA(string init_msg = NULL){
   
   //string init_msg = "Initializing EA...";
   
   if(init_msg != NULL)
   {
      Print(init_msg);
      lblAlert.Text(init_msg);
   }
   
   //initControlVariables(); NO NEED
     
   HistoryTotal = OrdersHistoryTotal();
   
   sendIntro();
   sendDataAttrForSyncStateID();
   sendSyncOrdersData();
   
 }
 
 void sendIntro(){

   string ea_executable_file = StringSubstr( __PATH__, 0, StringLen(__PATH__) -3) + "ex"+ StringSubstr( __PATH__, StringLen(__PATH__) -1); 
                  
   string data =  "intro=true"+TAB
                  +"version="+VERSION+TAB   
                  +"is_live_account="+!IsDemo()+TAB
                  +"broker="+AccountCompany()+TAB
                  +"account_number="+AccountNumber()+TAB
                  +"account_name="+AccountName()+TAB
                  +"terminal_path="+TerminalPath()+TAB                                                                                                          
                  +"platform_type="+getPlatformType()+TAB                                 
                  +"sync_copy_manual_entry="+SyncCopyManualEntry+TAB  
                  +"ea_executable_file="+ea_executable_file+TAB
                  +accountInfoPacket();
   
   sendTradeData(data);
   IsIntroRequired = false;
 
 }


void OnChartEvent(const int id,         // Event ID 
                  const long& lparam,   // Parameter of type long event 
                  const double& dparam, // Parameter of type double event 
                  const string& sparam  // Parameter of type string events 
  ){

   if(id == CHARTEVENT_OBJECT_CLICK){
      
      if(StringFind(sparam, "lstPeerTicketsView"+"Item") == 0){
         int len = StringLen("lstPeerTicketsView"+"Item");
         int selecteItemIndex = (int)StringToInteger(StringSubstr(sparam, len));
         lstPeerTicketsView.Select(selecteItemIndex);
         
         updatePeerStoplossLabelsUI(lstPeerTicketsView.Select());
         
      }
      
   }

   
}

 void updatePeerStoplossLabelsUI(string selectedPeerTicket){
 
      int symb_digit = SymbolInfoInteger(Symbol(), SYMBOL_DIGITS); 
 
      for(int i = 0; i < vSyncList.Total(); i++){
         
         VirtualSync *vSync = vSyncList.GetNodeAtIndex(i);
         
         if(vSync.peer_ticket == selectedPeerTicket){                         
            
            lblPeerStoploss.Text(NormalizeDouble(vSync.peer_stoploss, symb_digit));
            
            double clearance = exitClearance(vSync);
            
            int cpercent = EXIT_CLEARANCE_FACTOR*100;
            int spread = (int)(vSync.peer_spread_point / getUsableSymbolPoint(OrderSymbol()));
            string str_less_peer_spread = "( Less "+EXIT_CLEARANCE_FACTOR*100
                                          +"% peer spread of "+spread+" )";
            
            if(WorkingPosition == OP_BUY){
               lblActualExit.Text(NormalizeDouble(vSync.peer_stoploss - clearance, symb_digit));
               labelActualExit.Text("Exit at Bid >=");               
               
            }else if(WorkingPosition == OP_SELL){
               lblActualExit.Text(NormalizeDouble(vSync.peer_stoploss + clearance, symb_digit));
               labelActualExit.Text("Exit at Ask <=");
            }
            
            labelLessPeerSpread.Text(str_less_peer_spread);
            
            break;
         }
      
      }
 }

 void creatGUI(){
             
 
      dialog.Create(0,"DlgSyncTradeClient",0,500,150,0,0);
      dialog.Width(850);
      dialog.Height(500); 
      dialog.Caption("SyncTradeClient");   
               
      
      panelTop.Create(0,"panelTop",0,10,10,0, 0);
      panelTop.Width(dialog.Width() - 30);
      panelTop.Height(170);
      panelTop.ColorBackground(clrWhiteSmoke);
      panelTop.BorderType(BORDER_RAISED);
      
      
      
      panelCenter.Create(0,"panelCenter",0,10,190,0, 0);
      panelCenter.Width(dialog.Width() - 30);
      panelCenter.Height(170);
      panelCenter.ColorBackground(clrWhiteSmoke);
      panelCenter.BorderType(BORDER_RAISED);
      
      
      panelBottom.Create(0,"panelBottom",0,10,370,0, 0);
      panelBottom.Width(dialog.Width() - 30);
      panelBottom.Height(100);
      panelBottom.ColorBackground(clrWhiteSmoke);
      panelBottom.BorderType(BORDER_RAISED);
      
      
      
      
      
      labelBalance.Create(0,"labelBalance",0,dialog.Width() - 490, 20, 0, 0);
      labelBalance.Width(200);
      labelBalance.Height(30);
      labelBalance.Text("Account Balance: ");
      
      
      lblBalance.Create(0,"lblBalance",0,dialog.Width() - 260, 20, 0, 0);
      lblBalance.Width(200);
      lblBalance.Height(30);
      lblBalance.Text(DoubleToString(NormalizeDouble((float)AccountBalance(), 2),2)+ " "+AccountCurrency());
      
                  
  
      
      labelExpectedProfitRange.Create(0,"labelExpectedProfitRange",0,40, 80, 0, 0);
      labelExpectedProfitRange.Width(150);
      labelExpectedProfitRange.Height(30);
      labelExpectedProfitRange.Text("Profit Range: ");
      
      
      lblExpectedProfitRange.Create(0,"lblExpectedProfitRange",0,250, 80, 0, 0);
      lblExpectedProfitRange.Width(250);
      lblExpectedProfitRange.Height(30);
      lblExpectedProfitRange.FontSize(12);
      lblExpectedProfitRange.Color(clrBlue);
      lblExpectedProfitRange.Text(NormalizeDouble(ExpectedExitProfit, 2)
      + " " + AccountCurrency()
      + " to " + NormalizeDouble(ExpectedTargetProfit, 2)
      + " " + AccountCurrency());  
  
  
      
      labelExpectedBalanceRange.Create(0,"labelExpectedBalanceRange",0,40, 130, 0, 0);
      labelExpectedBalanceRange.Width(150);
      labelExpectedBalanceRange.Height(30);
      labelExpectedBalanceRange.Text("Balance Range: ");
      
      
      lblExpectedBalanceRange.Create(0,"lblExpectedBalanceRange",0,250, 130, 0, 0);
      lblExpectedBalanceRange.Width(250);
      lblExpectedBalanceRange.Height(30);
      lblExpectedBalanceRange.FontSize(12);
      lblExpectedBalanceRange.Color(clrGreen);      
      lblExpectedBalanceRange.Text(NormalizeDouble(ExpectedExitBalance, 2)
      + " " + AccountCurrency() 
      + " to " + NormalizeDouble(ExpectedTargetBalance, 2) 
      + " " + AccountCurrency());


  
      lstPeerTicketsView.Create(0,"lstPeerTicketsView",0,40, 250, 0, 300);
      lstPeerTicketsView.Width(150);
      lstPeerTicketsView.Height(100);
      lstPeerTicketsView.VScrolled(true);
      lstPeerTicketsView.BorderType(BORDER_SUNKEN);            
      lstPeerTicketsView.ColorBackground(clrWheat);
      
      
      
      labelExitDescription.Create(0,"labelExitDescription",0,40, 200, 0, 0);
      labelExitDescription.Width(800);
      labelExitDescription.Height(30);
      //labelExitDescription.Font("");
      labelExitDescription.Text("Attempts to exit trade as price nears or hits peer stoploss");      

      lblSymbol.Create(0,"lblSymbol",0,240, 250, 0, 0);
      lblSymbol.Width(120);
      lblSymbol.Height(30);
      lblSymbol.Text(Symbol()); 
 
      lblPeerStoploss.Create(0,"lblPeerStoploss",0,400, 250, 0, 0);
      lblPeerStoploss.Width(250);
      lblPeerStoploss.Height(40);
      lblPeerStoploss.FontSize(16);
      lblPeerStoploss.Color(clrBrown);
      //lblPeerStoploss.Text(1874.3);
  
  

      labelActualExit.Create(0,"labelActualExit",0,220, 320, 0, 0);
      labelActualExit.Width(120);
      labelActualExit.Height(30);
      //labelActualExit.Text("Exit at >="); 
 
      lblActualExit.Create(0,"lblActualExit",0,400, 320, 0, 0);
      lblActualExit.Width(250);
      lblActualExit.Height(40);
      lblActualExit.FontSize(10);
      lblActualExit.Color(clrRed);
      //lblActualExit.Text(1854.3);
  
  
  
      labelLessPeerSpread.Create(0,"labelLessPeerSpread",0,520, 325, 0, 0);
      labelLessPeerSpread.Width(250);
      labelLessPeerSpread.Height(40);
      labelLessPeerSpread.FontSize(8);
      //labelLessPeerSpread.Text("( Less 100% peer spread of 200 )");
  
      
      lblAlert.Create(0,"lblAlert",0,40, 400, 0, 0);
      lblAlert.Width(800);
      lblAlert.Height(30);
      //lblAlert.Font("");
      //lblAlert.Text("Alert Message");      

           
      dialog.Add(panelTop);  
      dialog.Add(panelCenter);  
      dialog.Add(panelBottom);           
      dialog.Add(labelBalance);
      dialog.Add(lblBalance);
      dialog.Add(labelExpectedProfitRange);
      dialog.Add(lblExpectedProfitRange);
      dialog.Add(labelExpectedBalanceRange);
      dialog.Add(lblExpectedBalanceRange);
      dialog.Add(lblPeerStoploss);
      dialog.Add(lblSymbol);
      dialog.Add(labelExitDescription);
      dialog.Add(lstPeerTicketsView);
      dialog.Add(lblActualExit);
      dialog.Add(labelActualExit);
      dialog.Add(labelLessPeerSpread);
      dialog.Add(lblAlert);
      
      
      dialog.Show();      
     
 }
 
 string getPlatformType(){
 
    int len = StringLen(__FILE__);
    string ext = StringSubstr(__FILE__,len -3);
    if(ext == "mq4"){
      return "mt4";
    }else if(ext == "mq5"){
      return "mt5";
    }  
    
    return "";
 }
 
 void RunTimerIfNot(){
       if(!IsTimerRunning){
         if(EventSetMillisecondTimer(RUN_INTERVAL))
         {
            IsTimerRunning = true;
            Print("Timer set succesfully...");
         }
      }
 }
 
 void initControlVariables(){
 
       CumStoploss = 0;  
       CumTarget = 0;
       CumSwap = 0;
       BuyCount = 0;
       BuyLimitCount = 0;
       BuyStopCount = 0;
       SellCount = 0;
       SellLimitCount = 0;
       SellStopCount = 0;
       HistoryTotal = 0;
       UnusedRecv = "";
       clearTicketsOfSyncCopy();
       clearTicketsOfSyncClose();
       clearTicketsOfSyncModify();
       clearTicketsOfPlacementOrder();
       PrintEAIsStopped = true;       
       IsInitialSpreadFound = false;
       InitialSpreadTickCount = 0;
       ExitSpreadPoint = 0;
       PreSpreadPoint = 0;
       ExitSpreadLastTime = 0;
       NtTradeCount = 0;  
       SpreadPointSum = 0;
       SpreadTickCount = 0;
       SpreadPoint = 0;
       LastAutoModifiedTarget = 0;
       PeerRealSymbolDigits = 0;
 }
 
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  
      //Close the communication channel 
      CloseSocket();    
      
      //destroy timer
      EventKillTimer();   
      
      delete vSyncList;      
      
      lstPeerTicketsView.ItemsClear();
      
      dialog.Destroy();
            
      if(reason > 1){
         ExpertRemove();//Prevent Reinitialization of this EA
         string attentMsg = "ATTENTION!!! SyncTradeClient has been removed";
         
         switch(reason){
            case REASON_CHARTCHANGE:
               attentMsg +=" because the symbol or chart has changed";
               break;
            case REASON_RECOMPILE:
               attentMsg +=" because the EA has been recompiled";
               break;
            case REASON_CHARTCLOSE:
               attentMsg +=" because the chart has closed";
               break;
            case REASON_PARAMETERS:
               attentMsg +=" because the input parameters was changed by the user";
               break;
            case REASON_ACCOUNT:
               attentMsg +=" because another account has been activated or reconnection to the trade server has occurred due to changes in the account settings";
               break;
            case REASON_TEMPLATE:
               attentMsg +=" because a new template has been applied";
               break;
            case REASON_INITFAILED:
               attentMsg +=" because the EA failed to initialize";
               break;
            case REASON_CLOSE:
               attentMsg +=" because the Terminal has been closed";
               break;
         }            
         Alert(attentMsg);                  
      }
   
   
   
   
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

      if(IsMarketClosed){
         IsMarketJustOpen = true;
      }

      IsMarketClosed = false;
      
      RunTimerIfNot();
      
      isConnectionOpen = IsSocketConnected();
 
      if(isConnectionOpen == false){
         isWillRestartTerminalSent = false;
         isPrintAboutToRestart = false;
         return;
      }
  
      
      computeStoploss();     
      
      checkPeerStoplossHit();
      
      sendAccountInfo();
      
      doRun();      
      
      IsMarketJustOpen = false; 
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {   
      doRun();      
  }


void Terminate(string msg=NULL){
      if(IsTerminated){
         return;
      }
      
      CloseSocket();
      
      if(msg!=NULL){
         PlaySound("alert.wav"); 
         MessageBox(msg);  
      }
      
      ExpertRemove();
      IsTerminated = true;      
}

/*
datetime simulate_time = TimeLocal();

bool SimulateIsConnected()
{
   

   ulong elapse = (ulong)(TimeLocal() - simulate_time);
   
      //Print(elapse);
      
      if(elapse > 2 * 60){      
         return false;
      }
      
      if(elapse > 1 * 60 && elapse < 1 * 60 + 3){
         Print("Connection Lost");
      }

   return true;
}
*/


void resartTerminalOnConnectionLost(){
   
   if(!IsConnected()){
      if(lastConnectionAvailsbleTime == 0)
      {
         return;
      }      
      
      ulong elapse = (ulong)(TimeLocal() - lastConnectionAvailsbleTime);
      
      ulong max_time = MAX_ALLOW_TERMINAL_DISCONNECTED_MINUTE * 60;
      
      ulong half_time = max_time /2;
      
      if(!isPrintAboutToRestart 
         &&  max_time > 10 
         && elapse > half_time){
         string msg = StringFormat("Connection lost detected! Possibly terminal Is Outdated. Will restart terminal in about %d seconds if the connection is not restored.", half_time);
         Print(msg);   
         Alert(msg);
         isPrintAboutToRestart = true;
      } 
      
      
      if(!isWillRestartTerminalSent && elapse > max_time){                     
         string data= "will_restart_due_to_connection_lost="+TerminalPath()+TAB;
         sendData(data);
         isWillRestartTerminalSent = true;
      }
      
   
   }else{
      lastConnectionAvailsbleTime = TimeLocal();
   }

}


void doRun(){
      
     resartTerminalOnConnectionLost();
      
     if(OrdersTotal() == 0){
         //initControlVariables(); //bug
     }
      
      double startTime = GetTickCount();
      
      if(Terminating){
         Terminate();
         return;
      }
      
      
      lastKnownServerTime = TimeCurrent();
      
      if(TimeCurrent() > lastKnownServerTime){
         IsMarketClosed = false;
      }
      
      int error_code = GetLastError();
      
      if(lastErrorCode != error_code){
         lastErrorCode = error_code;
         if(lastErrorCode == 132){
         
            IsMarketClosed = true;
         }
      }
      
      
      
      if(!channelIfNot()){
         return;
      }
      
     
      validateConnection();
      
      if(IsIntroRequired){
         if(StringLen(AccountCompany()) > 0){
            sendIntro();
         }      
      }
      
      sendPlaceOrderData();
            
      handleAccountBalanceChanged();
            
      ChangeStats stats;
            
      if(isOrderTradeStatusChange(stats))
      {
        if(stats.TradeCountChanged)
        {
         trimVirtualSyncList();
         TradeAnalyze();
         sendTradeData();
         sendDataAttrForSyncStateID();         
        }
        
        /*if(stats.TradeCountIncreased)
        {
            sendPeerTakeProfitParam();
        }*/        
        
        if(stats.TradeModified)
        {
         TradeAnalyze();
         
         restoreTarget();//new
         
         //sendTradeModifyData();  @Deprecated and removed 
        }
        
        if(stats.TradeSwapChanged)
        {Print("stats.TradeSwapChanged");
            sendPeerTakeProfitParam();   
        }
        
      }            
      
      handleNotifications();
      
      handleReceived(receiveData());
      
      //--- Get the spent time in milliseconds
      uint elapse=GetTickCount() - startTime;

      //Print("Benchmark: elapse = ", elapse, " milliseconds");
}

bool channelIfNot(){
      
      
      if(IsSocketConnected() == false){                  
         
         if(!openConnection()){
            return false;
         }
         
         startUpEA();
         
         if(isConnectionOpen){
            lblAlert.Text(strRuning);
         }
      }
 

   return true;
}

void handleNotifications(){

 
   int last_trade_count = NtTradeCount;   
   NtTradeCount = OrdersTotal();
   
   if(NtTradeCount == 0 && last_trade_count > 0){   
      SendNotification(StringFormat("TRADE CLOSED\nBal: %s %s", DoubleToStr(AccountBalance(), 2), AccountCurrency()));
      
   }
   
   
}

void sendUnpairedNotification(TradePacket &trade){
   SendNotification(StringFormat("UNPAIRED DETECTED - Peer [%s, %s]", trade.peer_broker, trade.peer_account_number));
}


void sendEADisconnectionNotification(){
   SendNotification("ATTENTION!!! EA Disconnected from pipe server. Waiting...");
}


void reestablishedPairingNotification(){
   SendNotification("PAIRING RE-ESTABLISHED SUCCESSFULLY AFTER TERMINAL RESTART");
}  


void restartedTerminalNotification(){
   SendNotification("TERMINAL HAS BEEN RESTARTED AND RESTORED BACK ONLINE AFTER OFFLINE DETECTION");
}  
  
void peerTerminalToRestartNotification(TradePacket &trade){
   SendNotification(StringFormat("PEER OFFLINE DETECTED - Peer [%s, %s]\n\n Peer terminal will restart", trade.peer_broker, trade.peer_account_number));
}   

void peerTerminalToRestartConfirmNotification(TradePacket &trade){
   SendNotification(StringFormat("PEER OFFLINE DETECTED \n\n ATTENTION NEEDED \n\n Peer [%s, %s]\n\n Peer terminal needs restart", trade.peer_broker, trade.peer_account_number));
}   


void reportPeerTerminalToRestartFailed(TradePacket &trade){
   string report = StringFormat("FAILED - ATTENTION NEEDED: Could not restart peer terminal after offline detection: Peer [%s, %s]", trade.peer_broker, trade.peer_account_number);
   SendNotification(report);
   Alert(report);
   Print(report);
}   


//------------------------------------------------------
//Remove virtual sync objects representing closed trades
//------------------------------------------------------
void trimVirtualSyncList(){

         
      for(int i = 0; i < vSyncList.Total(); i++){
            
          VirtualSync *vSync = vSyncList.GetNodeAtIndex(i);
          if(OrderSelect(vSync.own_ticket, SELECT_BY_TICKET))
          {
          
            if(!OrderCloseTime()){
              continue; // skip since we only need closed orders
            }
            
            //At this point the order is closed
            
            //Print("for i = ", i);
            //Print("About to deleted vSync.own_ticket ", vSync.own_ticket);
            //Print("Before deleted vSyncList.Total() ", vSyncList.Total());
                          
             vSyncList.Delete(i); //delete from sync list
             
             lstPeerTicketsView.ItemDelete(i); //alse delete from GUI list view
             
             i--;
             
             
             //Print("Deleted vSync.own_ticket", vSync.own_ticket);
             //Print("After deleted vSyncList.Total() ", vSyncList.Total());
             
             continue;
          }
            
      }
         
         
         

}

void TradeAnalyze(){

      int total = OrdersTotal();
     
      AccountSwapCost = 0;
      AccountCommissionCost = 0;
      AccountSwapPerDay = 0;
      AccountTradeCost = 0;
      ExpectedHedgeProfit = 0;
      for(int i=0; i < total; i++)
         {
         
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
            
                  AccountTradeCost += OrderCommission() + OrderSwap();
                  
                  if(OrderType() == OP_BUY){
                     AccountSwapPerDay += MarketInfo(OrderSymbol(), MODE_SWAPLONG);                        
                  }
                  
                  if(OrderType() == OP_SELL){
                     AccountSwapPerDay += MarketInfo(OrderSymbol(), MODE_SWAPSHORT);
                  }
                  
                  AccountSwapCost += OrderSwap();
                  AccountCommissionCost += OrderCommission();
                  
                  //calculate entry spread - I AM ASSUMING THIS CALCULATION IS CORRECT - come back to confirm correctness
                  /*
                  // IT HAS BEEN CONFIRMED THAT SPREAD COST CANNOT BE DETERMINED THIS WAY
                  double pip_move = MathAbs(OrderOpenPrice() - OrderClosePrice())/getUsableSymbolPoint(OrderSymbol()); 
                  double profit = pip_move * OrderLots() * symbolTickValue(OrderSymbol()) * 10;
                  double entry_spread_cost = profit - (OrderProfit() - OrderCommission() - OrderSwap());
                  */
                  
                  //UNCOMMENT THE LINE BELOW IF THE ABOVE CALCULATION IS NOT CORRECT. 
                  //LETS MANAGE THE FAIRLY ACCURATE ONE BELOW WHICH DOES ONLY GIVE 
                  //THE CURRENT MARKET SPREAD OF THE SYMBOL AND NOT ITS ENTRY SPREAD
                  
                  double current_spread_pips = MathAbs(MarketInfo(OrderSymbol(), MODE_ASK) - MarketInfo(OrderSymbol(), MODE_BID))/getUsableSymbolPoint(OrderSymbol()); 
                  double entry_spread_cost = current_spread_pips * OrderLots() * MarketInfo(OrderSymbol(), MODE_TICKVALUE);
                  
                  AccountTradeCost -= entry_spread_cost;             
                  
                  double pip_win = MathAbs(OrderOpenPrice() - OrderTakeProfit())/getUsableSymbolPoint(OrderSymbol());
                  double target_profit = pip_win * OrderLots() * symbolTickValue(OrderSymbol());
                  ExpectedHedgeProfit = target_profit;
                  
            }
            
            
        }  
}


string accountInfoPacket(){

      return "account_balance="+AccountBalance()+TAB
            +"account_equity="+AccountEquity()+TAB
            +"account_credit="+AccountCredit()+TAB
            +"account_currency="+AccountCurrency()+TAB
            +"account_leverage="+AccountLeverage()+TAB
            +"account_margin="+AccountMargin()+TAB
            +"account_stopout_level="+AccountStopoutLevel()+TAB
            +"account_profit="+AccountProfit()+TAB
            +"account_free_margin="+AccountFreeMargin()+TAB
            +"account_swap_per_day="+AccountSwapPerDay+TAB
            +"account_swap_cost="+AccountSwapCost+TAB
            +"account_commission_cost="+AccountCommissionCost+TAB
            +"account_trade_cost="+AccountTradeCost+TAB
            +"chart_symbol="+Symbol()+TAB      
            +"total_open_orders="+OrdersTotal()+TAB       
            +"chart_symbol_digits="+SymbolInfoInteger(Symbol(), SYMBOL_DIGITS)+TAB
            +"chart_symbol_max_lot_size="+SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)+TAB
            +"chart_symbol_min_lot_size="+SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)+TAB
            +"chart_symbol_tick_value="+symbolTickValue(Symbol())+TAB
            +"chart_symbol_tick_size="+SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE)+TAB            
            +"chart_symbol_swap_long="+SymbolInfoDouble(Symbol(), SYMBOL_SWAP_LONG)+TAB 
            +"chart_symbol_swap_short="+SymbolInfoDouble(Symbol(), SYMBOL_SWAP_SHORT)+TAB 
            +"chart_symbol_spread="+SymbolInfoInteger(Symbol(), SYMBOL_SPREAD)+TAB                   
            +"chart_symbol_trade_units="+SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE)+TAB
            +"chart_market_price="+Close[0]+TAB  
            +"exchange_rate_for_margin_requirement="+iClose(SymbolForMarginReqirement,0,0)+TAB          
            +"expected_exit_profit="+ExpectedExitProfit+TAB
            +"expected_target_profit="+ExpectedTargetProfit+TAB
            +"expected_exit_balance="+ExpectedExitBalance+TAB
            +"expected_target_balance="+ExpectedTargetBalance+TAB
            +"terminal_connected="+IsConnected()+TAB
            +"only_trade_with_credit="+(OnlyTradeWithCredit?"true":"false")+TAB
            +"chart_symbol_trade_allowed="+(MarketInfo(Symbol(), MODE_TRADEALLOWED)? "true":"false")+TAB
            +"sync_state_pair_id="+SyncStatePairID+TAB;
            

}


void sendAccountInfo(){
      sendData(accountInfoPacket());
}

void sendPeerTakeProfitParam(){

           
     AccountInfoUsedByPeer();                  
               
     string data ="account_margin="+AccountMargin()+TAB                  
                  +"stopout_level="+AccountStopoutLevel()+TAB   
                  +"account_balance="+AccountBalance()+TAB  
                  +"account_credit="+AccountCredit()+TAB  
                  +"total_commission="+TotalCommission+TAB  
                  +"total_swap="+TotalSwap+TAB
                  +"total_lot_size="+TotalLotSize+TAB
                  +"total_open_orders="+OrdersTotal()+TAB                 
                  +"contract_size="+MarketInfo(Symbol(), MODE_LOTSIZE)+TAB
                  +"position="+Position+TAB    
                  +"base_open_price="+baseOpenPrice()+TAB                 
                  +"peer_take_profit_param=true"+TAB;
            

   sendData(data);
}

void handleAccountBalanceChanged(){

      if(MyAccountBalance == AccountBalance()){
         return;
      }
      
      MyAccountBalance = AccountBalance();
      
      string data = "account_balance="+MyAccountBalance+TAB
                   +"account_balance_changed=true"+TAB;

      sendData(data);
      
      lblBalance.Text(DoubleToString(NormalizeDouble((float)AccountBalance(), 2),2)+ " "+AccountCurrency());
}

double getUsableSymbolPoint(string symbol){

     double _point = MarketInfo(symbol, MODE_TICKSIZE)/ MarketInfo(symbol, MODE_TICKVALUE);     
     
     return _point;
}  

void handleReceived(string recv){
   
   recv = UnusedRecv + recv;
   
   if(recv == ""){
      return;
   }
   
   int new_line_end = -1;
   int recv_len =  StringLen(recv);
   for(int i = recv_len -1 ; i >-1; i--)
   {  
       if(StringGetChar(recv, i) == StringGetChar(NEW_LINE,0))
       {
            new_line_end = i;
            break;
       }
      
   }
   
   if(new_line_end > -1)
   {
      string r =  StringSubstr(recv, 0, new_line_end);
      
      string arr [];
      int count = StringSplit(r, StringGetChar(NEW_LINE,0), arr);
      
      for(int i=0; i< count; i++)
      {
          receivedLine(arr[i]);
          
      }
      
      int pos = new_line_end + 1;
      if(StringLen(recv) >= pos + 1){
         UnusedRecv = StringSubstr(recv, pos, recv_len - pos);
      }else{
         UnusedRecv = "";
      }
      
   }else{
      UnusedRecv = recv;
      
   }
   

}

string getCorrespondingSymbol(string symbol_group)
{

   string symb_arr [];

   int len = StringSplit(symbol_group,';', symb_arr);
   
   for(int i=0; i < len; i++)
   {
      string symb = symb_arr[i];
      
      double try_ask = MarketInfo(symb, MODE_ASK);
      if(GetLastError() == ERR_UNKNOWN_SYMBOL)
      {  ResetLastError();
         continue;
      } 
      
      if(try_ask > 0)
      {
         return symb;
      }
       
           
   } 

   return "SOMETHING_IS_WORONG_HERE";//at this point something must be wrong
}

void duplicateEA(){
   
   string err = "Duplicate EA Not Allowed! EA on chart "+Symbol()+" has been removed because it was found to be a duplicate.";
   Alert(err);
   Print(err);
   Terminating = true;

}


void reloadEAOngoingInstallation(TradePacket &trade_packet_struct){

   if(trade_packet_struct.immediate == true){
      string msg = "Please Reload EA. Due to ongoing installations the EA has been forcibly removed.";
      Alert(msg);     
      Print(msg);
      Terminating = true;
   }
   
}


void receivedLine(string line)
{

   
   TradePacket trade_packet_struct;
   
   toReceivedTradePacket(line,  trade_packet_struct);
   
   
   //command
   if(trade_packet_struct.command == "check_enough_money")
   {
        sendCommandCheckEnoughMoney(trade_packet_struct); 
   }   
   
   if(trade_packet_struct.command == "check_tradable")
   {
        sendCommandCheckTradable(trade_packet_struct); 
   }
      
   if(trade_packet_struct.command == "duplicate_ea")
   {
        duplicateEA(); 
   }      
   
   if(trade_packet_struct.command == "shutdown_terminal_for_restart")
   {   
       //immediately close the terminal - the gui app will restart it thereafter
       TerminalClose(0);
   }
   
   if(trade_packet_struct.command == "re_established_pairing")
   {
        reestablishedPairingNotification();
   }
   
   if(trade_packet_struct.command == "re_started_terminal")
   {
        restartedTerminalNotification();
   }
   
   if(trade_packet_struct.command == "peer_terminal_to_restart")
   {
        peerTerminalToRestartNotification(trade_packet_struct);
   }
   
   
   if(trade_packet_struct.command == "peer_terminal_to_restart_confirm")
   {
        peerTerminalToRestartConfirmNotification(trade_packet_struct);
   }
   
   
   if(trade_packet_struct.command == "report_peer_terminal_to_restart_failed")
   {
        reportPeerTerminalToRestartFailed(trade_packet_struct);
   }   
      
   
   if(trade_packet_struct.command == "reload_ea_ongoing_installation")
   {
        reloadEAOngoingInstallation(trade_packet_struct); 
   }   
   
    
   if(trade_packet_struct.command == "virtual_sync")
   {
        setVirtualSync(trade_packet_struct); 
   }   
   
     
   
   //action
   if(trade_packet_struct.action == "intro")
   {
        IsIntroRequired = true; //force the EA to send the intro
   }
   
   
   
   if(trade_packet_struct.action == "sync_place_order")
   {
        sendPacketTrade(trade_packet_struct); 
   }
   
   
   if(trade_packet_struct.action == "request_take_profit_param")
   {
        sendPeerTakeProfitParam();
   }
   
   
   if(trade_packet_struct.action == "set_take_profit")
   {
        computeTakeProfit();
   }
   
   if(trade_packet_struct.action == "sync_copy")
   {
        sendPacketTrade(trade_packet_struct); 
   }
   
   
   if(trade_packet_struct.action == "sync_close")
   {
        sendPacketClose(trade_packet_struct); 
   }
   
   if(trade_packet_struct.action == "sync_partial_close")
   {
        sendPacketClose(trade_packet_struct); 
   }
   
   if(trade_packet_struct.action == "own_close")
   {
        sendPacketClose(trade_packet_struct); 
   }

   if(trade_packet_struct.action == "sync_modify_target")
   {
        sendPacketSyncModifyTarget(trade_packet_struct); 
   }

   if(trade_packet_struct.action == "unpaired_notification")
   {
        sendUnpairedNotification(trade_packet_struct); 
   }
   
   if(trade_packet_struct.action == "sync_state_paird_id")
   {             
       SyncStatePairID = trade_packet_struct.sync_state_paird_id;
       
       //Print("SyncStatePairID =",SyncStatePairID);// TESTING!!!
       
   }

      
}
//--------------------------------------------------
// initilize the trade packet struct otherwise the garbage values will be assign to it
//--------------------------------------------------
void initTradeStrct(TradePacket &trade_packet_struct)
{
   trade_packet_struct.command = "";
   trade_packet_struct.command_id = "";
   trade_packet_struct.action = "";
   trade_packet_struct.force = "";
   trade_packet_struct.uuid = "";
   trade_packet_struct.origin_ticket = -1;
   
   trade_packet_struct.immediate = false;
   
   trade_packet_struct.signal_time = 0;
   trade_packet_struct.close_time = 0;
   trade_packet_struct.copy_type = "";
   trade_packet_struct.lot_size = 0;
   trade_packet_struct.open_price = 0;
   trade_packet_struct.open_time = 0;
   trade_packet_struct.position = "";
   trade_packet_struct.stoploss = 0;
   trade_packet_struct.symbol = "";
   trade_packet_struct.target =0;
   trade_packet_struct.ticket = -1;
   trade_packet_struct.account_balance = 0;
   trade_packet_struct.floating_balance = 0;
   
   trade_packet_struct.own_ticket = 0;
   trade_packet_struct.peer_ticket = 0;
   trade_packet_struct.peer_stoploss = 0;
   trade_packet_struct.peer_spread_point = 0;
   trade_packet_struct.partial_closed_lot_fraction = 0;
}

void toReceivedTradePacket(string line, TradePacket &trade_packet_struct)
{
  
   
    if(line != PING_PACKET)
    {
         Print("RECEIVED: ",line);//TESTING!!!
    }
  
    initTradeStrct(trade_packet_struct);  
  
    string token [];
    int size = StringSplit(line,StringGetChar(TAB,0), token);   
    
    for(int i=0; i < size; i++)
    {
         string param [];
         StringSplit(token[i], '=' , param);
         string name = param[0];
         string value = param[1];
         
         trade_packet_struct.signal_time = (long)TimeCurrent();
         
         
         if(name == "command")
         {
            trade_packet_struct.command = value;
         }
         
         if(name == "command_id")
         {
            trade_packet_struct.command_id = value;
         }
         
         if(name == "action")
         {
            trade_packet_struct.action = value;
         }
         
         if(name == "uuid")
         {
            trade_packet_struct.uuid = value;            
         }
         
         if(name == "immediate")
         {
            trade_packet_struct.immediate = value == "true";
         }
         
         if(name == "force")
         {
            trade_packet_struct.force = value;
         }
         
         if(name == "reason")
         {
            trade_packet_struct.reason = value;
         }
         
         if(name == "symbol")
         {
            trade_packet_struct.symbol = defactorSymbol(value);
         }
         
         /*//deprecated
         if(name == "symbol_group" && StringLen(value) > 0)
         { 
            trade_packet_struct.symbol = getCorrespondingSymbol(value);
         }
         */
         
         if(name == "relative_symbol" && StringLen(value) > 0)// yes relative_symbol must come below symbol so that if known we use it straightway 
         {
            trade_packet_struct.symbol = value;
         }
         
         
         if(name == "ticket")
         {
            trade_packet_struct.ticket = StringToInteger(value);
         }
         
         
         if(name == "origin_ticket")
         {
            trade_packet_struct.origin_ticket = StringToInteger(value);
         }
         
         
         if(name == "position")
         {
            trade_packet_struct.position = value;
         }
         
         if(name == "lot_size")
         {
            trade_packet_struct.lot_size = value;
         }
         
         if(name == "open_price")
         {
            trade_packet_struct.open_price = value;
         }
         
         if(name == "trade_copy_type")
         {
            trade_packet_struct.copy_type = value;
         }
         
         if(name == "target")
         {
            trade_packet_struct.target = StringToDouble(value);
         }
         
         if(name == "stoploss")
         {
            trade_packet_struct.stoploss = StringToDouble(value);
         }
         
         if(name == "spread_point")
         {
            trade_packet_struct.spread_point = StringToDouble(value);
         }
         
         if(name == "peer_broker")
         {
            trade_packet_struct.peer_broker = value;
         }
         
         if(name == "peer_account_number")
         {
            trade_packet_struct.peer_account_number = value;
         }
         
      
         
         if(name == "own_ticket")
         {
            trade_packet_struct.own_ticket = StringToInteger(value);
         }
         
         
         if(name == "peer_ticket")
         {
            trade_packet_struct.peer_ticket = StringToInteger(value);
         }
         
         
         if(name == "peer_stoploss")
         {
            trade_packet_struct.peer_stoploss = StringToDouble(value);
         }
         
         
         if(name == "peer_spread_point")
         {
            trade_packet_struct.peer_spread_point = StringToDouble(value);
         }
         
         if(name == "sync_state_paird_id")
         {
            trade_packet_struct.sync_state_paird_id = value;
         }
         
         if(name == "partial_closed_lot_fraction")
         {
            trade_packet_struct.partial_closed_lot_fraction = StringToDouble(value);
         }
         
         
         
         if(name == "peer_symbol_digits")
         {
            PeerRealSymbolDigits = StringToInteger(value);
            
            Print("PeerRealSymbolDigits ", PeerRealSymbolDigits);
         }
       
         if(name == "peer_account_margin")
         {
            PeerAccountMargin = StringToDouble(value);            
         }    
         
         if(name == "peer_stopout_level")
         {
            PeerStopoutLevel = StringToDouble(value);            
         }         
                  
         if(name == "peer_account_balance")
         {
            PeerAccountBalance = StringToDouble(value);            
         }         
                  
         if(name == "peer_account_credit")
         {
            PeerAccountCredit = StringToDouble(value);            
         }         
         
         if(name == "peer_total_commission")
         {
            PeerTotalCommission = StringToDouble(value);            
         }         
                  
         if(name == "peer_total_swap")
         {
            PeerTotalSwap = StringToDouble(value);            
         }                  
         
         if(name == "peer_total_lot_size")
         {
            PeerTotalLotSize = StringToDouble(value);            
         }         
         
         if(name == "peer_contract_size")
         {
            PeerContractSize = StringToDouble(value);            
         }         
         
         if(name == "peer_position")
         {
            PeerPosition = value == "BUY"? OP_BUY: value == "SELL"? OP_SELL: -1 ;            
         }                                                          
         
         if(name == "peer_base_open_price")
         {
            PeerBaseOpenPrice = StringToDouble(value);            
         }         
          
         
         if(name == "peer_safety_spread")
         {
            PeerSafetySpread = StringToDouble(value);            
         }                                     
                                    
         
         //EA Trade Properties
         
         if(name == "sync_copy_manual_entry")
         {
            SyncCopyManualEntry =  value == "true" || value == "1";
            
            Print("SyncCopyManualEntry ", SyncCopyManualEntry);
         }
         
         
         if(name == "exit_clearance_factor")
         {
            switch(StringToInteger(value)){
               case 0: exitClearanceFactor = _0_PERCENT; EXIT_CLEARANCE_FACTOR =0; break;
               case 30: exitClearanceFactor = _30_PERCENT; EXIT_CLEARANCE_FACTOR =0.3; break;
               case 50: exitClearanceFactor = _50_PERCENT; EXIT_CLEARANCE_FACTOR =0.5; break;
               case 80: exitClearanceFactor = _80_PERCENT; EXIT_CLEARANCE_FACTOR =0.8; break;
               case 100: exitClearanceFactor = _100_PERCENT;  EXIT_CLEARANCE_FACTOR =1;break;
            }
            
            Print("EXIT_CLEARANCE_FACTOR ", EXIT_CLEARANCE_FACTOR);
         }
         
         
         if(name == "only_trade_with_credit")
         {
            OnlyTradeWithCredit =  value == "true" || value == "1";
            
            Print("OnlyTradeWithCredit ", OnlyTradeWithCredit);
         }
                                  
         
        
         if(name == "enable_exit_at_peer_stoploss")
         {
            IsExitAtPeerStoplossEnabled = value == "true" || value == "1";
            
            Print("IsExitAtPeerStoplossEnabled ", IsExitAtPeerStoplossEnabled);
         }
          
                  
         
      
    } 

}


double GetRequiredMargin(string symbol, double lotSize) {
   // Get the leverage of the account
   double leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
   
   // Get the current price of the symbol
   double price = SymbolInfoDouble(symbol, SYMBOL_BID);
   
   // Get the contract size (standard is 100,000 units for forex)
   double contractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   
   // Calculate the margin required
   double margin = (lotSize * contractSize * price) / leverage;
   
   return margin;
}


void sendCommandCheckEnoughMoney(TradePacket &trade){

      double max_volume = 0;
      SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX, max_volume);

      double lot_size = trade.lot_size > max_volume? max_volume : trade.lot_size;     
      
      int order_type = toIntOrderType(trade.position);
      
      //check if money is enough
      double free_margin = AccountFreeMarginCheck(Symbol(), order_type, lot_size);
      double required_margin = AccountBalance() - free_margin;
      int last_error = GetLastError();
      
   
      //double check
      double manaul_computed_required_margin = GetRequiredMargin(Symbol(), lot_size);
      bool manual_check_enough_money = AccountInfoDouble(ACCOUNT_BALANCE) > manaul_computed_required_margin;
            
      
      if(free_margin <= 0 || last_error==134){
         string error = "No enough money -  Free margin is zero or negative";
         if(last_error ==134){
            error = ErrorDescription(last_error);//No enough money
            ResetLastError();
         }  
         if(!manual_check_enough_money){  //double check
            sendData(checkEnoughMoneyCommandResponse(false, trade, error));
            return;
         }
         
      }
      
      sendData(checkEnoughMoneyCommandResponse(true, trade, DoubleToString(required_margin)));

}

void sendCommandCheckTradable(TradePacket &trade){

      
   
   bool connected = TerminalInfoInteger(TERMINAL_CONNECTED); 
   if(!connected){
      sendData(checkTradableCommandResponse(false, trade, "Terminal Disconnected!"));
      return;
   }
   
   bool trade_allow = AccountInfoInteger(ACCOUNT_TRADE_ALLOWED);
   if(!trade_allow){
      sendData(checkTradableCommandResponse(false, trade, "Trade not allowed!"));
      return;
   }   
      
   bool trade_expert = AccountInfoInteger(ACCOUNT_TRADE_EXPERT);
   if(!trade_expert){
      sendData(checkTradableCommandResponse(false, trade, "Automated trading is forbidden for the account " +AccountInfoInteger(ACCOUNT_LOGIN)
            +" at the trade server side"));
      return;
   }      
  
   bool symbol_trade_mode = SymbolInfoInteger(Symbol(), SYMBOL_TRADE_MODE);
   if(symbol_trade_mode == SYMBOL_TRADE_MODE_DISABLED){
      sendData(checkTradableCommandResponse(false, trade, "Trade is disabled for the symbol - "+Symbol()));
      return;
   } 
      
   sendData(checkTradableCommandResponse(true, trade,"success"));

}


void setVirtualSync(TradePacket &trade){
   
   bool found = false;
         
   for(int i=0; i<vSyncList.Total(); i++){
      VirtualSync *vSync = vSyncList.GetNodeAtIndex(i);
      if(vSync.own_ticket == trade.own_ticket && vSync.peer_ticket == trade.peer_ticket){
          if(trade.peer_stoploss != 0){
               
               vSync.peer_stoploss = trade.peer_stoploss;
               
               //update GUI list view               
               lstPeerTicketsView.ItemUpdate(i, vSync.peer_ticket, vSync.peer_ticket);
               
          } 
          if(trade.peer_spread_point != 0){
               vSync.peer_spread_point = trade.peer_spread_point;
          }             
          
          found = true;              
      }
   }      
   
   if(!found){
        VirtualSync *vSync = new VirtualSync;
        vSync.own_ticket = trade.own_ticket;
        vSync.peer_ticket = trade.peer_ticket;
        vSync.peer_stoploss = trade.peer_stoploss;
        vSync.peer_spread_point = trade.peer_spread_point;
        
        vSyncList.Add(vSync);       
        
        //add item to GUI list view
        lstPeerTicketsView.AddItem(vSync.peer_ticket, vSync.peer_ticket); 
            
        lstPeerTicketsView.Select(0); //select the first in the list
        
        updatePeerStoplossLabelsUI(lstPeerTicketsView.Select());
   }
   
   ExpectedExitProfit = 0; // profit if exit at peer stoploss
   ExpectedTargetProfit = 0;// profit if exit at main target
   ExpectedExitBalance = 0;// balance if exit at peer stoploss
   ExpectedTargetBalance = 0;// balance if exit at main target
   
   
   Print(" -----------------START VIRTUAL SYNC------------------------- ");

   
   for(int i=0; i<vSyncList.Total(); i++){
       VirtualSync *vSync = vSyncList.GetNodeAtIndex(i);     
       
       
         //Print("vSync.own_ticket ",vSync.own_ticket);
         //Print("vSync.peer_ticket ",vSync.peer_ticket);
         //Print("vSync.peer_stoploss ",vSync.peer_stoploss);
         //Print("vSync.peer_spread_point ",vSync.peer_spread_point);                 
      
       if(OrderSelect(vSync.own_ticket, SELECT_BY_TICKET)==true) 
       {               
          
          if(OrderCloseTime()){
              continue;//skip since we only need open orders
          }
          
          //At this point the order is still open
            
          ExpectedExitProfit += OrderSwap() + OrderCommission() + OrderLots() * MathAbs(OrderOpenPrice() - vSync.peer_stoploss) / getUsableSymbolPoint(OrderSymbol());       
          ExpectedTargetProfit += OrderSwap() + OrderCommission() + OrderLots() * MathAbs(OrderOpenPrice() - OrderTakeProfit()) / getUsableSymbolPoint(OrderSymbol());       
          
          ExpectedExitBalance = AccountBalance() + ExpectedExitProfit; 
          ExpectedTargetBalance = AccountBalance() + ExpectedTargetProfit;
             
       }
   }
   
   
   lblExpectedProfitRange.Text(NormalizeDouble(ExpectedExitProfit, 2)
      + " " + AccountCurrency()
      + " / " + NormalizeDouble(ExpectedTargetProfit, 2)
      + " " + AccountCurrency());
      
   lblExpectedBalanceRange.Text(NormalizeDouble(ExpectedExitBalance, 2)
      + " " + AccountCurrency()
      + " / " + NormalizeDouble(ExpectedTargetBalance, 2)
      + " " + AccountCurrency());
   
   
   
   
   //Print("ExpectedExitProfit ",ExpectedExitProfit);
   //Print("ExpectedTargetProfit ",ExpectedTargetProfit);
   //Print("expected_exit_bal ",ExpectedExitBalance);
   //Print("expected_target_bal ",ExpectedTargetBalance);
   //Print(" -----------------END VIRTUAL SYNC------------------------- ");

}

void checkPeerStoplossHit(){
   
      if(!IsExitAtPeerStoplossEnabled){
         return;
      }

      for(int n=0; n<vSyncList.Total(); n++){                      
          
           VirtualSync *vSync = vSyncList.GetNodeAtIndex(n);
          
           if(vSync.peer_stoploss <= 0){
               continue; //Skip since no stoploss yet.
           }
          
           if(OrderSelect(vSync.own_ticket, SELECT_BY_TICKET)) 
           {
               if(OrderCloseTime()){
                  continue;//skip since we only need open orders
               }
               
               //At this point the order is still open
               
               if(OrderType() == OP_BUY){
                  //Which means peer position is SELL
                  checkPeerStoplossHit0(OP_SELL, vSync);                                                      
               }else if(OrderType() == OP_SELL){
                  //Which means peer position is BUY
                  checkPeerStoplossHit0(OP_BUY, vSync);                        
               }
                                         
             }
      }
      
}

double exitClearance(VirtualSync &vSync){
   return vSync.peer_spread_point * EXIT_CLEARANCE_FACTOR;
}

//-------------------------------------
//This method is use to prevent us from missing
//the correct price to test our exit condition especially
//during high volatility where the EA is not fast enough 
//to see the current prices to test our conditon with.
//It can be dangerous if we missing price as per our condition.
//So the trick is to use the highest or lowest price within
//setting safe (reasonable) period to match our condition 
//
//Now suppose the account position is BUY and the peer account is SELL
//Then this account eixt condition will be that if the peer Ask price (ie this account current price named this way for logic clarity)
//is greater than or equal to the exit price (stoploss of peer minus clearance), then close the 
//the trade. But what if the patform hangs or a distrupting event happens (like too high volatility)
//at that period the condition was met and EA could to detect is first and the market reverses
//completely and never meets that condition  again, that will just mean blowing out the entire
//account on both sides. Now to prevent this posssibility we will test with the 
//highest high of last 3 one-minute bars instead of just the current price (we named as peer Ask price).
//The sense behind this is that this unexpected happening that prevented this account EA
//from seeing the exist condition first time may not last for more than 3 minute 
//thus allowing the condition to be detected even  though very late, 
//thanks to the High price stamped on all bars
//------------------------------------
double safePriceToCompareWith(int peerPos, double exit_price , double peer_spread_point){

   int LAST_BARS_COUNT = 3;

   debugPriceIsClosePrice = false;//for debug purpose

   //let know time elapse after trade open
   int timeElapseInsec = TimeCurrent() - OrderOpenTime();
   if(timeElapseInsec <= LAST_BARS_COUNT * 60){
      debugPriceIsClosePrice = true;//for debug purpose
      return Close[0]; //just return current prices within the first minute as it is unsafe to test with Low or High with this period
   }
   
   //At this point we are on the next N bars of the one minute timeframe since open trade. 
   //This is a safe (reasonable) period to use High or Low to test our condition
   int one_minute_bar_count = timeElapseInsec/60;
   
   //we just need few bars like say 3 to reduce computation
   //Since we know the EA delay (slowness - time b/w execution)
   //can not be more than 3 minutes except is something is 
   //seriously wrong
   if(one_minute_bar_count > LAST_BARS_COUNT){
      one_minute_bar_count = LAST_BARS_COUNT;
   }
   
   
   //At this point at least a new one minute bar is created
   double peak_price = 0;
   
   int shift = 0;
   if(peerPos == OP_BUY){
      shift = iLowest(Symbol(), PERIOD_M1, MODE_LOW, one_minute_bar_count);    
      
      if(shift == -1) PrintFormat("Error in iLowest. Error code=%d",GetLastError());  
      
   }else{
      shift = iHighest(Symbol(), PERIOD_M1, MODE_HIGH, one_minute_bar_count);
      
      if(shift == -1) PrintFormat("Error in iHighest. Error code=%d",GetLastError());
   }
   
   
   if(shift == -1){      
      //An error occoure so just return the high or low of the current bar  
      shift = 0;  
   }

   //ASSERTION 1 - Just checking if this is a bug - unexpected hitting the peer exit stoploss
   if(shift > LAST_BARS_COUNT){ 
      Print("BUG PREVENTED!!!  POSSIBLY NONSENSE VALUE. shift = ", shift);
      shift = 0;  
   }


        
   if(peerPos == OP_BUY)
      peak_price = Low[shift];
   else
      peak_price = High[shift];    
   
   
   
   //Check if the peer stoploss intercepts the high / low with the last N bars on the current timeframe
   
   if(timeElapseInsec <= LAST_BARS_COUNT * Period() * 60){
      
      if(peerPos == OP_BUY && peak_price <= exit_price)
      {         
         bugResolved ++;
         peak_price =  Close[0];      
      } 
      
      if(peerPos == OP_SELL && peak_price >= peak_price + peer_spread_point)
      {  
         bugResolved ++;       
         peak_price =  Close[0];      
      }      

   } 
   
   
   if(bugResolved == 1){
      
      Alert("GREAT! MAJOR BUG IS RESOLVED");
      Print("GREAT! MAJOR BUG IS RESOLVED");
   
   }           
   
   return peak_price;
}

void checkPeerStoplossHit0(int peerPos, VirtualSync &vSync){
   
   //Print("checkPeerStoplossHit0");
   
   bool success = false;
   bool attempted = false;

   //The purpose of this clearance is to ensure this account (POSITIVE SIDE) sees
   //this stoploss price before the peer account (NEGATIVE SIDE) to ensure the positive side
   //closes first before the negative account side.

   double clearance = exitClearance(vSync);    

   double exit_price = peerPos == OP_BUY
                ? vSync.peer_stoploss + clearance 
                : vSync.peer_stoploss - clearance;
           
   
   double safePrice = safePriceToCompareWith(peerPos, exit_price, vSync.peer_spread_point);//which is Highest High or Lowest Low of N bars - Please see Comments on safePriceToCompareWith() method for more explanation      
      
      
   //BUY enters at Ask price but closes at Bid price
   double PeerBid = safePrice; //Which is Close[0] but we are not using the Close[0] directly to handle missed price condition - Please see Comments on safePriceToCompareWith() method for more explanation
   
   //SELL enters at Bid price but closes at Ask price
   double PeerAsk = safePrice + vSync.peer_spread_point; //yes, we are calculating what should be the Ask price on the peer account. We know it is the Close[0] plus the spread - But we are not using the Close[0] directly to handle missed price condition - Please see Comments on safePriceToCompareWith() method for more explanation

   if(peerPos == OP_BUY){   
      
      bool PrevIsHitPeerStoploss = vSync.IsHitPeerStoploss; // if true then it probably is a retry otherwise a big bug - this is while we are storing the value
      
      if(PeerBid <=  exit_price || vSync.IsHitPeerStoploss){                   
         vSync.IsHitPeerStoploss = true;
         attempted = true;
         //NOTE: SELL closes at Ask Price - since Peer is BUY then own is SELL and will close at Ask price
         int err_code = closeSelectedPosition( OrderLots(), MODE_ASK);
         success = err_code == 0;           
                  
         Print("HIT Peer BUY Stoploss exit_price ", exit_price,
                " safePrice ", safePrice ,  
                " debugPriceIsClosePrice ", debugPriceIsClosePrice , //whether the safePrice is the current price or high/low
                " vSync.peer_stoploss ", vSync.peer_stoploss ,    
                " vSync.peer_spread_point ", vSync.peer_spread_point ,      
                " clearance ",clearance,
                " PrevIsHitPeerStoploss ", PrevIsHitPeerStoploss); 
      }
         
   }
   
   
   
   
   if(peerPos == OP_SELL){   
   
      bool PrevIsHitPeerStoploss = vSync.IsHitPeerStoploss; // if true then it probably is a retry otherwise a big bug - this is while we are storing the value
   
      if(PeerAsk >=  exit_price || vSync.IsHitPeerStoploss){            
         vSync.IsHitPeerStoploss = true;
         attempted = true;
         //NOTE: BUY closeS at Bid Price - since Peer is SELL then own is BUY and will close at Bid price
         int err_code = closeSelectedPosition( OrderLots(), MODE_BID);
         success = err_code == 0;              
                  
         Print("HIT Peer SELL Stoploss exit_price ", exit_price,
                " safePrice ", safePrice ,    
                " debugPriceIsClosePrice ", debugPriceIsClosePrice , //whether the safePrice is the current price or high/low                 
                " vSync.peer_stoploss ", vSync.peer_stoploss ,    
                " vSync.peer_spread_point ", vSync.peer_spread_point ,      
                " clearance ",clearance,
                " PrevIsHitPeerStoploss ", PrevIsHitPeerStoploss);         
      }
            
   }
   
      
   if(attempted && success){
     
     sendData(exitAtPeerStoplossPacket(vSync));
     SendNotification(StringFormat("EXIT AT PEER STOPlOSS\nPeer Ticket #%d\nOwn Ticket #%d\nBal. %s", vSync.peer_ticket, vSync.own_ticket, AccountBalance()+" "+ AccountCurrency()));       
     lblAlert.Text("SUCCESSFUL EXIT AT PEER STOPOLOSS PRICE");
     
   }else if(attempted && !success){
      string error = ErrorDescription(GetLastError()); 
      sendData(exitAtPeerStoplossPacket(vSync, error));     
   }
   

}

string exitAtPeerStoplossPacket(VirtualSync &vSync, string error = ""){

   bool success = error=="";
          
   string packet = "exit_at_peer_stoploss_success="+success+TAB
   +"own_ticket="+IntegerToString(vSync.own_ticket)+TAB
   +"peer_ticket="+IntegerToString(vSync.peer_ticket)+TAB
   +"error="+error+TAB;
   
   return packet;

} 

int closeSelectedPosition(double lots, int mode){
    
    int MAX_ATTEMPT = 3;
    int error = 0;
    
    for(int try_count = 0; try_count < MAX_ATTEMPT; try_count++){                     
       bool success = OrderClose( OrderTicket(), lots, MarketInfo(OrderSymbol(), mode), 5, clrNONE ); 

       error = GetLastError();
       
       if(!success && error == ERR_REQUOTE){
           Sleep(200);  
           Print(StringFormat("REQUOTE ERROR: RETRY CLOSE [%d] - Order ticket #%d", try_count, OrderTicket()));
           ResetLastError();           
           RefreshRates();           
           continue;
       }else{
           break;
       }                        
    }
    
   return error;   
}


void sendPacketClose(TradePacket &trade)
{
   
     string data = "";

      for(int i= OrdersTotal() - 1; i > -1; i--)
      {
          
          if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
          {  
             if(trade.ticket == OrderTicket())
             {
                string error = "";
                bool success = true;
                bool pending = false;     
                bool is_partial_close = trade.partial_closed_lot_fraction > 0 && trade.partial_closed_lot_fraction < 1;
                
                double lots = OrderLots();
                                                
                if(is_partial_close){
                  lots = OrderLots() * trade.partial_closed_lot_fraction; 
                }
                
                if ( OrderType() == OP_BUY)  //BUY is enters at ASK price but closes at BID price
                {
                   int err_code = closeSelectedPosition(lots, MODE_BID);
                   success = err_code == 0;
                }
                else if ( OrderType() == OP_SELL)//SELL is enters at BID price but closes at ASK price 
                {
                   int err_code = closeSelectedPosition(lots, MODE_ASK);
                   success = err_code == 0;                   
                }
                else //pending orders
                {
                   pending = true;
                   success = OrderDelete(OrderTicket());                   
                }
                
                if(success && !is_partial_close)
                {
                     addTicketOfSyncClose(trade.ticket);//mark this order ticket as one of those generated by close operation
                     if(trade.force == "true"){
                        lblAlert.Text(trade.reason);
                        Print(trade.reason);
                     }
                }
                else if(success && is_partial_close)
                {
                  addTicketOfSyncClose(trade.ticket);//mark this order ticket as one of those generated by close operation                     
                }
                else
                {
                     if(trade.force == "true"){
                        string warning = "WARNING!!! Secure attempt to forcibly close order #"+trade.ticket+" failed!";
                        lblAlert.Text(warning);
                        Print(warning);
                     }
                     
                    error = ErrorDescription(GetLastError());
                   
                      if(!pending){
                         Print("OrderClose error ",error);  
                      }else{
                         Print("OrderDelete error ",error);  
                      }
                }
                
                data += closeSuccessPacket(success, trade, error);   
                    
             }
                  
          } 
      }
     
       
      if(data !="")
      {
           sendData(data);
      }        
      
   
}

void restoreTarget(){


      if(LastAutoModifiedTarget == 0){
         return;
      }
      
      int SymbolDigits = ensureSameSymboDigitsWithPeer();
      
      if( SymbolDigits == UNDEFINED){
         return;
      }
      
      
      for(int i= OrdersTotal() - 1; i > -1; i--)
      {         
          
          if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
          {  
                                
                if(NormalizeDouble(OrderTakeProfit(), SymbolDigits) 
                     == NormalizeDouble(LastAutoModifiedTarget, SymbolDigits)){
                     continue;
                }
                
                
                PrintFormat("Order #%d - DETECTED MANUAL TARGET MODIFICATION WHICH IS NOT ALLOWED", OrderTicket());  
                
                if(OrderModify(OrderTicket(),OrderOpenPrice(), OrderStopLoss(),LastAutoModifiedTarget,0,0))
                {
                    PrintFormat("Order #%d - TARGET HAS BEEN RESET BACK TO %s", OrderTicket(), DoubleToString(LastAutoModifiedTarget, _Digits));
  
                }else{                                        
                    PrintFormat("Order #%d - FAILED TO RESET TARGET BACK TO %s", OrderTicket(),DoubleToString(LastAutoModifiedTarget, _Digits));
                    
                    string error = ErrorDescription(GetLastError()); 
                    Print(error);
                }                                               
          } 
      }
}

void sendPacketSyncModifyTarget(TradePacket &trade)
{
   
     string data = "";

      for(int i= OrdersTotal() - 1; i > -1; i--)
      {
          
          if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
          {  
             if(trade.ticket == OrderTicket())
             {
                if(OrderModify(OrderTicket(),OrderOpenPrice(), OrderStopLoss(),trade.target,0,0))
                {
                    LastAutoModifiedTarget = trade.target;
                     
                    data += modifyTargetSuccessPacket(true, trade);  
                    
                    addTicketOfSyncModify(trade.ticket);
                    
                }else{
                    
                    string error = ErrorDescription(GetLastError());
                   
                    data += modifyTargetSuccessPacket(false, trade, error);   
                }
                
             }
                  
          } 
      }
     
       
      if(data !="")
      {
           sendData(data);
      }        
      
   
}


bool findTradeByPacket(TradePacket &trade){
     
     
     for(int i= OrdersTotal() - 1; i > -1; i--)
     {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {         
         
            if(OrderMagicNumber() == COPIED_TRADE_MAGIC_NUMBER 
                  && trade.ticket == OrderTicket()//NEW 
                  )
            {
               return true;
            }
         } 
     }
     
     return  false;      
}

bool findHistoryByPacket(TradePacket &trade){
     
     
     for(int i= OrdersHistoryTotal() - 1; i > -1; i--)
     {
         if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
         {
         
             if(!isOrderType()){//we only want order type and not credit or balance as displayed in AccountHistory of the Terminal
                 continue;               
             }
      
         
            if(OrderMagicNumber() == COPIED_TRADE_MAGIC_NUMBER 
                  && trade.ticket == OrderTicket()//NEW 
                  )
            {
               return true;
            }
         } 
     }
     
     return  false;      
}

   /*
   @Deprecated
   
      CODING FOR PARTIAL CLOSE FEATURE IS TOO COMPLEX AND CHALLENGING BECAUSE  WHEN 
      PARTIALLY CLOSE A NEW TICKET IS CREATE OF THE PARTIAL OPEN ORDER THUS POSES
      A VERY COMPLEX APPROACH FOR ENSURING SYNCHRONIZATION 
    
   double partialClosedOrderFraction(ulong partial_closed_ticket, double partial_lot, ulong &open_tickets[], double &open_lots[]){
        
        int size = ArraySize(open_tickets);
        
        for(int i =0; i < size; i++){
        
            if(open_tickets[i] != partial_closed_ticket){                        
               return open_lots[i] / ( open_lots[i] + partial_lot);
            }                                
        }
      
      return 0;
   
   } 
   */


void addTicketOfSyncOrderSend(ulong ticket)
{
   addSetItem(ticket, ticketsOfSyncCopy);
}


void addTicketOfSyncClose(ulong ticket)
{
   addSetItem(ticket, ticketsOfSyncClose);
}


void addTicketOfSyncModify(ulong ticket)
{
   addSetItem(ticket, ticketsOfSyncModify);
}


void addSetItem(ulong item, ulong &items [])
{

   bool isAlreadyAdded = contains(item, items);
   
   if( isAlreadyAdded){
      return;
   }

   int new_size = ArraySize(items) + 1;
   ArrayResize(items, new_size);
   items[new_size -1] = item;
}


void addSetItem(double item, double &items [])
{

   bool isAlreadyAdded = contains(item, items);
   
   if( isAlreadyAdded){
      return;
   }

   int new_size = ArraySize(items) + 1;
   ArrayResize(items, new_size);
   items[new_size -1] = item;
}


void addItem(ulong item, ulong &items [])
{
   int new_size = ArraySize(items) + 1;
   ArrayResize(items, new_size);
   items[new_size -1] = item;
}


void addItem(double item, double &items [])
{
   int new_size = ArraySize(items) + 1;
   ArrayResize(items, new_size);
   items[new_size -1] = item;
}


bool isTicketOfSyncCopy(ulong ticket)
{
   return contains(ticket, ticketsOfSyncCopy);
}

bool isTicketOfSyncClose(ulong ticket)
{
   return contains(ticket, ticketsOfSyncClose);
}


bool isTicketOfSyncModify(ulong ticket)
{
   return contains(ticket, ticketsOfSyncModify);
}

bool contains(ulong item, ulong &items [])
{
   int size = ArraySize(items);
   
   for(int i=0; i < size; i++)
   {
      if(items[i] == item)
      {
         return true;
      }
   }
   return false;
}


bool contains(double item, double &items [])
{
   int size = ArraySize(items);
   
   for(int i=0; i < size; i++)
   {
      if(items[i] == item)
      {
         return true;
      }
   }
   return false;
}


void clearTicketsOfSyncCopy()
{
   ArrayResize(ticketsOfSyncCopy, 0);
}


void clearTicketsOfSyncClose()
{
   ArrayResize(ticketsOfSyncClose, 0);
}


void clearTicketsOfSyncModify()
{
   ArrayResize(ticketsOfSyncModify, 0);
}

void arrayAppend(ulong ticket, ulong &ticketsOfOrder [])
{
   int new_size = ArraySize(ticketsOfOrder) + 1;
   ArrayResize(ticketsOfOrder, new_size);
   ticketsOfOrder[new_size -1] = ticket;
}


void clearTicketsOfPlacementOrder()
{
   ArrayResize(ticketsOfPlacementOrder, 0);
}

void sendPacketTrade(TradePacket &trade)
{
      
      double lot_size = trade.lot_size;
      
      string trade_pos = trade.position;            
      
      int order_type = toIntOrderType(trade_pos);
      
      
      //Print("-------------------------------");
      //Print("trade.ticket=",trade.ticket);
      //Print("trade.origin_ticket=",trade.origin_ticket);
      //Print("trade.symbol=",trade.symbol);
      //Print("trade.open_price=",trade.open_price);
      //Print("trade.close_time=",trade.close_time);
      //Print("trade.position=",trade.position);
      //Print("order_type=",order_type);
      //Print("trade.lot_size=",trade.lot_size);
      //Print("trade.stoploss=",trade.stoploss);
      //Print("trade.target=",trade.target);
      
      
      if(!IsConnected()){
         sendData(syncSendOrderSuccessPacket(false, -1, trade, "No connection."));
         return;
      }
      
      string data = "";
      
      int count_try = 0;
      
      while(count_try < 3)
      {
         count_try++;
         
         if(order_type == OP_BUY)
         { 
             double entry_price = MarketInfo(trade.symbol,MODE_ASK);  
             
             ulong ticket=OrderSend(trade.symbol, order_type, lot_size, entry_price, 100, trade.stoploss, trade.target,
                                                      "",COPIED_TRADE_MAGIC_NUMBER,0,clrNONE);
             
                  
             if(ticket > 0 ){
                  
                  addTicketOfSyncOrderSend(ticket);//mark this order ticket as one of those generated by sync send order operation
                  
                  data = syncSendOrderSuccessPacket(true, ticket, trade);                  
                  break;
             }
             else{
                  string error = ErrorDescription(GetLastError());
                  
                  data = syncSendOrderSuccessPacket(false, -1, trade, error);
                    
                 Print("TRY : ", count_try,"OrderSend error ", error);
              } 
              
          }else if(order_type == OP_SELL){
          
             double entry_price = MarketInfo(trade.symbol,MODE_BID);  
             
             
             ulong ticket=OrderSend(trade.symbol, order_type,lot_size, entry_price, 100, trade.stoploss, trade.target,
                                                      "",COPIED_TRADE_MAGIC_NUMBER,0,clrNONE);
                                                      
             if(ticket > 0 ){
                  
                  addTicketOfSyncOrderSend(ticket);//mark this order ticket as one of those generated by copy operation
                  
                  data = syncSendOrderSuccessPacket(true, ticket, trade);                  
                  break;
             }
             else{
                  string error = ErrorDescription(GetLastError());
                  
                 data = syncSendOrderSuccessPacket(false, -1, trade, error);  
                 Print("TRY : ", count_try,"OrderSend error ", error);                     
             } 
              
          }else{
            Print("Unknown order type ", order_type);
            return;
          }
          
          Sleep(1000); //important!
          
          //Important - avoid duplicate trade when there is a connection error which is possible. I observed the bug.
          //So make sure truly the trade is not duplicated because of connection error moment after the trade is
          //already sent to the server
          if(findTradeByPacket(trade))
          {
              Print("GOOD! Avoided duplicate trade! - ",trade.symbol);             
              break;//leave to avoid duplicate trade
          }
       }
       
       if(data !="")
       {
            sendData(data);
       }     

}

string syncSendOrderSuccessPacket(bool success, ulong ticket, TradePacket &trade, string error="")
{      
   if(trade.action == "sync_copy"){
      return copySuccessPacket(success, ticket, trade,  error);
   }else if(trade.action == "sync_place_order"){
      return placeOrderSuccessPacket(success, ticket, trade,  error);   
   }
   
   return "";
}


string placeOrderSuccessPacket(bool success, ulong ticket, TradePacket &trade, string error="")
{      
   if(error == "market is closed")
   {
      IsMarketClosed = true;
   }
   
   arrayAppend(ticket, ticketsOfPlacementOrder); //important! force the order information to be sent on next ticket. only reliable way of selecting the order
          
   string packet = "place_order_success="+success+TAB
   +"ticket="+IntegerToString(ticket)+TAB
   +"uuid="+trade.uuid+TAB
   +"error="+error+TAB;
   
   return packet;
}



string copySuccessPacket(bool success, ulong ticket, TradePacket &trade, string error="")
{      
   if(error == "market is closed")
   {
      IsMarketClosed = true;
   }
          
   string packet = "copy_success="+success+TAB
   +"ticket="+IntegerToString(ticket)+TAB
   +"origin_ticket="+IntegerToString(trade.ticket)+TAB
   +"copy_signal_time="+trade.signal_time+TAB
   +"copy_execution_time="+(long)TimeCurrent()+TAB
   +"error="+error+TAB;
   
   return packet;
}

string maximizeLockInProfitSuccessPacket(bool success,int ticket, string stoploss, string error="")
{  

   if(error == "market is closed")
   {
      IsMarketClosed = true;
   }
       
   return "ticket="+IntegerToString(ticket)+TAB
   +"stoploss="+DoubleToString(stoploss)+TAB   
   +"maximize_lock_in_profit_success="+success+TAB   
   +"error="+error+TAB;
}

string lockInProfitSuccessPacket(bool success, TradePacket &trade, string error="")
{  

   if(error == "market is closed")
   {
      IsMarketClosed = true;
   }
       
   return "ticket="+IntegerToString(trade.ticket)+TAB
   +"origin_ticket="+IntegerToString(trade.origin_ticket)+TAB   
   +"stoploss="+DoubleToString(trade.stoploss)+TAB
   +"lock_in_profit_success="+success+TAB   
   +"error="+error+TAB;
}

string exitOnToleranceTargetSuccessPacket(bool success, TradePacket &trade, string error="")
{  

   if(error == "market is closed")
   {
      IsMarketClosed = true;
   }
       
   return "ticket="+IntegerToString(trade.ticket)+TAB
   +"origin_ticket="+IntegerToString(trade.origin_ticket)+TAB   
   +"floating_balance="+DoubleToString(trade.floating_balance)+TAB
   +"account_balance="+DoubleToString(trade.account_balance)+TAB   
   +"exit_on_tolerance_target_success="+success+TAB   
   +"error="+error+TAB;
}


string closeSuccessPacket(bool success, TradePacket &trade, string error="")
{  

   if(error == "market is closed")
   {
      IsMarketClosed = true;
   }
       
   string packet = "";
       
   packet += "ticket="+IntegerToString(trade.ticket)+TAB 
   +"close_signal_time="+trade.signal_time+TAB
   +"close_execution_time="+(long)TimeCurrent()+TAB
   +"error="+error+TAB;
      
   
   if(trade.ticket > 0){//means it is selected
      long close_time = 0;
      double close_price = 0;
      
      if(OrderSelect(trade.ticket, SELECT_BY_TICKET)){
            close_time = (long)OrderCloseTime();
            close_price = OrderClosePrice();
      }      
   
      if(close_time == 0){//just in case it is still saying zero then i disagree
         close_time = (long)TimeCurrent();
      }
   
      packet += "close_time="+close_time+TAB
               +"close_price="+close_price+TAB;  
   }
   
   
   if(trade.action == "sync_close"){
      packet += "origin_ticket="+IntegerToString(trade.origin_ticket)+TAB
      +"close_success="+success+TAB;  

   }else if(trade.action == "own_close"){
      packet += "origin_ticket="+IntegerToString(trade.origin_ticket)+TAB
      +"partial_close_success="+success+TAB; 
      
   }else if(trade.action == "own_close"){
      packet += "force="+trade.force+TAB
      +"reason="+trade.reason+TAB
      +"own_close_success="+success+TAB;  
   }   
   
   return packet;
}


string modifyTakeProfitSuccessPacket(bool success, TradePacket &trade, string error="")
{         
   if(error == "market is closed")
   {
      IsMarketClosed = true;
   }
       
   return "modify_take_profit_success="+success+TAB
   +"ticket="+IntegerToString(trade.ticket)+TAB
   +"target="+DoubleToString(trade.target)+TAB
   +"error="+error+TAB;
}


string modifyTargetSuccessPacket(bool success, TradePacket &trade, string error="")
{         
   if(error == "market is closed")
   {
      IsMarketClosed = true;
   }
       
   return "modify_target_success="+success+TAB
   +"ticket="+IntegerToString(trade.ticket)+TAB
   +"origin_ticket="+IntegerToString(trade.origin_ticket)+TAB
   +"target="+DoubleToString(trade.target)+TAB
   +"modify_target_signal_time="+trade.signal_time+TAB
   +"modify_target_execution_time="+(long)TimeCurrent()+TAB
   +"error="+error+TAB;
}


string checkEnoughMoneyCommandResponse(bool success,  TradePacket &trade, string response){
   return "command="+trade.command+TAB
         +"command_id="+trade.command_id+TAB
         +"command_response="+response+TAB
         +"command_success="+success+TAB;
}

string checkTradableCommandResponse(bool success,  TradePacket &trade, string response){
   return "command="+trade.command+TAB
         +"command_id="+trade.command_id+TAB
         +"command_response="+response+TAB
         +"command_success="+success+TAB;
}

string getStrOrderType()
{
        if(OrderType() == OP_BUY)
        {
            return "BUY";
        }
        else if(OrderType() == OP_BUYLIMIT)
        {
            return "BUYLIMIT";
        }
        else if(OrderType() == OP_BUYSTOP)
        {
            return "BUYSTOP";               
        }
        else if(OrderType() == OP_SELL)
        {
            return "SELL";
        }
        else if(OrderType() == OP_SELLLIMIT)
        {
            return "SELLLIMIT";
        }
        else if(OrderType() == OP_SELLSTOP)
        {
            return "SELLSTOP";
        }
               
   return "";                           
}

bool isOrderType(){
   return OrderType() == OP_BUY 
            || OrderType() == OP_SELL 
            || OrderType() == OP_BUYSTOP 
            || OrderType() == OP_SELLSTOP 
            || OrderType() == OP_BUYLIMIT 
            || OrderType() == OP_SELLLIMIT;
}


int toIntOrderType(string pos)
{
         
        if(pos == "BUY")
        {
            return OP_BUY;
        }
        else if(pos == "BUYLIMIT")
        {
            return OP_BUYLIMIT;
        }
        else if(pos == "BUYSTOP")
        {
            return OP_BUYSTOP;               
        }
        else if(pos == "SELL")
        {
            return OP_SELL;
        }
        else if(pos == "SELLLIMIT")
        {
            return OP_SELLLIMIT;
        }
        else if(pos == "SELLSTOP")
        {
            return OP_SELLSTOP;
        }
        
        
    return -1;
}

bool isOrderTradeStatusChange(ChangeStats &stats)
{

      stats.TradeCountChanged = false;      
      stats.TradeCountIncreased = false;
      stats.TradeModified = false;     
      stats.TradeSwapChanged = false;
      
      int total = OrdersTotal();
      int buy_count = 0;
      int sell_count = 0;
      double cum_stoploss = 0;
      double cum_target = 0;
      double cum_swap = 0;
      
      for(int i=0; i < total; i++)
         {
         
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {         
            
               cum_stoploss += OrderStopLoss();
               cum_target += OrderTakeProfit();
               cum_swap += OrderSwap();
               
               if(OrderType() == OP_BUY )
               {
                  buy_count++;
               }
               else if(OrderType() == OP_SELL)
               {
                 sell_count++;
               }

            
            }
            
         }
         
         bool is_changed = false;
         
         if(buy_count != BuyCount 
            ||sell_count != SellCount)
        {        
            
            if(buy_count > BuyCount || sell_count > SellCount){
               stats.TradeCountIncreased = true; 
            }            
        
            BuyCount = buy_count;
            SellCount = sell_count;
                                    
            stats.TradeCountChanged = true;             
            is_changed = true;
        }  
        
        
        int h_total = OrdersHistoryTotal();
        
        if(HistoryTotal != h_total)
        {
           stats.TradeCountChanged = true; 
           is_changed = true;
        }
        
        
        if(cum_stoploss != CumStoploss 
            || cum_target != CumTarget )
        {
            CumStoploss = cum_stoploss;
            CumTarget = cum_target;
                       
            stats.TradeModified = true;
            is_changed = true;
        }  
        
        if(cum_swap != CumSwap)
        {
            CumSwap = cum_swap;
                       
            stats.TradeSwapChanged = true;
            is_changed = true;
        }  
                
        
    return is_changed;      
}

void sendPlaceOrderData(){

   ulong failed_tickets [];
   
   for(int i=0; i < ArraySize(ticketsOfPlacementOrder); i++)
   {
      ulong ticket = ticketsOfPlacementOrder[i];
      if(OrderSelect(ticket, SELECT_BY_TICKET))
      {
         
          if(!isOrderType()){//we only want order type and not credit or balance as displayed in AccountHistory of the Terminal
              continue;               
          }
      
          string data = generateTradeStreamPacket();          
          sendData(data);         
      }else{
         arrayAppend(ticket, failed_tickets);
      }
      
   }  
   
   clearTicketsOfPlacementOrder();
   
   if(ArraySize(failed_tickets)){
      ArrayCopy(ticketsOfPlacementOrder, failed_tickets);
   }
}
  

void sendDataAttrForSyncStateID(){

      string data = "";
      string tickets = "";
      
      int total = OrdersTotal();
      

      int count = 0;
      string tck = "";
      for(int i=0; i < total; i++)
         {
         
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {                                         
                 //At this point the order was not generated by copy operation                      
                 count++;
                 tck = count == 1 ? OrderTicket(): ","+OrderTicket();
                 tickets += tck;
                                       
            }
            
         }
         
                        
      data +="data_for_sync_state_pair_id="+tickets+TAB;  
      sendData(data);       

}


void sendSyncOrdersData()
{

      string data = "";

      int total = OrdersTotal();
      for(int i=0; i < total; i++)
         {         
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {         
               //in this case we need those generated by sync operations   
               if(isTicketOfSyncCopy(OrderTicket()))
                  {
                     //only those by sync operation
                     data += generateTradeStreamPacket();
                  }                                  
                 
            }
            
         }    
     
     if(data != "")
     {
         sendData(data);
     }
}
  
void sendTradeData(string prepend_data = "")
{
   
      bool new_trade_entries = false;
      bool close_trades = false;
      
      //CODING FOR PARTIAL CLOSE FEATURE IS TOO COMPLEX AND CHALLENGING BECAUSE  WHEN 
      //PARTIALLY CLOSED A NEW TICKET IS CREATED OF THE PARTIAL OPEN ORDER THUS POSES
      //A VERY COMPLEX APPROACH FOR ENSURING SYNCHRONIZATION
      
      //bool partial_close = false; //@Deprecated - TOO HARD TO DO  - SOLUTION PRONE TO ERROR
      
      
      ulong open_tickets [];
      double open_lots [];

      string data = ensureWithTab(prepend_data);

      int total = OrdersTotal();
      for(int i=0; i < total; i++)
         {
         
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {            
            
                  //we will make sure we don't send packets for orders generated by copy operation  - it is useless to do so
                  if(isTicketOfSyncCopy(OrderTicket()))
                  {
                     continue;//do no include this order since it is one of those generated by copy operation
                  }
                 
                 //At this point the order was not generated by copy operation                 
                   
                 data += generateTradeStreamPacket();
                 new_trade_entries = true; 
            }
            
         }
    
      if(new_trade_entries){
         data += "new_trade_entries=true" + TAB;
         
         clearTicketsOfSyncCopy();//just clear off since the job is done at this time         
      }
     
                 
     string history_data = "";  
     string partial_data = "";   
     int h_total = OrdersHistoryTotal();
          
     if(h_total > HistoryTotal)
     {
         
         int diff_closed = h_total - HistoryTotal;
         
         
         for(int i= h_total - 1; i > HistoryTotal -1; i--)
         {
            if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
            { 
                        
               if(!isOrderType()){//we only want order type and not credit or balance as displayed in AccountHistory of the Terminal
                   continue;               
               }
            
               //we will make sure we don't send packets for orders generated by close operation  - it is useless to do so
               if(isTicketOfSyncClose(OrderTicket()))
               {
                  continue;//do no include this order since it is one of those generated by close operation
               }
               
               
               //At this point the order was not generated by close operation                            
               
               history_data += generateTradeStreamPacket();   
               close_trades = true;  
               //Print("history_data", history_data);       
            }
            
         }
          
        HistoryTotal = h_total;
               
     }
     
     
     if(close_trades){//append history to data to be sent
        data += history_data +  "close_trades=true" + TAB;
        
        clearTicketsOfSyncClose();//just clear off since the job is done at this time
        clearTicketsOfSyncModify();       
     }     
     
     sendData(data);
         
}

  
/*@Deprecated
void sendTradeModifyData()
{
   
      bool modify_trades = false;

      string data = "";

      int total = OrdersTotal();
      for(int i=0; i < total; i++)
         {
         
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
                 data += generateTradeStreamPacket();
                 modify_trades = true; 
            }
            
         }
    
      if(modify_trades){
         data += "modify_trades=true" + TAB;        
      }
     
     
     sendData(data);
         
}  
*/


bool AccountInfoUsedByPeer(){


      int total_orders = OrdersTotal();

      TotalCommission = 0;
      TotalLotSize = 0;
      TotalSwap = 0;
      Position = "";
                                                   
      for(int i = 0; i < total_orders; i++){
     
     
         if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
             return false; //just leave - no room for error
         }
           
         TotalLotSize += OrderLots();          
         TotalCommission += OrderCommission();  
         TotalSwap += OrderSwap();  
         Position = OrderType() == OP_BUY? "BUY" 
                     : OrderType() == OP_SELL? "SELL"
                     :"";   
        
     }
     
     return true;
}


string generateTradeStreamPacket(double partial_close_fraction = 0)
{

        string copy_sender_ticket = "";
        if(OrderMagicNumber() == COPIED_TRADE_MAGIC_NUMBER)
        {
           //copy_sender_ticket = extractCopyTicket(OrderComment());//REMOVED - Instead the server will set it
        }
            
        string position = getStrOrderType();  
          
        if(position == ""){//possibly credit or balance as displayed in the AccountHistory
            return "";
        }        
                  
        double symbol_point = getUsableSymbolPoint(OrderSymbol());
               
        string data = "ticket="+OrderTicket()+TAB
                    +"symbol="+ refactorSymbol(OrderSymbol())+TAB
                    +"raw_symbol="+OrderSymbol()+TAB
                    +"point="+symbol_point +TAB
                    +"digits="+SymbolInfoInteger(OrderSymbol(), SYMBOL_DIGITS) +TAB
                    +"position="+position+TAB
                    +"open_price="+OrderOpenPrice()+TAB
                    +"close_price="+OrderClosePrice()+TAB
                    +"open_time="+(long)OrderOpenTime()+TAB
                    +"close_time="+(long)OrderCloseTime()+TAB
                    +"lot_size="+OrderLots()+TAB
                    +"symbol_commission_per_lot="+ (OrderCommission()/OrderLots())+TAB
                    +"account_expected_hedge_profit="+ExpectedHedgeProfit+TAB
                    +"target="+OrderTakeProfit()+TAB
                    +"stoploss="+OrderStopLoss()+TAB                        
                    +"partial_close_fraction="+partial_close_fraction+TAB;
            
                              
    return data;           
}
  

bool isUpperCaseChar(ushort c)
{
   return (c>=65 && c<=90);
}  

bool isAlphabet(ushort c)
{
   return (c>=65 && c<=90) || (c>=97 && c<=122);
}  
    
string refactorSymbol(string symbol, bool retain_case = false){
      
   if(!isRegularSymbol(symbol))
   {
      return symbol;
   }
   
   int begin = -1;
   int end = -1;
   int count = 0; 
   
   StringReplace(symbol,"/",""); // remove '/' character if any
   
   int len = StringLen(symbol);
   
   for(int i = 0; i < len; i++)
   {
   
      ushort c = StringGetChar(symbol,i);
      
      if(isAlphabet(c))
      {
         count++;
         if(count == 1)
         {
            begin = i;
         }
         
         if(count == 6)
         {
            end = i;
            break;
         }
         
      }else {
         if(count < 6){
            count = 0;
         }
         
      }
   
   } 
   
   symbol = StringSubstr(symbol, begin, end + 1);
   
   int index = StringFind(symbol,"/",0);
   if(index>-1){
      return symbol;
   }
   
   symbol = StringSubstr(symbol,0,3)+"/"+StringSubstr(symbol,3,3);
   
   if(!retain_case)
   {
      StringToUpper(symbol);
   }
   
   return symbol;   
}


bool isSevenLetterPair(string pair)
{

   int len = StringLen(pair);
   
   if(len != 7)
   {
      return false;
   }
   
   int slash_count = 0;
   int slash_pos = 0;
   for(int i = 0; i < len; i++)
   {   
      slash_pos = i;
      ushort c = StringGetChar(pair,i);
      
      if(!isAlphabet(c))
      {
         if(c == '/' && slash_count == 0)
         {
            if(slash_pos != 3)
            {
               return false;
            }
            
            slash_count++;
         }
         else
         {
           return false;
         }
         
      }     
   }   

   return true;
}

bool isSixLetterPair(string pair)
{

   int len = StringLen(pair);
   
   if(len != 6)
   {
      return false;
   }
   
   for(int i = 0; i < len; i++)
   {   
      ushort c = StringGetChar(pair,i);
      
      if(!isAlphabet(c))
      {
         return false;
      }     
   }   

   return true;
}


bool isRegularSymbol(string symbol)
{

    
    string split [];
    StringSplit(symbol, '.',split);
    
    string prefix = "";
    string suffix = "";
    string pair = "";
    int split_size = ArraySize(split);
    
    if(split_size == 1)
    {
      pair = split[0];    
    }
    
    if(split_size == 2)
    {
    
       string part_1 = split[0];
       string part_2 = split[1];
       
       if(isSixLetterPair(part_1))
       {
         pair = part_1;
         prefix = part_2;         
       }
       
       if(isSevenLetterPair(part_1))
       {
         pair = part_1;
         prefix = part_2;                 
       }
       
       if(isSixLetterPair(part_2))
       {
         if(pair != "")
         {
            return false; // meaning both parts cannot be pair
         }
         
         pair = part_2;
         suffix = part_1;   
         
       }
       
       if(isSevenLetterPair(part_2))
       {
         
         if(pair != "")
         {
            return false; // meaning both part cannot be pair
         }
         
         pair = part_2;
         suffix = part_1;       
       }
    
    }
    
    
    if(split_size == 3)
    {
       prefix = split[0];
       pair = split[1];
       suffix = split[2];
       
    }
    
    if(split_size > 3)
    {
       return false;   
    }
    
    
    if(!isSixLetterPair(pair) && !isSevenLetterPair(pair))
    {  
       return false;        
    }
       
    return true;  
}

string defactorSymbol(string symb){
   
   //string symbol = "abc.USD/JPY.xyz"; //mab at work  - replace if Symbol() later
   
   if(!isRegularSymbol(symb))
   {
      return symb;
   }
   
   string symbol = Symbol(); 
   
   int begin = -1;
   int end = -1;
   int count = 0; 
   bool has_slash = StringFind(symbol, "/") > -1;
   int len = StringLen(symbol);
   
   for(int i = 0; i < len; i++)
   {
   
      ushort c = StringGetChar(symbol,i);
      
      if(isAlphabet(c) || c == '/')
      {
         count++;
         if(count == 1)
         {
            begin = i;
         }
         
         if((!has_slash && count == 6) || (has_slash && count == 7))
         {
            end = i;
            break;
         }
         
      }else {
         if((!has_slash && count < 6) || (has_slash && count < 7)){
            count = 0;
         }
         
      }
   
   }
   
   string prefix = begin > 0 ? StringSubstr(symbol,0, begin) : "";
   string suffix = StringSubstr(symbol , end + 1, len - end - 1);
      
   string s = refactorSymbol(symbol, true);
   
   if(isUpperCaseChar(StringGetChar(s,0)))
   {
      StringToUpper(symb);
   }
   else
   {
      StringToLower(symb);
   }
   
   bool symb_has_slash = StringFind(symb, "/") > -1;
   
   symb = StringSubstr(symb,begin,end-begin + 1);
   
   if(has_slash && !symb_has_slash)
   {
      symb = StringSubstr(symb,0,3)+"/"+StringSubstr(symb,3,3);     
   }
   else if(!has_slash && symb_has_slash)
   {
      StringReplace(symb,"/","");
   }
   
   return prefix+symb+suffix;
   
}


bool openConnection(){
  
  
   //--- wait for server
   
   if(!IsStopped())
     {
        
         ExtConnection = Connect(Host , Port);
                  
         bool isDisconnection = !PrintConnectionWaiting && !isConnectionOpen;
         if(ExtConnection){
            
            PrintConnectionWaiting=true;
            isConnectionOpen = true;
            Print("Client: connection opened");
            lblAlert.Text("Client: connection opened");
            return true;
         }
         
         if(PrintConnectionWaiting)
           {
            PrintConnectionWaiting=false;
            Print("Client: waiting for server");
            lblAlert.Text("Client: waiting for server");
            if(isDisconnection){
               sendEADisconnectionNotification();
            }
           }
      
     }else{
         
         if(PrintEAIsStopped)
           {
            PrintEAIsStopped=false;
            string str_print_stop = "ATTENTION: The EA has stopped running...Please reload";
            Print(str_print_stop);
            lblAlert.Text(str_print_stop);
            SendNotification(str_print_stop);
           }
     }  
   
   return false;
}

void reconnect(string error_reason, uint errCount = 1){

   string reconnMsg = errCount == 1 
                     ? "Reconnecting... after last error : "+error_reason 
                     : "Reconnecting after "+errCount+" successive errors : "+error_reason ;

   Print(reconnMsg);
   lblAlert.Text(reconnMsg);
         
   channelIfNot();   

}

string ensureWithTab(string data)
{ 
   return ensureEndWith(data, TAB);
} 

string ensureEndWithNewLine(string data)
{
   return ensureEndWith(data, NEW_LINE);
} 

string ensureEndWith(string data, string ch){

   if(data == "")
   {
      return "";//no need for new line character
   }

   if(StringSubstr(data, StringLen(data) -1, 1) != ch)
   { 
      data += ch;
   }
   
   return data;
}

void validateConnection()
{
   //We now have a far more efficient commication channel with the remote end so we 
   //will only be pinging very infrequently just to notify us if the connection is lost 
   //which is not very likely  though in this our current implementation using C++ DLL
   
   
   int timeElapseInMinutesSinceLastPing = (TimeCurrent() - lastPingTime)/60;
   
   if(timeElapseInMinutesSinceLastPing >= PING_INTERVAL_IN_MINUTES){
      lastPingTime = TimeCurrent();
      sendData(PING_PACKET);
   }
      
}
  
void sendData(string data)
{

   if(data == "")
   {
      return;
   }
   
   bool is_ping = data == PING_PACKET;
  
   data = StringTrimLeft(data); //remove tailing TAB  
   data = StringTrimRight(data);//remove tailing TAB
   
   data += TAB + "is_market_closed="+(IsMarketClosed == true ? "true": "false");
   
   data  = ensureEndWithNewLine(data);
      
   
   if(!is_ping)
   {
      //Print("sendData ",data);//TESTING!!!
   }
   
   
   uint   size_str=StringLen(data);
   
   int result = Send(data);
   
   if(result == -1)
     {
         if(!IsSocketConnected()){
         
            if(!is_ping){
               Print("Client: failed to send data because connection is closed [",GetSyncLastError(),"]"); 
               lblAlert.Text(lastSyncTradeErrorDesc());
            }else{
               Print("Pinging detected connection closed.");
               lblAlert.Text("Pinging detected connection closed.");
            }         
            
            //isConnectionOpen = false; //force the EA to reinitialize
            sendEADisconnectionNotification();
            
            return;
         }else{
            Print("Client: failed to send data [",GetSyncLastError(),"]");
            Print("Client: Contact Administrator to revolve send operation failure.");
            lblAlert.Text("Client: Contact Administrator to revolve send operation failure.");
         }
         
     }

}

string lastSyncTradeErrorDesc(){

   char errStr [255];
   GetSyncLastErrorDesc(errStr, 255);
   return CharArrayToString(errStr);
}

string receiveData(){

   int last_error = GetLastError();
   if(last_error != 0){
      Print("Client: Error occured [", ErrorDescription(last_error),"]");
      lblAlert.Text(ErrorDescription(last_error));
      ResetLastError();
   }
   
   string data;   
      
   int dataLen = GetData();      
   
   if(dataLen >= 0){
      
      fialReadCount = 0;
      
      //char buffer [10]; //@Deprecated - since it is static array it can not be resize in mql5. instead use 'char buffer []'
      
      char buffer []; //Dynamic array which can be resize in mql5      
                                    
      ArrayResize(buffer, dataLen); //resize the buffer to length of data available      
      
      if(dataLen > 0){      
         PacketReceived(buffer, dataLen);
         data = CharArrayToString(buffer);       
      }
      
      
   }else{//error occured
      
      fialReadCount++;
         
      string str_last_error = lastSyncTradeErrorDesc();         
      
                   
      if(!IsSocketConnected()){
         reconnect(str_last_error);      
      }else if(IsSocketConnected() && fialReadCount >= 3){
      
         lblAlert.Text(str_last_error);   
         Print("Client: read string failed [",str_last_error,"]");   
         
         CloseSocket();
         Sleep(300);
         reconnect(str_last_error, fialReadCount);
      }
   
   } 
   
      
   return data;
}

  
//+------------------------------------------------------------------+

