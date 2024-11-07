//+------------------------------------------------------------------+
//|                                                 SyncClientX5.mq5 |
//|                                                    Chuks Alimele |
//|                                           chuksalimele@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Chuks Alimele"
#property link      "chuksalimele@gmail.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\HistoryOrderInfo.mqh>
#include <Trade\AccountInfo.mqh>

#include <Arrays\ArrayLong.mqh>

//#include <stdlib.mqh>
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


#import "SyncTradeConnector5.dll"

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


enum ExitClearanceFactor {
   _0_PERCENT,
   _30_PERCENT,
   _50_PERCENT,
   _80_PERCENT,
   _100_PERCENT,
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class VirtualSync: public CObject {
public:
   ulong             own_ticket;
public:
   ulong             peer_ticket;
public:
   double            peer_stoploss;
public:
   double            peer_spread_point;
public:
   bool              IsHitPeerStoploss;


public:
   VirtualSync(void) {};
   ~VirtualSync(void) {};
};


bool SyncCopyManualEntry = false;// Sync copy manual entry
ExitClearanceFactor exitClearanceFactor = _30_PERCENT;// Exit clearance factor
bool OnlyTradeWithCredit = false;// Only trade with credit.



enum TradeMode {
   PACKET,
   LIVE
};

//int ExtConnection=-1;
struct MarketPrice {
   string            symbol;
   double            bid;
   double            ask;
};

struct TradePacket {
   string            command;
   string            command_id;
   string            action;
   string            uuid;
   string            force;
   string            reason;
   string            origin_ticket;

   string            immediate;

   string            peer_broker;
   string            peer_account_number;

   ulong             own_ticket;
   ulong             peer_ticket;
   double            peer_stoploss;
   double            peer_spread_point;

   string            symbol;
   ulong             ticket;
   string            position;
   double            lot_size;
   double            open_price;
   long              signal_time;
   long              close_time;
   long              open_time;
   double            target;//target price
   double            stoploss;//stoploss price
   double            spread_point;
   string            copy_type;

   double            floating_balance;
   double            account_balance;

   double            partial_closed_lot_fraction;

   string            sync_state_paird_id;
};

struct ChangeStats {

   bool              TradeCountChanged;
   bool              TradeCountIncreased;
   bool              TradeModified;
   bool              TradeSwapChanged;

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
datetime HistoryFromTime = 0;
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


struct PacketOrder {

   string            position;
   string            symbol;
   ulong             ticket;
   double            open_price;
   double            close_price;
   datetime          open_time;
   double            close_time;
   double            lot_size;
   double            target;
   double            stoploss;
   ulong             magic;
   double            commission;

};

CTrade              tradeObj;                      // trading object
CAccountInfo        accountObj;                     // symbol info object
CSymbolInfo         symbolObj;                     // symbol info object
COrderInfo          orderObj;                      // trade order object
CHistoryOrderInfo   historyOrderObj;                      // trade order object
CPositionInfo       positionObj;                   // trade position object


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

CArrayLong *OpenTicketList = new CArrayLong; //any enlisted ticket that is not found by the positionObj is assumed to be closed

//+------------------------------------------------------------------+
void computeStoploss() {
   symbolObj.Name(Symbol());

   if(PositionsTotal() == 0) {
      LastAutoModifiedTarget = 0;
      return;
   }

   double StopLossAtStopOut = 0;

   int positions_total = PositionsTotal();//open positions
   string symbol = "";
   double total_lots = 0;
   double total_commission = 0;
   double total_swap = 0;
   double open_price = 0;
   for(int i = 0; i < positions_total; i++) {


      if(!positionObj.SelectByIndex(i)) {
         return; //just leave - no room for error
      }

      if(i == 0) { //just use the open price of the first order - that is the best we can do
         open_price = positionObj.PriceOpen();
      }

      symbol = positionObj.Symbol();
      total_lots += positionObj.Volume();
      total_commission += positionObj.Commission();
      total_swap += positionObj.Swap();

   }


   double BuyStopLossAtStopOut = determinePriceAtOwnStopout(POSITION_TYPE_BUY, open_price, symbol, total_lots, total_commission, total_swap);
   double SellStopLossAtStopOut = determinePriceAtOwnStopout(POSITION_TYPE_SELL, open_price, symbol, total_lots, total_commission, total_swap);

   if(BuyStopLossAtStopOut == open_price || SellStopLossAtStopOut == open_price) {
      //This is possible in some symbols of certain broker e.g HK50 in Blueberry
      //where the symbol tick value is zero most of the time
      return;
   }


   for(int i = 0; i < positions_total; i++) {


      if(!positionObj.SelectByIndex(i)) {
         return; //just leave - no room for error
      }

      int SymbolDigits = ensureSameSymboDigitsWithPeer();

      if(SymbolDigits == UNDEFINED) {
         return;
      }

      double order_lots = positionObj.Volume();// chuks - added to avoid strange division by zero - see comment below

      if(order_lots == 0) { // chuks - added to avoid strange division by zero - see comment below
         return;
      }

      /*@Deprecated - replace by if block below
       if(order_lots * 1000 < accountObj.Balance()/1000){
         return; //skip since the lot size is too small
      }*/

      if(order_lots < SymbolInfoDouble(positionObj.Symbol(), SYMBOL_VOLUME_MIN)) {
         return; //skip since the lot size is too small
      }

      if(((positionObj.PositionType() == POSITION_TYPE_BUY))) {
         WorkingPosition =  POSITION_TYPE_BUY;

         //NOTE: in the case of BUY position NO NEED TO compensate for exit spread since the exit price is at BID price
         //so we always expect the stoploss price to be hit. Note this is not the case for SELL side which can cause
         //premature hunting of the stoploss price since the Ask price is hit which is before the actual stoploss
         StopLossAtStopOut = BuyStopLossAtStopOut;

         if(IsMarketJustOpen || NormalizeDouble(StopLossAtStopOut, SymbolDigits) !=  NormalizeDouble(positionObj.StopLoss(), SymbolDigits)) {
            tradeObj.PositionModify(positionObj.Ticket(), StopLossAtStopOut, positionObj.TakeProfit());
            if(IsTradeRequestSuccessful()) {
               sendData(stoplossPacket(StopLossAtStopOut));
            } else {
               string error = tradeObj.ResultRetcodeDescription();
               if(error == "Market is closed") {
                  IsMarketClosed = true;
               }
            }
         }
      }

      if(((positionObj.PositionType() == POSITION_TYPE_SELL))) {
         WorkingPosition =  POSITION_TYPE_SELL;

         StopLossAtStopOut = SellStopLossAtStopOut ;
         if(IsMarketJustOpen || NormalizeDouble(StopLossAtStopOut, SymbolDigits) !=  NormalizeDouble(positionObj.StopLoss(), SymbolDigits)) {
            tradeObj.PositionModify(positionObj.Ticket(), StopLossAtStopOut, positionObj.TakeProfit());

            if(IsTradeRequestSuccessful()) {
               sendData(stoplossPacket(StopLossAtStopOut));
            } else {
               string error = tradeObj.ResultRetcodeDescription();
               if(error == "Market is closed") {
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
     
     int total_positions   = PositionsTotal();
     
     double safety_spread_point = PeerSafetySpread * Point(); 

     for(int i = 0; i < total_positions; i++){
     
     
        if(!positionObj.SelectByIndex(i)) {
           return; //just leave - no room for error
        }                                        
                
        trade.ticket = positionObj.Ticket();
        trade.symbol = positionObj.Symbol();
        trade.signal_time = TimeCurrent(); //come back
                
        int SymbolDigits = ensureSameSymboDigitsWithPeer();
        
        if(SymbolDigits == UNDEFINED){
            return;
        }
        
        string data = "";

        if(PeerPosition == POSITION_TYPE_BUY)
        {                     
           double TargetAtPeerStopOut = determinePriceAtPeerStopout() + safety_spread_point;                       
           
           if(NormalizeDouble(TargetAtPeerStopOut, SymbolDigits) !=  NormalizeDouble(positionObj.TakeProfit(), SymbolDigits))
           {
              tradeObj.PositionModify(positionObj.Ticket(), positionObj.StopLoss(), TargetAtPeerStopOut);                                              
              if(IsTradeRequestSuccessful())
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
                                
        if(PeerPosition == POSITION_TYPE_SELL)
        {
           double TargetAtPeerStopOut = determinePriceAtPeerStopout() - safety_spread_point;                 
           
           if(NormalizeDouble(TargetAtPeerStopOut, SymbolDigits) !=  NormalizeDouble(positionObj.TakeProfit(), SymbolDigits))
           {                                     
              tradeObj.PositionModify(positionObj.Ticket(), positionObj.StopLoss(), TargetAtPeerStopOut);                                              
              if(IsTradeRequestSuccessful())
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ensureSameSymboDigitsWithPeer() {

   int OwnSymbolDigits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);

   if(PeerRealSymbolDigits == UNDEFINED) {
      return UNDEFINED;
   } else if(PeerRealSymbolDigits < OwnSymbolDigits) {
      return PeerRealSymbolDigits; // using the smaller digit
   } else {
      return OwnSymbolDigits;
   }

}


//--------------------------------------------------------------------------------------------------
//Get the base open price. That is the position with mininum open price for BUY and maximum for SELL
//---------------------------------------------------------------------------------------------------
double baseOpenPrice(){
        
      int positions_total = PositionsTotal();//open positions
        
      //base open price is the lowest of the trade for BUY and the Highest for SELL
      double base_buy_open_price = INT_MIN; 
      double base_sell_open_price = INT_MAX; 
      for(int i = 0; i < positions_total; i++){
     
     
         if(!positionObj.SelectByIndex(i)){
             return 0; //just leave - no room for error
         }
           
         if(positionObj.PositionType() == POSITION_TYPE_BUY){
             //get the maximum
             if(positionObj.PriceOpen() > base_buy_open_price){ 
                  base_buy_open_price = positionObj.PriceOpen();
             }
           
         }else if(positionObj.PositionType() == POSITION_TYPE_SELL){
             //get the mininum
             if(positionObj.PriceOpen() < base_sell_open_price){
                 base_sell_open_price = positionObj.PriceOpen();
             }           
         }else{
            return 0;
         }
        
      }
   

      if(positionObj.PositionType() == POSITION_TYPE_BUY){           
         return base_buy_open_price;  
      }else if(positionObj.PositionType() == POSITION_TYPE_SELL){
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
      int positions_total = PositionsTotal();//open positions
      double total_lots = 0;
            
      for(int i = 0; i < positions_total; i++){
     
     
         if(!positionObj.SelectByIndex(i)){
             return 0; //just leave - no room for error
         }
           
         total_drift += positionObj.Volume() * MathAbs(positionObj.PriceOpen() - base_open_price);  
         total_lots += positionObj.Volume();          
        
     }
     
     
     
     double drift_per_lot = total_drift / total_lots;
     
//Print("base_open_price ",base_open_price, " total_drift ", total_drift, " positions_total ", positions_total," drift_per_lot ",drift_per_lot);     
         
     return drift_per_lot;
}


double getTotalLotSize(){

      int positions_total = PositionsTotal();//open positions
      double total_lots = 0;
            
      for(int i = 0; i < positions_total; i++){
          
         if(!positionObj.SelectByIndex(i)){
             return 0; //just leave - no room for error
         }
           
         total_lots += positionObj.Volume();          
        
     }
          
     return total_lots;
}

double determinePriceAtOwnStopout(double pos, double open_price, string symbol, double total_lots, double total_commission, double total_swap){    


   double contract_size =  SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);

   double base_open_price = baseOpenPrice();
   
   return determineStopout( accountObj.Balance(),
                            accountObj.Credit(), 
                            total_commission,
                            total_swap,
                            accountObj.Margin(), 
                            accountObj.MarginStopOut(),
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
   
   if(position == POSITION_TYPE_BUY){
      stoploss = base_open_price - E;   
   }else if(position == POSITION_TYPE_SELL){   
      stoploss = base_open_price + E;
   }   
   
    string strPos = position == POSITION_TYPE_BUY ? "BUY": "SELL";
   
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


//+------------------------------------------------------------------+
//|@Deprecated                                                                       |
//+------------------------------------------------------------------+
double determinePriceAtStopout_OLD(double pos, double open_price, string symbol, double total_lots, double total_commission, double total_swap){    

    
   double margin =  accountObj.Margin();
   double stopout_margin = margin * accountObj.MarginStopOut() / 100;
   double stopout_loss = accountObj.Balance() + accountObj.Credit() + total_commission + total_swap - stopout_margin;
   double stopout_pip_move = ammountToPips(stopout_loss, total_lots, symbol);
   double stopout_points_move = stopout_pip_move * getUsableSymbolPoint(symbol);


   
   double base_open_price = baseOpenPrice();
   
   double pips_point_drift_per_lot = pipsPointDriftPerLot(base_open_price);   

//Print("pips_point_drift_per_lot ", pips_point_drift_per_lot);
     
   double stoploss = 0;
   
   if(pos == POSITION_TYPE_BUY){
      stoploss = base_open_price - stopout_points_move - pips_point_drift_per_lot;   
   }else if(pos == POSITION_TYPE_SELL){   
      stoploss = base_open_price + stopout_points_move + pips_point_drift_per_lot;
   }
      
   

   return stoploss;
}


//+------------------------------------------------------------------+
//|@Deprecated                                                                  |
//+------------------------------------------------------------------+
double determinePriceAtStopout_OLDER(double pos, double open_price, string symbol, double total_lots, double total_commission, double total_swap) {
   double margin =  accountObj.Margin();
   double stopout_margin = margin * accountObj.MarginStopOut() / 100;
   double stopout_loss = accountObj.Balance() + accountObj.Credit() + total_commission + total_swap - stopout_margin;
   double stopout_pip_move = ammountToPips(stopout_loss, total_lots, symbol);
   double stopout_points_move = stopout_pip_move * getUsableSymbolPoint(symbol);
   double stoploss = 0;

   if(pos == POSITION_TYPE_BUY) {
      stoploss = open_price - stopout_points_move;
   } else if(pos == POSITION_TYPE_SELL) {
      stoploss = open_price + stopout_points_move;
   }


   return stoploss;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double ammountToPips(double amount, double lots, string symbol) {

   double syb_tick_value = symbolTickValue(symbol); // MAY NOT BE NEEDED HERE
// SEE HACK SOLUTION BELOW

   if(syb_tick_value == 0) {
      //This is possible in some symbols of certain broker e.g HK50 in Blueberry
      return 0;
   }

   syb_tick_value = 1; //This is a just hack solution.
//Since we are using getUsuableSymbolPoint
//where the Tick size is Divided by the tick value it is
//reasonable to set the tick value to 1 for all symbols in
//just the case

   double contract_size =  SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);   
   double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   
   double multiplier = contract_size * tick_size ;   

   return amount /(lots * multiplier);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double symbolTickValue(string symbol) {
   double value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);

//NOTE: Because of a weird observation where the Tick Value changes very slightly
//but approximately the same leading to unnecessary computation of Stoploss
//and resulting in frequent triggering of stoploss_changed events we will simply return the
//the last known tick value if the difference with the current tick value is negligibe
//such as 0.00001



   double diff = MathAbs(value - PrevTickValue);

   if(PrevTickValue > 0 && diff <= TickValueVariance) {
      value = PrevTickValue;
   } else if(PrevTickValue > 0 && TickValueVariance < MAX_TICK_VALUES_VARIANCE) {

      double prevTickValueVar = TickValueVariance;
      TickValueVariance *= 10;

      PrintFormat("INCREASE TICK VALUES VARIANCE FROM %f to %f TO PREVENT FREQUENT STOPLOSS CHANGES", prevTickValueVar, TickValueVariance);


      if(diff <= TickValueVariance) {
         value = PrevTickValue;
      }
   } else if(PrevTickValue > 0) {
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void WriteComment(double open_price, double stop_loss, string symbol, double total_lots, double total_commission, double total_swap) {

   double symbol_point = getUsableSymbolPoint(symbol);

   Comment("MARGIN: ",accountObj.Margin(),
           "\nSTOPOUT: ",accountObj.MarginStopOut(),
           "\nLEVERAGE: ",accountObj.Leverage(),
           "\nACCOUNT BALANCE: ",accountObj.Balance(),
           "\nCREDIT VALUE:",accountObj.Credit(),
           "\nTOTAL SWAP: ",total_swap,
           "\nTICK VALUE: ",symbolTickValue(symbol),
           "\nSPREAD: ",symbolObj.Spread(),
           "\nUSING EXIT SPREAD: ",(int)(ExitSpreadPoint/symbol_point),
           "\nTOTAL LOT SIZE: ",total_lots,
           "\nTOTAL COMMISSION: ",total_commission,
           "\nFIRST ORDER OPEN PRICE: ",open_price,
           "\nORDER STOPLOSS: ", stop_loss);

}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string stoplossPacket(double stoploss) {

   double symbol_point = getUsableSymbolPoint(positionObj.Symbol());

   return "ticket="+positionObj.Ticket()+TAB
          + "stoploss_change_time="+(long)TimeCurrent()+TAB
          + "stoploss_changed=true"+TAB
          + "point="+symbol_point +TAB
          + "digits="+SymbolInfoInteger(positionObj.Symbol(), SYMBOL_DIGITS) +TAB
          + "stoploss="+stoploss+TAB;

}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   HistoryFromTime = TimeCurrent();
   tradeObj.SetExpertMagicNumber(COPIED_TRADE_MAGIC_NUMBER);
   tradeObj.SetMarginMode();

   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) {
      MessageBox("Automated trading is not allowed in the terminal settings!", "FAILED", MB_ICONERROR);
      return INIT_FAILED;
   }

   if(!MQLInfoInteger(MQL_TRADE_ALLOWED)) {
      MessageBox("Live trading is not enabled. Please enable Allow Live Trading!\nHint: Ensure Allow Algo Trading checkbox is checked on EA properties dialog!", "FAILED", MB_ICONERROR);
      return INIT_FAILED;
   }

   if(!MQLInfoInteger(MQL_DLLS_ALLOWED)) {
      MessageBox("This EA uses DLL but DLL is not yet enabled!\n\nHint: Click on 'Allow DLL imports' on Expert Properties dialog", "FAILED", MB_ICONERROR);
      return INIT_FAILED;
   }

   /* @Deprecate - this can cause unexpected behaviour if the terminal is restarted due to connection lost
                    instead we will validate for ACCOUNT_TRADE_EXPERT before placing order
   if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT)) {
         MessageBox("Automated trading is forbidden for the account " +AccountInfoInteger(ACCOUNT_LOGIN)
         +" at the trade server side", "FAILED", MB_ICONERROR);
         return INIT_FAILED;
   }*/

   /* @Deprecate - this can cause unexpected behaviour if the terminal is restarted due to connection lost
                   instead we will validate for TERMINAL_CONNECTED and ACCOUNT_TRADE_ALLOWED before placing order
   if(TerminalInfoInteger(TERMINAL_CONNECTED) && !AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)) {
      MessageBox("Trading is forbidden for the account "+AccountInfoInteger(ACCOUNT_LOGIN) +
            ".\n Perhaps an investor password has been used to connect to the trading account."+
            "\n Check the terminal journal for the following entry:"+
            "\n\'"+AccountInfoInteger(ACCOUNT_LOGIN)+"\': trading has been disabled - investor mode.", "FAILED", MB_ICONERROR);
      return INIT_FAILED;
   }
   */



   if(exitClearanceFactor == _0_PERCENT) {
      EXIT_CLEARANCE_FACTOR = 0;
   } else if(exitClearanceFactor == _30_PERCENT) {
      EXIT_CLEARANCE_FACTOR = 0.3;
   } else if(exitClearanceFactor == _50_PERCENT) {
      EXIT_CLEARANCE_FACTOR = 0.5;
   } else if(exitClearanceFactor == _80_PERCENT) {
      EXIT_CLEARANCE_FACTOR = 0.8;
   } else if(exitClearanceFactor == _100_PERCENT) {
      EXIT_CLEARANCE_FACTOR = 1;
   }

   MyAccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   
   
   //Store already open Tickets
   int total_positions = PositionsTotal();
   for(int i=0; i < total_positions; i++) {
      if(positionObj.SelectByIndex(i)) {      
         if(positionObj.Magic() != COPIED_TRADE_MAGIC_NUMBER){
            continue; //we only want trade opened by this EA
         }
         if(positionObj.Time() <  HistoryFromTime){
            HistoryFromTime = positionObj.Time();
         } 
         ulong pos_ticket = positionObj.Ticket();
         
         if(OpenTicketList.SearchLinear(pos_ticket) == -1) { //store open position tickets
            OpenTicketList.Add(pos_ticket);
         }
      }

   }   
   

//--- create timer
   RunTimerIfNot();

//clear previous comments
   Comment("");

   if(SyncCopyManualEntry) {
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
            
            ushort c = StringGetCharacter(symbol, i);
            
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
         
         if(up_case_base_currency == AccountInfoString(ACCOUNT_CURRENCY)){
            //e.g USDJPY if Account currency is USD
            SymbolForMarginReqirement = Symbol();
            return iClose(SymbolForMarginReqirement,0,0) != 0;         
         }
         
         //At this point the base currency is not the AccountCurrency() usually USD
         
         //Now replace the quote currency with the Account Currency 
         char symbol_arr[];        
         StringToCharArray(symbol, symbol_arr);
         
         char quote_currency_arr[];        
         StringToCharArray(AccountInfoString(ACCOUNT_CURRENCY), quote_currency_arr);
                  
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


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void startUpEA(string init_msg = NULL) {

//string init_msg = "Initializing EA...";

   if(init_msg != NULL) {
      Print(init_msg);
      lblAlert.Text(init_msg);
   }

//initControlVariables(); NO NEED

   HistorySelect(HistoryFromTime, TimeCurrent());

   HistoryTotal = HistoryOrdersTotal();

   sendIntro();
   sendDataAttrForSyncStateID();
   sendSyncOrdersData();

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sendIntro() {

   string ea_executable_file = StringSubstr(__PATH__, 0, StringLen(__PATH__) -3) + "ex"+ StringSubstr(__PATH__, StringLen(__PATH__) -1);

   string data =  "intro=true"+TAB
                  +"version="+VERSION+TAB
                  +"is_live_account="+(AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL)+TAB
                  +"broker="+AccountInfoString(ACCOUNT_COMPANY)+TAB
                  +"account_number="+AccountInfoInteger(ACCOUNT_LOGIN)+TAB
                  +"account_name="+AccountInfoString(ACCOUNT_NAME)+TAB
                  +"terminal_path="+TerminalInfoString(TERMINAL_PATH)+TAB
                  +"platform_type="+getPlatformType()+TAB
                  +"sync_copy_manual_entry="+SyncCopyManualEntry+TAB
                  +"ea_executable_file="+ea_executable_file+TAB
                  +accountInfoPacket();

   sendTradeData(data);
   IsIntroRequired = false;

}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // Event ID
                  const long& lparam,   // Parameter of type long event
                  const double& dparam, // Parameter of type double event
                  const string& sparam  // Parameter of type string events
                 ) {

   if(id == CHARTEVENT_OBJECT_CLICK) {

      if(StringFind(sparam, "lstPeerTicketsView"+"Item") == 0) {
         int len = StringLen("lstPeerTicketsView"+"Item");
         int selecteItemIndex = (int)StringToInteger(StringSubstr(sparam, len));
         lstPeerTicketsView.Select(selecteItemIndex);

         updatePeerStoplossLabelsUI(lstPeerTicketsView.Select());

      }

   }


}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void updatePeerStoplossLabelsUI(string selectedPeerTicket) {

   int symb_digit = SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);

   for(int i = 0; i < vSyncList.Total(); i++) {

      VirtualSync *vSync = vSyncList.GetNodeAtIndex(i);

      if(vSync.peer_ticket == selectedPeerTicket) {

         lblPeerStoploss.Text(NormalizeDouble(vSync.peer_stoploss, symb_digit));

         double clearance = exitClearance(vSync);

         int cpercent = EXIT_CLEARANCE_FACTOR*100;
         int spread = (int)(vSync.peer_spread_point / getUsableSymbolPoint(positionObj.Symbol()));
         string str_less_peer_spread = "( Less "+EXIT_CLEARANCE_FACTOR*100
                                       +"% peer spread of "+spread+" )";

         if(WorkingPosition == POSITION_TYPE_BUY) {
            lblActualExit.Text(NormalizeDouble(vSync.peer_stoploss - clearance, symb_digit));
            labelActualExit.Text("Exit at Bid >=");

         } else if(WorkingPosition == POSITION_TYPE_SELL) {
            lblActualExit.Text(NormalizeDouble(vSync.peer_stoploss + clearance, symb_digit));
            labelActualExit.Text("Exit at Ask <=");
         }

         labelLessPeerSpread.Text(str_less_peer_spread);

         break;
      }

   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void creatGUI() {


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
   lblBalance.Text(DoubleToString(NormalizeDouble((float)accountObj.Balance(), 2),2)+ " "+accountObj.Currency());




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
                               + " " + accountObj.Currency()
                               + " to " + NormalizeDouble(ExpectedTargetProfit, 2)
                               + " " + accountObj.Currency());



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
                                + " " + accountObj.Currency()
                                + " to " + NormalizeDouble(ExpectedTargetBalance, 2)
                                + " " + accountObj.Currency());



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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getPlatformType() {

   int len = StringLen(__FILE__);
   string ext = StringSubstr(__FILE__,len -3);
   if(ext == "mq4") {
      return "mt4";
   } else if(ext == "mq5") {
      return "mt5";
   }

   return "";
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void RunTimerIfNot() {
   if(!IsTimerRunning) {
      if(EventSetMillisecondTimer(RUN_INTERVAL)) {
         IsTimerRunning = true;
         Print("Timer set succesfully...");
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void initControlVariables() {

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
void OnDeinit(const int reason) {

//Close the communication channel
   CloseSocket();

//destroy timer
   EventKillTimer();

   delete OpenTicketList;

   delete vSyncList;

   lstPeerTicketsView.ItemsClear();

   dialog.Destroy();

   if(reason > 1) {

      ExpertRemove();//Prevent Reinitialization of this EA
      string attentMsg = "ATTENTION!!! SyncTradeClient has been removed";

      switch(reason) {
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
void OnTick() {
//---

   if(IsMarketClosed) {
      IsMarketJustOpen = true;
   }

   IsMarketClosed = false;

   RunTimerIfNot();

   isConnectionOpen = IsSocketConnected();

   if(isConnectionOpen == false) {
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
void OnTimer() {
   doRun();
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Terminate(string msg=NULL) {
   if(IsTerminated) {
      return;
   }

   CloseSocket();

   if(msg!=NULL) {
      PlaySound("alert.wav");
      MessageBox(msg);
   }

   ExpertRemove();
   IsTerminated = true;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void resartTerminalOnConnectionLost() {

   if(!TerminalInfoInteger(TERMINAL_CONNECTED)) {
      if(lastConnectionAvailsbleTime == 0) {
         return;
      }

      ulong elapse = (ulong)(TimeLocal() - lastConnectionAvailsbleTime);

      ulong max_time = MAX_ALLOW_TERMINAL_DISCONNECTED_MINUTE * 60;

      ulong half_time = max_time /2;

      if(!isPrintAboutToRestart
            &&  max_time > 10
            && elapse > half_time) {
         string msg = StringFormat("Connection lost detected! Possibly terminal Is Outdated. Will restart terminal in about %d seconds if the connection is not restored.", half_time);
         Print(msg);
         Alert(msg);
         isPrintAboutToRestart = true;
      }

      if(!isWillRestartTerminalSent && elapse > max_time) {
         string data= "will_restart_due_to_connection_lost="+TerminalInfoString(TERMINAL_PATH)+TAB;
         sendData(data);
         isWillRestartTerminalSent = true;
      }


   } else {
      lastConnectionAvailsbleTime = TimeLocal();
   }

}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void doRun() {

   resartTerminalOnConnectionLost();

   if(PositionsTotal() == 0) {
      //initControlVariables(); //bug
   }

   double startTime = GetTickCount();

   if(Terminating) {
      Terminate();
      return;
   }


   lastKnownServerTime = TimeCurrent();

   if(TimeCurrent() > lastKnownServerTime) {
      IsMarketClosed = false;
   }

   int error_code = GetLastError();

   if(lastErrorCode != error_code) {
      lastErrorCode = error_code;
      if(lastErrorCode == 132) {

         IsMarketClosed = true;
      }
   }



   if(!channelIfNot()) {
      return;
   }


   validateConnection();

   if(IsIntroRequired) {
      if(StringLen(accountObj.Company()) > 0) {
         sendIntro();
      }
   }

   sendPlaceOrderData();

   handleAccountBalanceChanged();

   ChangeStats stats;

   if(isOrderTradeStatusChange(stats)) {
      if(stats.TradeCountChanged) {
         trimVirtualSyncList();
         TradeAnalyze();
         sendTradeData();
         sendDataAttrForSyncStateID();
      }
     
      /*if(stats.TradeCountIncreased)
      {
          sendPeerTakeProfitParam();
      }*/   
        
      if(stats.TradeModified) {
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool channelIfNot() {


   if(IsSocketConnected() == false) {

      if(!openConnection()) {
         return false;
      }

      startUpEA();

      if(isConnectionOpen) {
         lblAlert.Text(strRuning);
      }
   }


   return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void handleNotifications() {


   int last_trade_count = NtTradeCount;
   NtTradeCount = PositionsTotal();

   if(NtTradeCount == 0 && last_trade_count > 0) {
      SendNotification(StringFormat("TRADE CLOSED\nBal: %s %s", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2), AccountInfoString(ACCOUNT_CURRENCY)));

   }


}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sendUnpairedNotification(TradePacket &trade) {
   SendNotification(StringFormat("UNPAIRED DETECTED - Peer [%s, %s]", trade.peer_broker, trade.peer_account_number));
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sendEADisconnectionNotification() {
   SendNotification("ATTENTION!!! EA Disconnected from pipe server. Waiting...");
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void reestablishedPairingNotification() {
   SendNotification("PAIRING RE-ESTABLISHED SUCCESSFULLY AFTER TERMINAL RESTART");
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void restartedTerminalNotification() {
   SendNotification("TERMINAL HAS BEEN RESTARTED AND RESTORED BACK ONLINE AFTER OFFLINE DETECTION");
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void peerTerminalToRestartNotification(TradePacket &trade) {
   SendNotification(StringFormat("PEER OFFLINE DETECTED - Peer [%s, %s]\n\n Peer terminal will restart", trade.peer_broker, trade.peer_account_number));
}


void peerTerminalToRestartConfirmNotification(TradePacket &trade){
   SendNotification(StringFormat("PEER OFFLINE DETECTED \n\n ATTENTION NEEDED \n\n Peer [%s, %s]\n\n Peer terminal needs restart", trade.peer_broker, trade.peer_account_number));
}   



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void reportPeerTerminalToRestartFailed(TradePacket &trade) {
   string report = StringFormat("FAILED - ATTENTION NEEDED: Could not restart peer terminal after offline detection: Peer [%s, %s]", trade.peer_broker, trade.peer_account_number);
   SendNotification(report);
   Alert(report);
   Print(report);
}


//------------------------------------------------------
//Remove virtual sync objects representing closed trades
//------------------------------------------------------
void trimVirtualSyncList() {


   for(int i = 0; i < vSyncList.Total(); i++) {

      VirtualSync *vSync = vSyncList.GetNodeAtIndex(i);

      if(SelectPositionByTicket(vSync.own_ticket) == false) {

         //NO NEED SINCE IF THE SELECT OF THE POSITION ORDER IS FALSE THE ORDER IS CLOSED SINCE BY THE PRESENT OF THE TICKET THE ORDER WAS ONCE OPENED
         /*if(!OrderCloseTime()){
           continue; // skip since we only need closed orders
         }*/

         //At this point the order is closed

         //Print("for i = ", i);
         //Print("About to deleted vSync.own_ticket ", vSync.own_ticket);
         //Print("Before deleted vSyncList.Total() ", vSyncList.Total());

         vSyncList.Delete(i); //delete from sync list

         lstPeerTicketsView.ItemDelete(i); //alsO delete from GUI list view

         i--;


         //Print("Deleted vSync.own_ticket", vSync.own_ticket);
         //Print("After deleted vSyncList.Total() ", vSyncList.Total());

         continue;
      }

   }


}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TradeAnalyze() {

   int positions_total = PositionsTotal();//open positions

   AccountSwapCost = 0;
   AccountCommissionCost = 0;
   AccountSwapPerDay = 0;
   AccountTradeCost = 0;
   ExpectedHedgeProfit = 0;
   for(int i=0; i < positions_total; i++) {

      if(positionObj.SelectByIndex(i)) {

         AccountTradeCost += positionObj.Commission() + positionObj.Swap();

         if(positionObj.PositionType() == POSITION_TYPE_BUY) {
            AccountSwapPerDay += SymbolInfoDouble(positionObj.Symbol(), SYMBOL_SWAP_LONG);
         }

         if(positionObj.PositionType() == POSITION_TYPE_SELL) {
            AccountSwapPerDay += SymbolInfoDouble(positionObj.Symbol(), SYMBOL_SWAP_SHORT);
         }

         AccountSwapCost += positionObj.Swap();
         AccountCommissionCost += positionObj.Commission();

         //calculate entry spread - I AM ASSUMING THIS CALCULATION IS CORRECT - come back to confirm correctness
         /*
         // IT HAS BEEN CONFIRMED THAT SPREAD COST CANNOT BE DETERMINED THIS WAY
         double pip_move = MathAbs(OrderOpenPrice() - OrderClosePrice())/getUsableSymbolPoint(positionObj.Symbol());
         double profit = pip_move * positionObj.Volume() * symbolTickValue(positionObj.Symbol()) * 10;
         double entry_spread_cost = profit - (OrderProfit() - positionObj.Commission() - positionObj.Swap());
         */

         //UNCOMMENT THE LINE BELOW IF THE ABOVE CALCULATION IS NOT CORRECT.
         //LETS MANAGE THE FAIRLY ACCURATE ONE BELOW WHICH DOES ONLY GIVE
         //THE CURRENT MARKET SPREAD OF THE SYMBOL AND NOT ITS ENTRY SPREAD

         double current_spread_pips = MathAbs(SymbolInfoDouble(positionObj.Symbol(), SYMBOL_ASK) - SymbolInfoDouble(positionObj.Symbol(), SYMBOL_BID))/getUsableSymbolPoint(positionObj.Symbol());
         double entry_spread_cost = current_spread_pips * positionObj.Volume() * SymbolInfoDouble(positionObj.Symbol(), SYMBOL_TRADE_TICK_VALUE);

         AccountTradeCost -= entry_spread_cost;

         double pip_win = MathAbs(positionObj.PriceOpen() - positionObj.TakeProfit())/getUsableSymbolPoint(positionObj.Symbol());
         double target_profit = pip_win * positionObj.Volume() * symbolTickValue(positionObj.Symbol());
         ExpectedHedgeProfit = target_profit;

      }


   }
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string accountInfoPacket() {
   long trade_allowed_for_symbol = SymbolInfoInteger(Symbol(), SYMBOL_TRADE_MODE);
// not yet tested!
   bool chart_symbol_trade_allowed = trade_allowed_for_symbol == SYMBOL_TRADE_MODE_FULL; //we are interest in full access

   return "account_balance="+AccountInfoDouble(ACCOUNT_BALANCE)+TAB
          +"account_equity="+AccountInfoDouble(ACCOUNT_EQUITY)+TAB
          +"account_credit="+AccountInfoDouble(ACCOUNT_CREDIT)+TAB
          +"account_currency="+AccountInfoString(ACCOUNT_CURRENCY)+TAB
          +"account_leverage="+AccountInfoInteger(ACCOUNT_LEVERAGE)+TAB
          +"account_margin="+AccountInfoDouble(ACCOUNT_MARGIN)+TAB
          +"account_stopout_level="+AccountInfoDouble(ACCOUNT_MARGIN_SO_SO)+TAB
          +"account_profit="+AccountInfoDouble(ACCOUNT_PROFIT)+TAB
          +"account_free_margin="+AccountInfoDouble(ACCOUNT_MARGIN_FREE)+TAB
          +"account_swap_per_day="+AccountSwapPerDay+TAB
          +"account_swap_cost="+AccountSwapCost+TAB
          +"account_commission_cost="+AccountCommissionCost+TAB
          +"account_trade_cost="+AccountTradeCost+TAB
          +"total_open_orders="+PositionsTotal()+TAB 
          +"chart_symbol="+Symbol()+TAB
          +"chart_symbol_digits="+SymbolInfoInteger(Symbol(), SYMBOL_DIGITS)+TAB
          +"chart_symbol_max_lot_size="+SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX)+TAB
          +"chart_symbol_min_lot_size="+SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN)+TAB
          +"chart_symbol_tick_value="+symbolTickValue(Symbol())+TAB
          +"chart_symbol_tick_size="+SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE)+TAB
          +"chart_symbol_swap_long="+SymbolInfoDouble(Symbol(), SYMBOL_SWAP_LONG)+TAB
          +"chart_symbol_swap_short="+SymbolInfoDouble(Symbol(), SYMBOL_SWAP_SHORT)+TAB
          +"chart_symbol_spread="+SymbolInfoInteger(Symbol(), SYMBOL_SPREAD)+TAB
          +"chart_symbol_trade_units="+SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE)+TAB
          +"chart_market_price="+iClose(NULL,PERIOD_CURRENT,0)+TAB
          +"exchange_rate_for_margin_requirement="+iClose(SymbolForMarginReqirement,0,0)+TAB
          +"expected_exit_profit="+ExpectedExitProfit+TAB
          +"expected_target_profit="+ExpectedTargetProfit+TAB
          +"expected_exit_balance="+ExpectedExitBalance+TAB
          +"expected_target_balance="+ExpectedTargetBalance+TAB
          +"terminal_connected="+(TerminalInfoInteger(TERMINAL_CONNECTED)?"true":"false")+TAB
          +"only_trade_with_credit="+(OnlyTradeWithCredit?"true":"false")+TAB
          +"chart_symbol_trade_allowed="+(chart_symbol_trade_allowed?"true":"false")+TAB
          +"sync_state_pair_id="+SyncStatePairID+TAB;


}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sendAccountInfo() {
   sendData(accountInfoPacket());
}


void sendPeerTakeProfitParam(){

           
     AccountInfoUsedByPeer();                  
               
     string data = "account_margin="+AccountInfoDouble(ACCOUNT_MARGIN)+TAB                  
                  +"stopout_level="+AccountInfoDouble(ACCOUNT_MARGIN_SO_SO)+TAB   
                  +"account_balance="+AccountInfoDouble(ACCOUNT_BALANCE)+TAB  
                  +"account_credit="+AccountInfoDouble(ACCOUNT_CREDIT)+TAB  
                  +"total_commission="+TotalCommission+TAB  
                  +"total_swap="+TotalSwap+TAB
                  +"total_lot_size="+TotalLotSize+TAB
                  +"total_open_orders="+PositionsTotal()+TAB 
                  +"contract_size="+SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE)+TAB
                  +"position="+Position+TAB   
                  +"base_open_price="+baseOpenPrice()+TAB                 
                  +"peer_take_profit_param=true"+TAB;
            

   sendData(data);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void handleAccountBalanceChanged() {

   if(MyAccountBalance == AccountInfoDouble(ACCOUNT_BALANCE)) {
      return;
   }

   MyAccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);

   string data = "account_balance="+MyAccountBalance+TAB
                 +"account_balance_changed=true"+TAB;

   sendData(data);

   lblBalance.Text(DoubleToString(NormalizeDouble((float)accountObj.Balance(), 2),2)+ " "+accountObj.Currency());
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getUsableSymbolPoint(string symbol) {

   double _point = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE)/ SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);

   return _point;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void handleReceived(string recv) {

   recv = UnusedRecv + recv;

   if(recv == "") {
      return;
   }

   int new_line_end = -1;
   int recv_len =  StringLen(recv);
   for(int i = recv_len -1 ; i >-1; i--) {
      if(StringGetCharacter(recv, i) == StringGetCharacter(NEW_LINE,0)) {
         new_line_end = i;
         break;
      }

   }

   if(new_line_end > -1) {
      string r =  StringSubstr(recv, 0, new_line_end);

      string arr [];
      int count = StringSplit(r, StringGetCharacter(NEW_LINE,0), arr);

      for(int i=0; i< count; i++) {
         receivedLine(arr[i]);

      }

      int pos = new_line_end + 1;
      if(StringLen(recv) >= pos + 1) {
         UnusedRecv = StringSubstr(recv, pos, recv_len - pos);
      } else {
         UnusedRecv = "";
      }

   } else {
      UnusedRecv = recv;

   }


}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getCorrespondingSymbol(string symbol_group) {

   string symb_arr [];

   int len = StringSplit(symbol_group,';', symb_arr);

   for(int i=0; i < len; i++) {
      string symb = symb_arr[i];

      double try_ask = SymbolInfoDouble(symb, SYMBOL_ASK);
      if(GetLastError() == ERR_MARKET_UNKNOWN_SYMBOL) {
         ResetLastError();
         continue;
      }

      if(try_ask > 0) {
         return symb;
      }


   }

   return "SOMETHING_IS_WORONG_HERE";//at this point something must be wrong
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void duplicateEA() {

   string err = "Duplicate EA Not Allowed! EA on chart "+Symbol()+" has been removed because it was found to be a duplicate.";
   Alert(err);
   Print(err);
   Terminating = true;

}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void reloadEAOngoingInstallation(TradePacket &trade_packet_struct) {

   if(trade_packet_struct.immediate == true) {
      string msg = "Please Reload EA. Due to ongoing installations the EA has been forcibly removed.";
      Alert(msg);
      Print(msg);
      Terminating = true;
   }

}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void receivedLine(string line) {


   TradePacket trade_packet_struct;

   toReceivedTradePacket(line,  trade_packet_struct);


//command
   if(trade_packet_struct.command == "check_enough_money") {
      sendCommandCheckEnoughMoney(trade_packet_struct);
   }

   if(trade_packet_struct.command == "check_tradable") {
      sendCommandCheckTradable(trade_packet_struct);
   }

   if(trade_packet_struct.command == "duplicate_ea") {
      duplicateEA();
   }

   if(trade_packet_struct.command == "shutdown_terminal_for_restart") {
      //immediately close the terminal - the gui app will restart it thereafter
      TerminalClose(0);
   }


   if(trade_packet_struct.command == "re_established_pairing") {
      reestablishedPairingNotification();
   }

   if(trade_packet_struct.command == "re_started_terminal") {
      restartedTerminalNotification();
   }

   if(trade_packet_struct.command == "peer_terminal_to_restart") {
      peerTerminalToRestartNotification(trade_packet_struct);
   }
   
   if(trade_packet_struct.command == "peer_terminal_to_restart_confirm")
   {
        peerTerminalToRestartConfirmNotification(trade_packet_struct);
   }
      
   if(trade_packet_struct.command == "report_peer_terminal_to_restart_failed") {
      reportPeerTerminalToRestartFailed(trade_packet_struct);
   }

   if(trade_packet_struct.command == "reload_ea_ongoing_installation") {
      reloadEAOngoingInstallation(trade_packet_struct);
   }


   if(trade_packet_struct.command == "virtual_sync") {
      setVirtualSync(trade_packet_struct);
   }



//action
   if(trade_packet_struct.action == "intro") {
      IsIntroRequired = true; //force the EA to send the intro
   }



   if(trade_packet_struct.action == "sync_place_order") {
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
   
   if(trade_packet_struct.action == "sync_copy") {
      sendPacketTrade(trade_packet_struct);
   }

   if(trade_packet_struct.action == "sync_close") {
      sendPacketClose(trade_packet_struct);
   }

   if(trade_packet_struct.action == "sync_partial_close") {
      sendPacketClose(trade_packet_struct);
   }

   if(trade_packet_struct.action == "own_close") {
      sendPacketClose(trade_packet_struct);
   }

   if(trade_packet_struct.action == "sync_modify_target") {
      sendPacketSyncModifyTarget(trade_packet_struct);
   }

   if(trade_packet_struct.action == "unpaired_notification") {
      sendUnpairedNotification(trade_packet_struct);
   }

   if(trade_packet_struct.action == "sync_state_paird_id") {
      SyncStatePairID = trade_packet_struct.sync_state_paird_id;

      //Print("SyncStatePairID =",SyncStatePairID);// TESTING!!!

   }


}
//--------------------------------------------------
// initilize the trade packet struct otherwise the garbage values will be assign to it
//--------------------------------------------------
void initTradeStrct(TradePacket &trade_packet_struct) {
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void toReceivedTradePacket(string line, TradePacket &trade_packet_struct) {


   if(line != PING_PACKET) {
      Print("RECEIVED: ",line);//TESTING!!!
   }

   initTradeStrct(trade_packet_struct);

   string token [];
   int size = StringSplit(line,StringGetCharacter(TAB,0), token);

   for(int i=0; i < size; i++) {
      string param [];
      StringSplit(token[i], '=', param);
      string name = param[0];
      string value = param[1];

      trade_packet_struct.signal_time = (long)TimeCurrent();


      if(name == "command") {
         trade_packet_struct.command = value;
      }

      if(name == "command_id") {
         trade_packet_struct.command_id = value;
      }

      if(name == "action") {
         trade_packet_struct.action = value;
      }

      if(name == "uuid") {
         trade_packet_struct.uuid = value;
      }

      if(name == "immediate") {
         trade_packet_struct.immediate = value == "true";
      }

      if(name == "force") {
         trade_packet_struct.force = value;
      }

      if(name == "reason") {
         trade_packet_struct.reason = value;
      }

      if(name == "symbol") {
         trade_packet_struct.symbol = defactorSymbol(value);
      }

      /*//deprecated
      if(name == "symbol_group" && StringLen(value) > 0)
      {
         trade_packet_struct.symbol = getCorrespondingSymbol(value);
      }
      */

      if(name == "relative_symbol" && StringLen(value) > 0) { // yes relative_symbol must come below symbol so that if known we use it straightway
         trade_packet_struct.symbol = value;
      }


      if(name == "ticket") {
         trade_packet_struct.ticket = StringToInteger(value);
      }


      if(name == "origin_ticket") {
         trade_packet_struct.origin_ticket = StringToInteger(value);
      }


      if(name == "position") {
         trade_packet_struct.position = value;
      }

      if(name == "lot_size") {
         trade_packet_struct.lot_size = value;
      }

      if(name == "open_price") {
         trade_packet_struct.open_price = value;
      }

      if(name == "trade_copy_type") {
         trade_packet_struct.copy_type = value;
      }

      if(name == "target") {
         trade_packet_struct.target = StringToDouble(value);
      }

      if(name == "stoploss") {
         trade_packet_struct.stoploss = StringToDouble(value);
      }

      if(name == "spread_point") {
         trade_packet_struct.spread_point = StringToDouble(value);
      }

      if(name == "peer_broker") {
         trade_packet_struct.peer_broker = value;
      }

      if(name == "peer_account_number") {
         trade_packet_struct.peer_account_number = value;
      }



      if(name == "own_ticket") {
         trade_packet_struct.own_ticket = StringToInteger(value);
      }


      if(name == "peer_ticket") {
         trade_packet_struct.peer_ticket = StringToInteger(value);
      }


      if(name == "peer_stoploss") {
         trade_packet_struct.peer_stoploss = StringToDouble(value);
      }


      if(name == "peer_spread_point") {
         trade_packet_struct.peer_spread_point = StringToDouble(value);
      }

      if(name == "sync_state_paird_id") {
         trade_packet_struct.sync_state_paird_id = value;
      }

      if(name == "partial_closed_lot_fraction") {
         trade_packet_struct.partial_closed_lot_fraction = StringToDouble(value);
      }



      if(name == "peer_symbol_digits") {
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
         PeerPosition = value == "BUY"? POSITION_TYPE_BUY: value == "SELL"? POSITION_TYPE_SELL: -1 ;            
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

      if(name == "sync_copy_manual_entry") {
         SyncCopyManualEntry =  value == "true" || value == "1";

         Print("SyncCopyManualEntry ", SyncCopyManualEntry);
      }


      if(name == "exit_clearance_factor") {
         switch(StringToInteger(value)) {
         case 0:
            exitClearanceFactor = _0_PERCENT;
            EXIT_CLEARANCE_FACTOR =0;
            break;
         case 30:
            exitClearanceFactor = _30_PERCENT;
            EXIT_CLEARANCE_FACTOR =0.3;
            break;
         case 50:
            exitClearanceFactor = _50_PERCENT;
            EXIT_CLEARANCE_FACTOR =0.5;
            break;
         case 80:
            exitClearanceFactor = _80_PERCENT;
            EXIT_CLEARANCE_FACTOR =0.8;
            break;
         case 100:
            exitClearanceFactor = _100_PERCENT;
            EXIT_CLEARANCE_FACTOR =1;
            break;
         }

         Print("EXIT_CLEARANCE_FACTOR ", EXIT_CLEARANCE_FACTOR);
      }


      if(name == "only_trade_with_credit") {
         OnlyTradeWithCredit =  value == "true" || value == "1";

         Print("OnlyTradeWithCredit ", OnlyTradeWithCredit);
      }


      if(name == "enable_exit_at_peer_stoploss") {
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


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sendCommandCheckEnoughMoney(TradePacket &trade) {

   ENUM_ORDER_TYPE order_type = toIntOrderType(trade.position);

//check if money is enough
   MqlTradeRequest request= {};
   MqlTradeCheckResult  result= {};

   symbolObj.Name(trade.symbol);
   symbolObj.RefreshRates();

   double max_volume = 0;
   SymbolInfoDouble(trade.symbol, SYMBOL_VOLUME_MAX, max_volume);

   double lots_size = trade.lot_size > max_volume? max_volume : trade.lot_size;

//--- parameters of request
   request.action   = TRADE_ACTION_DEAL;
   request.symbol   = Symbol();
   request.volume   = lots_size;
   request.type     = order_type;
   request.price    = order_type == ORDER_TYPE_BUY ? symbolObj.Ask() : symbolObj.Bid();
   request.deviation= 100;

   bool check_order = OrderCheck(request, result);
   int last_error = GetLastError();
   double required_margin = AccountInfoDouble(ACCOUNT_BALANCE) - result.margin_free;
   
   //double check
   double manaul_computed_required_margin = GetRequiredMargin(Symbol(), lots_size);
   bool manual_check_enough_money = AccountInfoDouble(ACCOUNT_BALANCE) > manaul_computed_required_margin;
   
   if(!check_order) {
      if(!manual_check_enough_money){//double check
         sendData(checkEnoughMoneyCommandResponse(false, trade, "No enough money!"));
         return;
      }
   }

   sendData(checkEnoughMoneyCommandResponse(true, trade, DoubleToString(required_margin)));

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sendCommandCheckTradable(TradePacket &trade) {


   bool connected = TerminalInfoInteger(TERMINAL_CONNECTED);
   if(!connected) {
      sendData(checkTradableCommandResponse(false, trade, "Terminal Disconnected!"));
      return;
   }

   bool trade_allow = AccountInfoInteger(ACCOUNT_TRADE_ALLOWED);
   if(!trade_allow) {
      sendData(checkTradableCommandResponse(false, trade, "Trade not allowed!"));
      return;
   }

   bool trade_expert = AccountInfoInteger(ACCOUNT_TRADE_EXPERT);
   if(!trade_expert) {
      sendData(checkTradableCommandResponse(false, trade, "Automated trading is forbidden for the account " +AccountInfoInteger(ACCOUNT_LOGIN)
                                            +" at the trade server side"));
      return;
   }

   bool symbol_trade_mode = SymbolInfoInteger(Symbol(), SYMBOL_TRADE_MODE);
   if(symbol_trade_mode == SYMBOL_TRADE_MODE_DISABLED) {
      sendData(checkTradableCommandResponse(false, trade, "Trade is disabled for the symbol - "+Symbol()));
      return;
   }


   sendData(checkTradableCommandResponse(true, trade, "success"));

}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void setVirtualSync(TradePacket &trade) {

   bool found = false;

   for(int i=0; i<vSyncList.Total(); i++) {
      VirtualSync *vSync = vSyncList.GetNodeAtIndex(i);
      if(vSync.own_ticket == trade.own_ticket && vSync.peer_ticket == trade.peer_ticket) {
         if(trade.peer_stoploss != 0) {

            vSync.peer_stoploss = trade.peer_stoploss;

            //update GUI list view
            lstPeerTicketsView.ItemUpdate(i, vSync.peer_ticket, vSync.peer_ticket);

         }
         if(trade.peer_spread_point != 0) {
            vSync.peer_spread_point = trade.peer_spread_point;
         }

         found = true;
      }
   }

   if(!found) {
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


   for(int i=0; i<vSyncList.Total(); i++) {
      VirtualSync *vSync = vSyncList.GetNodeAtIndex(i);


      //Print("vSync.own_ticket ",vSync.own_ticket);
      //Print("vSync.peer_ticket ",vSync.peer_ticket);
      //Print("vSync.peer_stoploss ",vSync.peer_stoploss);
      //Print("vSync.peer_spread_point ",vSync.peer_spread_point);

      if(SelectPositionByTicket(vSync.own_ticket)==true) {
         //NO NEED SINCE EVERY ORDER SELECTED BY positionObj IS STILL OPEN
         /*if(OrderCloseTime()){
             continue;//skip since we only need open orders
         }*/


         //At this point the order is still open

         ExpectedExitProfit += positionObj.Swap() + positionObj.Commission() + positionObj.Volume() * MathAbs(positionObj.PriceOpen() - vSync.peer_stoploss) / getUsableSymbolPoint(positionObj.Symbol());
         ExpectedTargetProfit += positionObj.Swap() + positionObj.Commission() + positionObj.Volume() * MathAbs(positionObj.PriceOpen() - positionObj.TakeProfit()) / getUsableSymbolPoint(positionObj.Symbol());

         ExpectedExitBalance = accountObj.Balance() + ExpectedExitProfit;
         ExpectedTargetBalance = accountObj.Balance() + ExpectedTargetProfit;

      }
   }


   lblExpectedProfitRange.Text(NormalizeDouble(ExpectedExitProfit, 2)
                               + " " + accountObj.Currency()
                               + " / " + NormalizeDouble(ExpectedTargetProfit, 2)
                               + " " + accountObj.Currency());

   lblExpectedBalanceRange.Text(NormalizeDouble(ExpectedExitBalance, 2)
                                + " " + accountObj.Currency()
                                + " / " + NormalizeDouble(ExpectedTargetBalance, 2)
                                + " " + accountObj.Currency());




//Print("ExpectedExitProfit ",ExpectedExitProfit);
//Print("ExpectedTargetProfit ",ExpectedTargetProfit);
//Print("expected_exit_bal ",ExpectedExitBalance);
//Print("expected_target_bal ",ExpectedTargetBalance);
//Print(" -----------------END VIRTUAL SYNC------------------------- ");

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkPeerStoplossHit() {

   if(!IsExitAtPeerStoplossEnabled) {
      return;
   }

   for(int n=0; n<vSyncList.Total(); n++) {

      VirtualSync *vSync = vSyncList.GetNodeAtIndex(n);

      if(vSync.peer_stoploss <= 0) {
         continue; //Skip since no stoploss yet.
      }

      if(SelectPositionByTicket(vSync.own_ticket)) {
         //NO NEED SINCE EVERY ORDER SELECTED BY positionObj IS STILL OPEN
         /*if(OrderCloseTime()){
            continue;//skip since we only need open orders
         }*/

         //At this point the order is still open

         if(positionObj.PositionType() == POSITION_TYPE_BUY) {
            //Which means peer position is SELL
            checkPeerStoplossHit0(POSITION_TYPE_SELL, vSync);
         } else if(positionObj.PositionType() == POSITION_TYPE_SELL) {
            //Which means peer position is BUY
            checkPeerStoplossHit0(POSITION_TYPE_BUY, vSync);
         }

      }
   }

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double exitClearance(VirtualSync &vSync) {
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
double safePriceToCompareWith(int peerPos, double exit_price, double peer_spread_point) {

   int LAST_BARS_COUNT = 3;

   debugPriceIsClosePrice = false;//for debug purpose

//let know time elapse after trade open
   int timeElapseInsec = TimeCurrent() - positionObj.Time();
   if(timeElapseInsec <= LAST_BARS_COUNT * 60) {
      debugPriceIsClosePrice = true;//for debug purpose
      return iClose(NULL,PERIOD_CURRENT,0); //just return current prices within the first minute as it is unsafe to test with Low or High with this period
   }

//At this point we are on the next N bars of the one minute timeframe since open trade.
//This is a safe (reasonable) period to use High or Low to test our condition
   int one_minute_bar_count = timeElapseInsec/60;

//we just need few bars like say 3 to reduce computation
//Since we know the EA delay (slowness - time b/w execution)
//can not be more than 3 minutes except is something is
//seriously wrong
   if(one_minute_bar_count > LAST_BARS_COUNT) {
      one_minute_bar_count = LAST_BARS_COUNT;
   }


//At this point at least a new one minute bar is created
   double peak_price = 0;

   int shift = 0;
   if(peerPos == POSITION_TYPE_BUY) {
      shift = iLowest(Symbol(), PERIOD_M1, MODE_LOW, one_minute_bar_count);

      if(shift == -1)
         PrintFormat("Error in iLowest. Error code=%d",GetLastError());

   } else {
      shift = iHighest(Symbol(), PERIOD_M1, MODE_HIGH, one_minute_bar_count);

      if(shift == -1)
         PrintFormat("Error in iHighest. Error code=%d",GetLastError());
   }


   if(shift == -1) {
      //An error occoure so just return the high or low of the current bar
      shift = 0;
   }

//ASSERTION 1 - Just checking if this is a bug - unexpected hitting the peer exit stoploss
   if(shift > LAST_BARS_COUNT) {
      Print("BUG PREVENTED!!!  POSSIBLY NONSENSE VALUE. shift = ", shift);
      shift = 0;
   }



   if(peerPos == POSITION_TYPE_BUY)
      peak_price = iLow(NULL,PERIOD_CURRENT,shift);
   else
      peak_price = iHigh(NULL,PERIOD_CURRENT, shift);



//Check if the peer stoploss intercepts the high / low with the last N bars on the current timeframe

   if(timeElapseInsec <= LAST_BARS_COUNT * Period() * 60) {

      if(peerPos == POSITION_TYPE_BUY && peak_price <= exit_price) {
         bugResolved ++;
         peak_price =  iClose(NULL,PERIOD_CURRENT,0);
      }

      if(peerPos == POSITION_TYPE_SELL && peak_price >= peak_price + peer_spread_point) {
         bugResolved ++;
         peak_price =  iClose(NULL,PERIOD_CURRENT,0);
      }

   }


   if(bugResolved == 1) {

      Alert("GREAT! MAJOR BUG IS RESOLVED");
      Print("GREAT! MAJOR BUG IS RESOLVED");

   }

   return peak_price;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkPeerStoplossHit0(int peerPos, VirtualSync &vSync) {

//Print("checkPeerStoplossHit0");

   bool success = false;
   bool attempted = false;

//The purpose of this clearance is to ensure this account (POSITIVE SIDE) sees
//this stoploss price before the peer account (NEGATIVE SIDE) to ensure the positive side
//closes first before the negative account side.

   double clearance = exitClearance(vSync);

   double exit_price = peerPos == POSITION_TYPE_BUY
                       ? vSync.peer_stoploss + clearance
                       : vSync.peer_stoploss - clearance;


   double safePrice = safePriceToCompareWith(peerPos, exit_price, vSync.peer_spread_point);//which is Highest High or Lowest Low of N bars - Please see Comments on safePriceToCompareWith() method for more explanation


//BUY enters at Ask price but closes at Bid price
   double PeerBid = safePrice; //Which is Close[0] but we are not using the Close[0] directly to handle missed price condition - Please see Comments on safePriceToCompareWith() method for more explanation

//SELL enters at Bid price but closes at Ask price
   double PeerAsk = safePrice + vSync.peer_spread_point; //yes, we are calculating what should be the Ask price on the peer account. We know it is the Close[0] plus the spread - But we are not using the Close[0] directly to handle missed price condition - Please see Comments on safePriceToCompareWith() method for more explanation

   if(peerPos == POSITION_TYPE_BUY) {

      bool PrevIsHitPeerStoploss = vSync.IsHitPeerStoploss; // if true then it probably is a retry otherwise a big bug - this is while we are storing the value

      if(PeerBid <=  exit_price || vSync.IsHitPeerStoploss) {
         vSync.IsHitPeerStoploss = true;
         attempted = true;
         //NOTE: SELL closes at Ask Price - since Peer is BUY then own is SELL and will close at Ask price

         int error = closeSelectedPosition();
         success = error == 0;

         Print("HIT Peer BUY Stoploss exit_price ", exit_price,
               " safePrice ", safePrice,
               " debugPriceIsClosePrice ", debugPriceIsClosePrice,  //whether the safePrice is the current price or high/low
               " vSync.peer_stoploss ", vSync.peer_stoploss,
               " vSync.peer_spread_point ", vSync.peer_spread_point,
               " clearance ",clearance,
               " PrevIsHitPeerStoploss ", PrevIsHitPeerStoploss);
      }

   }




   if(peerPos == POSITION_TYPE_SELL) {

      bool PrevIsHitPeerStoploss = vSync.IsHitPeerStoploss; // if true then it probably is a retry otherwise a big bug - this is while we are storing the value

      if(PeerAsk >=  exit_price || vSync.IsHitPeerStoploss) {
         vSync.IsHitPeerStoploss = true;
         attempted = true;
         //NOTE: BUY closeS at Bid Price - since Peer is SELL then own is BUY and will close at Bid price
         int error = closeSelectedPosition();
         success = error == 0;

         Print("HIT Peer SELL Stoploss exit_price ", exit_price,
               " safePrice ", safePrice,
               " debugPriceIsClosePrice ", debugPriceIsClosePrice,  //whether the safePrice is the current price or high/low
               " vSync.peer_stoploss ", vSync.peer_stoploss,
               " vSync.peer_spread_point ", vSync.peer_spread_point,
               " clearance ",clearance,
               " PrevIsHitPeerStoploss ", PrevIsHitPeerStoploss);
      }

   }


   if(attempted && success) {

      sendData(exitAtPeerStoplossPacket(vSync));
      SendNotification(StringFormat("EXIT AT PEER STOPlOSS\nPeer Ticket #%d\nOwn Ticket #%d\nBal. %s", vSync.peer_ticket, vSync.own_ticket, accountObj.Balance()+" "+ accountObj.Currency()));
      lblAlert.Text("SUCCESSFUL EXIT AT PEER STOPOLOSS PRICE");

   } else if(attempted && !success) {
      string error = ErrorDescription(GetLastError());
      sendData(exitAtPeerStoplossPacket(vSync, error));
   }


}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string exitAtPeerStoplossPacket(VirtualSync &vSync, string error = "") {

   bool success = error=="";

   string packet = "exit_at_peer_stoploss_success="+success+TAB
                   +"own_ticket="+IntegerToString(vSync.own_ticket)+TAB
                   +"peer_ticket="+IntegerToString(vSync.peer_ticket)+TAB
                   +"error="+error+TAB;

   return packet;

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int closeSelectedPosition() {

   int MAX_ATTEMPT = 3;
   int error = 0;

   for(int try_count = 0; try_count < MAX_ATTEMPT; try_count++) {
      tradeObj.PositionClose(positionObj.Ticket(), 15);
      bool success = IsTradeRequestSuccessful();
      error = tradeObj.ResultRetcodeDescription();

      if(!success && error == TRADE_RETCODE_REQUOTE) {
         Sleep(200);
         Print(StringFormat("REQUOTE ERROR: RETRY CLOSE [%d] - Order ticket #%d", try_count, positionObj.Ticket()));
         symbolObj.RefreshRates();
         continue;
      } else {
         break;
      }
   }

   return error;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sendPacketClose(TradePacket &trade) {

   string data = "";

   for(int i= PositionsTotal() - 1; i > -1; i--) {

      if(positionObj.SelectByIndex(i)) {
         if(trade.ticket == positionObj.Ticket()) {
            string error = "";
            bool success = true;
            bool pending = false;
            bool is_partial_close = trade.partial_closed_lot_fraction > 0 && trade.partial_closed_lot_fraction < 1;

            double lots = positionObj.Volume();

            if(is_partial_close) {
               lots = positionObj.Volume() * trade.partial_closed_lot_fraction;
            }

            if(positionObj.PositionType() == POSITION_TYPE_BUY) {  //BUY is enters at ASK price but closes at BID price
               error = closeSelectedPosition();
               success = error == 0;
            } else if(positionObj.PositionType() == POSITION_TYPE_SELL) { //SELL is enters at BID price but closes at ASK price
               error = closeSelectedPosition();
               success = error == 0;
            } else { //pending orders
               pending = true;
               tradeObj.OrderDelete(positionObj.Ticket());
               success = IsTradeRequestSuccessful();
            }

            if(success && !is_partial_close) {
               addTicketOfSyncClose(trade.ticket);//mark this order ticket as one of those generated by close operation
               if(trade.force == "true") {
                  lblAlert.Text(trade.reason);
                  Print(trade.reason);
               }
            } else if(success && is_partial_close) {
               addTicketOfSyncClose(trade.ticket);//mark this order ticket as one of those generated by close operation
            } else {
               if(trade.force == "true") {
                  string warning = "WARNING!!! Secure attempt to forcibly close order #"+trade.ticket+" failed!";
                  lblAlert.Text(warning);
                  Print(warning);
               }

               error = tradeObj.ResultRetcodeDescription();

               if(!pending) {
                  Print("OrderClose error ",error);
               } else {
                  Print("OrderDelete error ",error);
               }
            }

            data += closeSuccessPacket(success, trade, error);

         }

      }
   }


   if(data !="") {
      sendData(data);
   }


}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void restoreTarget() {


   if(LastAutoModifiedTarget == 0) {
      return;
   }

   int SymbolDigits = ensureSameSymboDigitsWithPeer();

   if(SymbolDigits == UNDEFINED) {
      return;
   }


   for(int i= PositionsTotal() - 1; i > -1; i--) {

      if(positionObj.SelectByIndex(i)) {

         if(NormalizeDouble(positionObj.TakeProfit(), SymbolDigits)
               == NormalizeDouble(LastAutoModifiedTarget, SymbolDigits)) {
            continue;
         }


         PrintFormat("Order #%d - DETECTED MANUAL TARGET MODIFICATION WHICH IS NOT ALLOWED", positionObj.Ticket());


         tradeObj.PositionModify(positionObj.Ticket(), positionObj.StopLoss(), LastAutoModifiedTarget);
         bool success = IsTradeRequestSuccessful();

         if(success) {
            PrintFormat("Order #%d - TARGET HAS BEEN RESET BACK TO %s", positionObj.Ticket(), DoubleToString(LastAutoModifiedTarget, _Digits));

         } else {
            PrintFormat("Order #%d - FAILED TO RESET TARGET BACK TO %s", positionObj.Ticket(),DoubleToString(LastAutoModifiedTarget, _Digits));

            string error = tradeObj.ResultRetcodeDescription();
            Print(error);
         }
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sendPacketSyncModifyTarget(TradePacket &trade) {

   string data = "";

   for(int i= PositionsTotal() - 1; i > -1; i--) {

      if(positionObj.SelectByIndex(i)) {
         if(trade.ticket == positionObj.Ticket()) {
            tradeObj.PositionModify(positionObj.Ticket(), positionObj.StopLoss(), trade.target);

            if(IsTradeRequestSuccessful()) {
               LastAutoModifiedTarget = trade.target;

               data += modifyTargetSuccessPacket(true, trade);

               addTicketOfSyncModify(trade.ticket);

            } else {

               string error = tradeObj.ResultRetcodeDescription();

               data += modifyTargetSuccessPacket(false, trade, error);
            }

         }

      }
   }


   if(data !="") {
      sendData(data);
   }


}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool findTradeByPacket(TradePacket &trade) {

//find open position
   for(int i= PositionsTotal() - 1; i > -1; i--) {
      if(positionObj.SelectByIndex(i)) {

         if(positionObj.Magic() == COPIED_TRADE_MAGIC_NUMBER
               && trade.ticket == positionObj.Ticket()//NEW
           ) {
            return true;
         }
      }
   }


//find pending orders
   for(int i= OrdersTotal() - 1; i > -1; i--) {
      if(orderObj.SelectByIndex(i)) {
         if(orderObj.Magic() == COPIED_TRADE_MAGIC_NUMBER
               && trade.ticket == orderObj.Ticket()//NEW
           ) {
            return true;
         }
      }
   }
   return  false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool findHistoryByPacket(TradePacket &trade) {

//select history from startup time to now

   HistorySelect(HistoryFromTime, TimeCurrent());//important! so that we can call HistoryOrdersTotal() otherwise it will always return zero

   for(int i= HistoryOrdersTotal() - 1; i > -1; i--) {
      if(historyOrderObj.SelectByIndex(i)) {

         if(!isOrderType(historyOrderObj)) { //we only want order type and not credit or balance as displayed in AccountHistory of the Terminal
            continue;
         }


         //check if it is open position
         ulong hticket = historyOrderObj.Ticket();


         if(SelectPositionByTicket(hticket)) {
            continue;
         }


         if(historyOrderObj.Magic() == COPIED_TRADE_MAGIC_NUMBER
               && trade.ticket == historyOrderObj.Ticket()//NEW
           ) {
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsTradeRequestSuccessful() {
   return tradeObj.ResultRetcode() == TRADE_RETCODE_DONE || tradeObj.ResultRetcode() == TRADE_RETCODE_PLACED;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void addTicketOfSyncOrderSend(ulong ticket) {
   addSetItem(ticket, ticketsOfSyncCopy);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void addTicketOfSyncClose(ulong ticket) {
   addSetItem(ticket, ticketsOfSyncClose);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void addTicketOfSyncModify(ulong ticket) {
   addSetItem(ticket, ticketsOfSyncModify);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void addSetItem(ulong item, ulong &items []) {

   bool isAlreadyAdded = contains(item, items);

   if(isAlreadyAdded) {
      return;
   }

   int new_size = ArraySize(items) + 1;
   ArrayResize(items, new_size);
   items[new_size -1] = item;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void addSetItem(double item, double &items []) {

   bool isAlreadyAdded = contains(item, items);

   if(isAlreadyAdded) {
      return;
   }

   int new_size = ArraySize(items) + 1;
   ArrayResize(items, new_size);
   items[new_size -1] = item;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void addItem(ulong item, ulong &items []) {
   int new_size = ArraySize(items) + 1;
   ArrayResize(items, new_size);
   items[new_size -1] = item;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void addItem(double item, double &items []) {
   int new_size = ArraySize(items) + 1;
   ArrayResize(items, new_size);
   items[new_size -1] = item;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isTicketOfSyncCopy(ulong ticket) {
   return contains(ticket, ticketsOfSyncCopy);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isTicketOfSyncClose(ulong ticket) {
   return contains(ticket, ticketsOfSyncClose);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isTicketOfSyncModify(ulong ticket) {
   return contains(ticket, ticketsOfSyncModify);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool contains(ulong item, ulong &items []) {
   int size = ArraySize(items);

   for(int i=0; i < size; i++) {
      if(items[i] == item) {
         return true;
      }
   }
   return false;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool contains(double item, double &items []) {
   int size = ArraySize(items);

   for(int i=0; i < size; i++) {
      if(items[i] == item) {
         return true;
      }
   }
   return false;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void clearTicketsOfSyncCopy() {
   ArrayResize(ticketsOfSyncCopy, 0);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void clearTicketsOfSyncClose() {
   ArrayResize(ticketsOfSyncClose, 0);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void clearTicketsOfSyncModify() {
   ArrayResize(ticketsOfSyncModify, 0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void arrayAppend(ulong ticket, ulong &ticketsOfOrder []) {
   int new_size = ArraySize(ticketsOfOrder) + 1;
   ArrayResize(ticketsOfOrder, new_size);
   ticketsOfOrder[new_size -1] = ticket;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void clearTicketsOfPlacementOrder() {
   ArrayResize(ticketsOfPlacementOrder, 0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sendPacketTrade(TradePacket &trade) {

   double lot_size = trade.lot_size;

   string trade_pos = trade.position;

   ENUM_ORDER_TYPE order_type = toIntOrderType(trade_pos);

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


   if(!TerminalInfoInteger(TERMINAL_CONNECTED)) {
      sendData(syncSendOrderSuccessPacket(false, -1, trade, "No connection."));
      return;
   }

   string data = "";

   int count_try = 0;

   symbolObj.Name(trade.symbol);
   symbolObj.RefreshRates();

   while(count_try < 3) {
      count_try++;

      if(order_type == ORDER_TYPE_BUY) {
         double entry_price = symbolObj.Ask();
         tradeObj.SetDeviationInPoints(100);

         //ulong ticket=OrderSend(trade.symbol, order_type, lot_size, entry_price, 100, trade.stoploss, trade.target,
         //                                         "",COPIED_TRADE_MAGIC_NUMBER,0,clrNONE);
         tradeObj.PositionOpen(trade.symbol, order_type, lot_size, entry_price, trade.stoploss, trade.target, "");

         ulong ticket = tradeObj.ResultOrder();

         if(IsTradeRequestSuccessful()) {

            addTicketOfSyncOrderSend(ticket);//mark this order ticket as one of those generated by sync send order operation

            data = syncSendOrderSuccessPacket(true, ticket, trade);
            break;
         } else {
            string error = tradeObj.ResultRetcodeDescription();

            data = syncSendOrderSuccessPacket(false, -1, trade, error);

            Print("TRY : ", count_try,"OrderSend error ", error);
         }

      } else if(order_type == ORDER_TYPE_SELL) {

         double entry_price = symbolObj.Bid();


         //ulong ticket=OrderSend(trade.symbol, order_type,lot_size, entry_price, 100, trade.stoploss, trade.target,
         //                                         "",COPIED_TRADE_MAGIC_NUMBER,0,clrNONE);

         tradeObj.SetDeviationInPoints(100);
         tradeObj.PositionOpen(trade.symbol, order_type, lot_size, entry_price, trade.stoploss, trade.target, "COPY");

         ulong ticket = tradeObj.ResultOrder();

         if(IsTradeRequestSuccessful()) {

            addTicketOfSyncOrderSend(ticket);//mark this order ticket as one of those generated by copy operation

            data = syncSendOrderSuccessPacket(true, ticket, trade);
            break;
         } else {
            string error = tradeObj.ResultRetcodeDescription();

            data = syncSendOrderSuccessPacket(false, -1, trade, error);
            Print("TRY : ", count_try,"OrderSend error ", error);
         }

      } else {
         Print("Unknown order type ", order_type);
         return;
      }

      Sleep(1000); //important!

      //Important - avoid duplicate trade when there is a connection error which is possible. I observed the bug.
      //So make sure truly the trade is not duplicated because of connection error moment after the trade is
      //already sent to the server
      if(findTradeByPacket(trade)) {
         Print("GOOD! Avoided duplicate trade! - ",trade.symbol);
         break;//leave to avoid duplicate trade
      }
   }

   if(data !="") {
      sendData(data);
   }

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string syncSendOrderSuccessPacket(bool success, ulong ticket, TradePacket &trade, string error="") {
   if(trade.action == "sync_copy") {
      return copySuccessPacket(success, ticket, trade,  error);
   } else if(trade.action == "sync_place_order") {
      return placeOrderSuccessPacket(success, ticket, trade,  error);
   }

   return "";
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string placeOrderSuccessPacket(bool success, ulong ticket, TradePacket &trade, string error="") {
   if(error == "Market is closed") {
      IsMarketClosed = true;
   }

   arrayAppend(ticket, ticketsOfPlacementOrder); //important! force the order information to be sent on next ticket. only reliable way of selecting the order

   string packet = "place_order_success="+success+TAB
                   +"ticket="+IntegerToString(ticket)+TAB
                   +"uuid="+trade.uuid+TAB
                   +"error="+error+TAB;

   return packet;
}



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string copySuccessPacket(bool success, ulong ticket, TradePacket &trade, string error="") {
   if(error == "Market is closed") {
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string maximizeLockInProfitSuccessPacket(bool success,int ticket, string stoploss, string error="") {

   if(error == "Market is closed") {
      IsMarketClosed = true;
   }

   return "ticket="+IntegerToString(ticket)+TAB
          +"stoploss="+DoubleToString(stoploss)+TAB
          +"maximize_lock_in_profit_success="+success+TAB
          +"error="+error+TAB;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string lockInProfitSuccessPacket(bool success, TradePacket &trade, string error="") {

   if(error == "Market is closed") {
      IsMarketClosed = true;
   }

   return "ticket="+IntegerToString(trade.ticket)+TAB
          +"origin_ticket="+IntegerToString(trade.origin_ticket)+TAB
          +"stoploss="+DoubleToString(trade.stoploss)+TAB
          +"lock_in_profit_success="+success+TAB
          +"error="+error+TAB;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string exitOnToleranceTargetSuccessPacket(bool success, TradePacket &trade, string error="") {

   if(error == "Market is closed") {
      IsMarketClosed = true;
   }

   return "ticket="+IntegerToString(trade.ticket)+TAB
          +"origin_ticket="+IntegerToString(trade.origin_ticket)+TAB
          +"floating_balance="+DoubleToString(trade.floating_balance)+TAB
          +"account_balance="+DoubleToString(trade.account_balance)+TAB
          +"exit_on_tolerance_target_success="+success+TAB
          +"error="+error+TAB;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string closeSuccessPacket(bool success, TradePacket &trade, string error="") {

   if(error == "Market is closed") {
      IsMarketClosed = true;
   }

   string packet = "";

   packet += "ticket="+IntegerToString(trade.ticket)+TAB
             +"close_signal_time="+trade.signal_time+TAB
             +"close_execution_time="+(long)TimeCurrent()+TAB
             +"error="+error+TAB;


   if(trade.ticket > 0) { //means it is selected
      long close_time = 0;
      double close_price = 0;

      if(success == true) {
         //since it was successfully closed, check the history trades

         if(FindHistoryOrderByTicket(trade.ticket, historyOrderObj)) {

            //close_time = (long)historyOrderObj.TimeDone();//@Deprecated - wrong since all once postion orders are history order which share the same time. when postions are closed a unique order of a different ticket is added to the history orders. it is not possible for us to know corresponding position order for which that unique order is added to the history
            close_time = (long)TimeCurrent(); //lets using the current time which a more realistic time
            close_price = historyOrderObj.PriceCurrent();

         }

      } else {

         //since it was not successfully closed, check the open trades
         if(orderObj.Select(trade.ticket)) {
            //close_time = (long)orderObj.TimeDone();//@Deprecated - wrong since all once postion orders are history order which share the same time. when postions are closed a unique order of a different ticket is added to the history orders. it is not possible for us to know corresponding position order for which that unique order is added to the history
            close_time = (long)TimeCurrent(); //lets using the current time which a more realistic time
            close_price = orderObj.PriceCurrent();
         }
      }

      if(close_time == 0) { //just in case it is still saying zero then i disagree
         close_time = (long)TimeCurrent();
      }

      packet += "close_time="+close_time+TAB
                +"close_price="+close_price+TAB;
   }


   if(trade.action == "sync_close") {
      packet += "origin_ticket="+IntegerToString(trade.origin_ticket)+TAB
                +"close_success="+success+TAB;

   } else if(trade.action == "own_close") {
      packet += "origin_ticket="+IntegerToString(trade.origin_ticket)+TAB
                +"partial_close_success="+success+TAB;

   } else if(trade.action == "own_close") {
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string modifyTargetSuccessPacket(bool success, TradePacket &trade, string error="") {
   if(error == "Market is closed") {
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


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string checkEnoughMoneyCommandResponse(bool success,  TradePacket &trade, string response) {
   return "command="+trade.command+TAB
          +"command_id="+trade.command_id+TAB
          +"command_response="+response+TAB
          +"command_success="+success+TAB;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string checkTradableCommandResponse(bool success,  TradePacket &trade, string response) {
   return "command="+trade.command+TAB
          +"command_id="+trade.command_id+TAB
          +"command_response="+response+TAB
          +"command_success="+success+TAB;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getStrPositionType(CPositionInfo &position_order) {
   if(position_order.PositionType() == POSITION_TYPE_BUY) {
      return "BUY";
   }

   else if(position_order.PositionType() == POSITION_TYPE_SELL) {
      return "SELL";
   }

   return "";
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getStrOrderType(COrderInfo &order) {
   if(order.OrderType() == ORDER_TYPE_BUY) {
      return "BUY";
   } else if(order.OrderType() == ORDER_TYPE_BUY_LIMIT) {
      return "BUYLIMIT";
   } else if(order.OrderType() == ORDER_TYPE_BUY_STOP) {
      return "BUYSTOP";
   } else if(order.OrderType() == ORDER_TYPE_SELL) {
      return "SELL";
   } else if(order.OrderType() == ORDER_TYPE_SELL_LIMIT) {
      return "SELLLIMIT";
   } else if(order.OrderType() == ORDER_TYPE_SELL_STOP) {
      return "SELLSTOP";
   }

   return "";
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getStrHistoryOrderType(CHistoryOrderInfo &history_order) {
   if(history_order.OrderType() == ORDER_TYPE_BUY) {
      return "BUY";
   } else if(history_order.OrderType() == ORDER_TYPE_BUY_LIMIT) {
      return "BUYLIMIT";
   } else if(history_order.OrderType() == ORDER_TYPE_BUY_STOP) {
      return "BUYSTOP";
   } else if(history_order.OrderType() == ORDER_TYPE_SELL) {
      return "SELL";
   } else if(history_order.OrderType() == ORDER_TYPE_SELL_LIMIT) {
      return "SELLLIMIT";
   } else if(history_order.OrderType() == ORDER_TYPE_SELL_STOP) {
      return "SELLSTOP";
   }

   return "";
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isOrderType(CHistoryOrderInfo &history_order) {
   return history_order.OrderType() == ORDER_TYPE_BUY
          || history_order.OrderType() == ORDER_TYPE_SELL
          || history_order.OrderType() == ORDER_TYPE_BUY_STOP
          || history_order.OrderType() == ORDER_TYPE_SELL_STOP
          || history_order.OrderType() == ORDER_TYPE_BUY_LIMIT
          || history_order.OrderType() == ORDER_TYPE_SELL_LIMIT;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE toIntOrderType(string pos) {

   if(pos == "BUY") {
      return ORDER_TYPE_BUY;
   } else if(pos == "BUYLIMIT") {
      return ORDER_TYPE_BUY_LIMIT;
   } else if(pos == "BUYSTOP") {
      return ORDER_TYPE_BUY_STOP;
   } else if(pos == "SELL") {
      return ORDER_TYPE_SELL;
   } else if(pos == "SELLLIMIT") {
      return ORDER_TYPE_SELL_LIMIT;
   } else if(pos == "SELLSTOP") {
      return ORDER_TYPE_SELL_STOP;
   }


   return -1;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isOrderTradeStatusChange(ChangeStats &stats) {

   stats.TradeCountChanged = false;
   stats.TradeCountIncreased = false;
   stats.TradeModified = false;
   stats.TradeSwapChanged = false;

   int positions_total = PositionsTotal();//open positions
   int pending_orders_total = OrdersTotal();//pending orders
   int buy_count = 0;
   int sell_count = 0;
   double cum_stoploss = 0;
   double cum_target = 0;
   double cum_swap = 0;

   for(int i=0; i < positions_total; i++) {

      if(positionObj.SelectByIndex(i)) {

         cum_stoploss += positionObj.StopLoss();
         cum_target += positionObj.TakeProfit();
         cum_swap += positionObj.Swap();

         if(positionObj.PositionType() == POSITION_TYPE_BUY) {
            buy_count++;
         } else if(positionObj.PositionType() == POSITION_TYPE_SELL) {
            sell_count++;
         }

      }

   }


   bool is_changed = false;

   if(buy_count != BuyCount
         ||sell_count != SellCount) {
         
      if(buy_count > BuyCount || sell_count > SellCount){
         stats.TradeCountIncreased = true; 
      }
               
      BuyCount = buy_count;
      SellCount = sell_count;                  
            
      stats.TradeCountChanged = true;
      is_changed = true;
   }


//select history from startup time to now
   HistorySelect(HistoryFromTime, TimeCurrent());//important! so that we can call HistoryOrdersTotal() otherwise it will always return zero

   int h_total = HistoryOrdersTotal();// The use of HistoryOrdersTotal() is just for detecting changes.
// I no longer use it for get history trades as it is unreliable in mql5.
//it works differently from that of mql4

   if(HistoryTotal != h_total) {
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sendPlaceOrderData() {

   ulong failed_tickets [];

   for(int i=0; i < ArraySize(ticketsOfPlacementOrder); i++) {
      ulong ticket = ticketsOfPlacementOrder[i];

      if(ticket == -1) {
         continue;
      }

      if(SelectPositionByTicket(ticket)) { // come back to check if this difference for mt4 (no history) has effect
         string data = generateTradeStreamPacket(positionObj);
         sendData(data);
      } else {
         arrayAppend(ticket, failed_tickets);
      }

   }

   clearTicketsOfPlacementOrder();

   if(ArraySize(failed_tickets)) {
      ArrayCopy(ticketsOfPlacementOrder, failed_tickets);
   }
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sendDataAttrForSyncStateID() {

   string data = "";
   string tickets = "";

   int positions_total = PositionsTotal();//open positions


   int count = 0;
   string tck = "";
   for(int i=0; i < positions_total; i++) {

      if(positionObj.SelectByIndex(i)) {
         //At this point the order was not generated by copy operation
         count++;
         tck = count == 1 ? positionObj.Ticket(): ","+positionObj.Ticket();
         tickets += tck;

      }

   }


   data +="data_for_sync_state_pair_id="+tickets+TAB;
   sendData(data);

}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sendSyncOrdersData() {

   string data = "";

   int positions_total = PositionsTotal();//open positions
   for(int i=0; i < positions_total; i++) {
      if(positionObj.SelectByIndex(i)) {
         //in this case we need those generated by sync operations
         if(isTicketOfSyncCopy(positionObj.Ticket())) {
            //only those by sync operation
            data += generateTradeStreamPacket(positionObj);
         }

      }

   }

   if(data != "") {
      sendData(data);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sendTradeData(string prepend_data = "") {

   bool new_trade_entries = false;
   bool close_trades = false;

//CODING FOR PARTIAL CLOSE FEATURE IS TOO COMPLEX AND CHALLENGING BECAUSE  WHEN
//PARTIALLY CLOSED A NEW TICKET IS CREATED OF THE PARTIAL OPEN ORDER THUS POSES
//A VERY COMPLEX APPROACH FOR ENSURING SYNCHRONIZATION

//bool partial_close = false; //@Deprecated - TOO HARD TO DO  - SOLUTION PRONE TO ERROR


   ulong open_tickets [];
   double open_lots [];

   string data = ensureWithTab(prepend_data);

   int total_positions = PositionsTotal();
   for(int i=0; i < total_positions; i++) {

      if(positionObj.SelectByIndex(i)) {
         ulong pos_ticket = positionObj.Ticket();


         if(OpenTicketList.SearchLinear(pos_ticket) == -1) { //store open position tickets
            OpenTicketList.Add(pos_ticket);
         }

         //we will make sure we don't send packets for orders generated by copy operation  - it is useless to do so
         if(isTicketOfSyncCopy(positionObj.Ticket())) {
            continue;//do no include this order since it is one of those generated by copy operation
         }

         //At this point the order was not generated by copy operation

         data += generateTradeStreamPacket(positionObj);
         new_trade_entries = true;
      }

   }

   if(new_trade_entries) {
      data += "new_trade_entries=true" + TAB;

      clearTicketsOfSyncCopy();//just clear off since the job is done at this time
   }


   string history_data = "";
   string partial_data = "";


   for(int i=0; i < OpenTicketList.Total(); i++) {

      ulong enlisted_ticket = OpenTicketList.At(i);
      bool found = false;

      for(int k=0; k< total_positions; k++) {
         if(positionObj.SelectByIndex(k)) {
            ulong pos_ticket = positionObj.Ticket();

            if(enlisted_ticket == pos_ticket) {
               found = true;
            }

         } else {
            //Well! we will double check below if the order is open since we could not select is here
         }
      }

      if(!found) {

         //As we promised above, double check that the order is not open


         if(SelectPositionByTicket(enlisted_ticket)) {
            continue;//Opps!!! the order is open so skip
         }

         //At this point we are more sure the order is not open

         bool is_deleted =  OpenTicketList.Delete(i);

         if(is_deleted) {
            i--;
         }


         //we will make sure we don't send packets for orders generated by close operation  - it is useless to do so
         if(isTicketOfSyncClose(enlisted_ticket)) {
            continue;//do no include this order since it is one of those generated by close operation
         }

         //At this point the order was not generated by close operation

         // MT5 ALL OPEN ORDERS 
            // ARE ALSE PART OF HISTORY ORDER AND WHEN THE OPEN ORDERS A CLOSED IT IS
            // ACTUALLY A NEW ORDER IN THE OPPOSITE DIRECTION WITH A DIFFERENT TICKET
            // THAT IS EXECUTED AS IN HEDGE ACCOUNT
         if(FindHistoryOrderByTicket(enlisted_ticket, historyOrderObj)) {

            history_data += generateTradeStreamPacket(historyOrderObj);
            close_trades = true;

         }
         
         

      }

   }

//select history from startup time to now
//@deprecated - using with care
   HistorySelect(HistoryFromTime, TimeCurrent());//important! so that we can call HistoryOrdersTotal() otherwise it will always return zero

//@deprecated - using with care
   int h_total = HistoryOrdersTotal();//from my observation in mql5 HistoryOrdersTotal() is total open and closed trades

   int prev_hist = HistoryTotal; //DEBUG!!!

   if(h_total > HistoryTotal) {
      HistoryTotal = CountHistoryOrders(historyOrderObj); //NEW
   }


   if(close_trades) { //append history to data to be sent
      data += history_data +  "close_trades=true" + TAB;

      Print("h_total ", h_total, " prev_hist ", prev_hist, " HistoryTotal ", HistoryTotal);//DEBUG!!!

      clearTicketsOfSyncClose();//just clear off since the job is done at this time
      clearTicketsOfSyncModify();
   }

   sendData(data);

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountHistoryOrders(CHistoryOrderInfo &hOrder) {

   int count = 0;
//select history from startup time to now

   HistorySelect(HistoryFromTime, TimeCurrent());//important! so that we can call HistoryOrdersTotal() otherwise it will always return zero

   int total = HistoryOrdersTotal();

   for(int i=0; i < total; i++) {

      if(hOrder.SelectByIndex(i)) {

        /*@Deprecated - Because in MT5 (as in Hedge Account Type) 
           the Opposing Order that closes the Position does not have
           Magic number so this IF block is WRONG
         if(hOrder.Magic() != COPIED_TRADE_MAGIC_NUMBER) {
            continue;
         }*/

         if(!isOrderType(hOrder)) { //we only want order type and not credit or balance as displayed in AccountHistory of the Terminal
            continue;
         }
      }

      count ++;
   }

   return count;
}

//THIS A HELPER FUNCTION TO AVOID Position not found ERROR
bool SelectPositionByTicket(CPositionInfo &posOrdObj, long ticket) {
   int pos_total = PositionsTotal();
   for(int i = 0; i < pos_total; i++) {
      if(posOrdObj.SelectByIndex(i)) {
         if(posOrdObj.Ticket() == ticket) {
            return true;
         }
      }
   }

   return false;
}

//THIS A HELPER FUNCTION TO AVOID Position not found ERROR
bool SelectPositionByTicket(long ticket) {
   return SelectPositionByTicket(positionObj, ticket);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool FindHistoryOrderByTicket(ulong ticket, CHistoryOrderInfo &hOrder) {

//select history from startup time to now

   HistorySelect(HistoryFromTime, TimeCurrent());//important! so that we can call HistoryOrdersTotal() otherwise it will always return zero

   int total = HistoryOrdersTotal();

   for(int i=0; i < total; i++) {

      if(hOrder.SelectByIndex(i)) {

         if(!isOrderType(hOrder)) { //we only want order type and not credit or balance as displayed in AccountHistory of the Terminal
            continue;
         }        

         if(hOrder.Magic() == COPIED_TRADE_MAGIC_NUMBER &&
               hOrder.Ticket() == ticket) {
            return true;
         }
      }

   }

   return false;
}

/*@Deprecated
void sendTradeModifyData()
{

      bool modify_trades = false;

      string data = "";

      int total = OrdersTotal();
      for(int i=0; i < total; i++)
         {

            if(positionObj.SelectByIndex(i))
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


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string generateTradeStreamPacket(CPositionInfo &position_order) {
   PacketOrder pckOrder;

   pckOrder.position = getStrPositionType(position_order);
   pckOrder.symbol = position_order.Symbol();
   pckOrder.ticket = position_order.Ticket();
   pckOrder.open_price = position_order.PriceOpen();
   pckOrder.close_price = position_order.PriceCurrent();
   pckOrder.open_time = position_order.Time();
   pckOrder.close_time = 0;
   pckOrder.lot_size = position_order.Volume();
   pckOrder.target = position_order.TakeProfit();
   pckOrder.stoploss = position_order.StopLoss();
   pckOrder.magic = position_order.Magic();
   pckOrder.commission = position_order.Commission();

   return generateTradeStreamPacket(pckOrder);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string generateTradeStreamPacket(CHistoryOrderInfo &history_order) {
   PacketOrder pckOrder;

   pckOrder.position = getStrHistoryOrderType(history_order);
   pckOrder.symbol = history_order.Symbol();
   pckOrder.ticket = history_order.Ticket();
   pckOrder.open_price = history_order.PriceOpen();
   pckOrder.close_price = history_order.PriceCurrent();
   pckOrder.open_time = history_order.TimeDone();//YES
   pckOrder.close_time = (long)TimeCurrent(); //lets using the current time which a more realistic time
   pckOrder.lot_size = history_order.VolumeCurrent();
   pckOrder.target = history_order.TakeProfit();
   pckOrder.stoploss = history_order.StopLoss();
   pckOrder.magic = history_order.Magic();
   pckOrder.commission = INT_MIN; //unknown - important . with this we can skip the sending commission is the value is INT_MIN

   return generateTradeStreamPacket(pckOrder);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string generateTradeStreamPacket(COrderInfo &pending_order) {
   PacketOrder pckOrder;

   pckOrder.position = getStrOrderType(pending_order);
   pckOrder.symbol = pending_order.Symbol();
   pckOrder.ticket = pending_order.Ticket();
   pckOrder.open_price = pending_order.PriceOpen();
   pckOrder.close_price = pending_order.PriceCurrent();
   pckOrder.open_time = 0;
   pckOrder.close_time = 0;
   pckOrder.lot_size = pending_order.VolumeCurrent();
   pckOrder.target = pending_order.TakeProfit();
   pckOrder.stoploss = pending_order.StopLoss();
   pckOrder.magic = pending_order.Magic();
   pckOrder.commission = INT_MIN; //unknown - important . with this we can skip the sending commission is the value is INT_MIN

   return generateTradeStreamPacket(pckOrder);
}


bool AccountInfoUsedByPeer(){


      int total_orders = PositionsTotal();

      TotalCommission = 0;
      TotalLotSize = 0;
      TotalSwap = 0;
      Position = "";
                                                   
      for(int i = 0; i < total_orders; i++){
     
     
         if(!positionObj.SelectByIndex(i)){
             return false; //just leave - no room for error
         }
           
         TotalLotSize += positionObj.Volume();          
         TotalCommission += positionObj.Commission();  
         TotalSwap += positionObj.Swap();  
         Position = positionObj.PositionType() == POSITION_TYPE_BUY? "BUY" 
                     : positionObj.PositionType() == POSITION_TYPE_SELL? "SELL"
                     :"";  
        
     }
     
     return true;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string generateTradeStreamPacket(PacketOrder &pckOrder, double partial_close_fraction = 0) {

   string copy_sender_ticket = "";
   if(pckOrder.magic == COPIED_TRADE_MAGIC_NUMBER) {
      //copy_sender_ticket = extractCopyTicket(OrderComment());//REMOVED - Instead the server will set it
   }


   if(pckOrder.position == "") { //possibly credit or balance as displayed in the AccountHistory
      return "";
   }

   double symbol_point = getUsableSymbolPoint(pckOrder.symbol);      

   string data = "ticket="+pckOrder.ticket+TAB
                 +"symbol="+ refactorSymbol(pckOrder.symbol)+TAB
                 +"raw_symbol="+pckOrder.symbol+TAB
                 +"point="+symbol_point +TAB
                 +"digits="+SymbolInfoInteger(pckOrder.symbol, SYMBOL_DIGITS) +TAB
                 +"position="+pckOrder.position+TAB
                 +"open_price="+pckOrder.open_price+TAB
                 +"close_price="+pckOrder.close_price+TAB
                 +"open_time="+(long)pckOrder.open_time+TAB
                 +"close_time="+(long)pckOrder.close_time+TAB
                 +"lot_size="+pckOrder.lot_size+TAB

//for the case of mql5 skip symbol_commission_per_lot if the value is INT_MIN signifying unknow commission e.g see history order and pending order object which do not reveal commision
                 + (pckOrder.commission == INT_MIN ?("symbol_commission_per_lot="+ DoubleToString(pckOrder.commission/pckOrder.lot_size)+TAB) : "") //come back

                 +"account_expected_hedge_profit="+ExpectedHedgeProfit+TAB
                 +"target="+pckOrder.target+TAB
                 +"stoploss="+pckOrder.stoploss+TAB                    
                 +"partial_close_fraction="+partial_close_fraction+TAB;

   return data;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isUpperCaseChar(ushort c) {
   return (c>=65 && c<=90);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isAlphabet(ushort c) {
   return (c>=65 && c<=90) || (c>=97 && c<=122);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string refactorSymbol(string symbol, bool retain_case = false) {

   if(!isRegularSymbol(symbol)) {
      return symbol;
   }

   int begin = -1;
   int end = -1;
   int count = 0;

   StringReplace(symbol,"/",""); // remove '/' character if any

   int len = StringLen(symbol);

   for(int i = 0; i < len; i++) {

      ushort c = StringGetCharacter(symbol,i);

      if(isAlphabet(c)) {
         count++;
         if(count == 1) {
            begin = i;
         }

         if(count == 6) {
            end = i;
            break;
         }

      } else {
         if(count < 6) {
            count = 0;
         }

      }

   }

   symbol = StringSubstr(symbol, begin, end + 1);

   int index = StringFind(symbol,"/",0);
   if(index>-1) {
      return symbol;
   }

   symbol = StringSubstr(symbol,0,3)+"/"+StringSubstr(symbol,3,3);

   if(!retain_case) {
      StringToUpper(symbol);
   }

   return symbol;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isSevenLetterPair(string pair) {

   int len = StringLen(pair);

   if(len != 7) {
      return false;
   }

   int slash_count = 0;
   int slash_pos = 0;
   for(int i = 0; i < len; i++) {
      slash_pos = i;
      ushort c = StringGetCharacter(pair,i);

      if(!isAlphabet(c)) {
         if(c == '/' && slash_count == 0) {
            if(slash_pos != 3) {
               return false;
            }

            slash_count++;
         } else {
            return false;
         }

      }
   }

   return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isSixLetterPair(string pair) {

   int len = StringLen(pair);

   if(len != 6) {
      return false;
   }

   for(int i = 0; i < len; i++) {
      ushort c = StringGetCharacter(pair,i);

      if(!isAlphabet(c)) {
         return false;
      }
   }

   return true;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isRegularSymbol(string symbol) {


   string split [];
   StringSplit(symbol, '.',split);

   string prefix = "";
   string suffix = "";
   string pair = "";
   int split_size = ArraySize(split);

   if(split_size == 1) {
      pair = split[0];
   }

   if(split_size == 2) {

      string part_1 = split[0];
      string part_2 = split[1];

      if(isSixLetterPair(part_1)) {
         pair = part_1;
         prefix = part_2;
      }

      if(isSevenLetterPair(part_1)) {
         pair = part_1;
         prefix = part_2;
      }

      if(isSixLetterPair(part_2)) {
         if(pair != "") {
            return false; // meaning both parts cannot be pair
         }

         pair = part_2;
         suffix = part_1;

      }

      if(isSevenLetterPair(part_2)) {

         if(pair != "") {
            return false; // meaning both part cannot be pair
         }

         pair = part_2;
         suffix = part_1;
      }

   }


   if(split_size == 3) {
      prefix = split[0];
      pair = split[1];
      suffix = split[2];

   }

   if(split_size > 3) {
      return false;
   }


   if(!isSixLetterPair(pair) && !isSevenLetterPair(pair)) {
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string defactorSymbol(string symb) {

//string symbol = "abc.USD/JPY.xyz"; //mab at work  - replace if Symbol() later

   if(!isRegularSymbol(symb)) {
      return symb;
   }

   string symbol = Symbol();

   int begin = -1;
   int end = -1;
   int count = 0;
   bool has_slash = StringFind(symbol, "/") > -1;
   int len = StringLen(symbol);

   for(int i = 0; i < len; i++) {

      ushort c = StringGetCharacter(symbol,i);

      if(isAlphabet(c) || c == '/') {
         count++;
         if(count == 1) {
            begin = i;
         }

         if((!has_slash && count == 6) || (has_slash && count == 7)) {
            end = i;
            break;
         }

      } else {
         if((!has_slash && count < 6) || (has_slash && count < 7)) {
            count = 0;
         }

      }

   }

   string prefix = begin > 0 ? StringSubstr(symbol,0, begin) : "";
   string suffix = StringSubstr(symbol, end + 1, len - end - 1);

   string s = refactorSymbol(symbol, true);

   if(isUpperCaseChar(StringGetCharacter(s,0))) {
      StringToUpper(symb);
   } else {
      StringToLower(symb);
   }

   bool symb_has_slash = StringFind(symb, "/") > -1;

   symb = StringSubstr(symb,begin,end-begin + 1);

   if(has_slash && !symb_has_slash) {
      symb = StringSubstr(symb,0,3)+"/"+StringSubstr(symb,3,3);
   } else if(!has_slash && symb_has_slash) {
      StringReplace(symb,"/","");
   }

   return prefix+symb+suffix;

}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool openConnection() {


//--- wait for server

   if(!IsStopped()) {

      ExtConnection = Connect(Host, Port);

      bool isDisconnection = !PrintConnectionWaiting && !isConnectionOpen;
      if(ExtConnection) {

         PrintConnectionWaiting=true;
         isConnectionOpen = true;
         Print("Client: connection opened");
         lblAlert.Text("Client: connection opened");
         return true;
      }

      if(PrintConnectionWaiting) {
         PrintConnectionWaiting=false;
         Print("Client: waiting for server");
         lblAlert.Text("Client: waiting for server");
         if(isDisconnection) {
            sendEADisconnectionNotification();
         }
      }

   } else {

      if(PrintEAIsStopped) {
         PrintEAIsStopped=false;
         string str_print_stop = "ATTENTION: The EA has stopped running...Please reload";
         Print(str_print_stop);
         lblAlert.Text(str_print_stop);
         SendNotification(str_print_stop);
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void reconnect(string error_reason, uint errCount = 1) {

   string reconnMsg = errCount == 1
                      ? "Reconnecting... after last error : "+error_reason
                      : "Reconnecting after "+errCount+" successive errors : "+error_reason ;

   Print(reconnMsg);
   lblAlert.Text(reconnMsg);

   channelIfNot();

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string ensureWithTab(string data) {
   return ensureEndWith(data, TAB);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string ensureEndWithNewLine(string data) {
   return ensureEndWith(data, NEW_LINE);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string ensureEndWith(string data, string ch) {

   if(data == "") {
      return "";//no need for new line character
   }

   if(StringSubstr(data, StringLen(data) -1, 1) != ch) {
      data += ch;
   }

   return data;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void validateConnection() {
//We now have a far more efficient commication channel with the remote end so we
//will only be pinging very infrequently just to notify us if the connection is lost
//which is not very likely  though in this our current implementation using C++ DLL


   int timeElapseInMinutesSinceLastPing = (TimeCurrent() - lastPingTime)/60;

   if(timeElapseInMinutesSinceLastPing >= PING_INTERVAL_IN_MINUTES) {
      lastPingTime = TimeCurrent();
      sendData(PING_PACKET);
   }

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sendData(string data) {

   if(data == "") {
      return;
   }


   bool is_ping = data == PING_PACKET;

   StringTrimLeft(data); //remove tailing TAB  - NOTE StringTrimLeft is different from that in mql4
   StringTrimRight(data);//remove tailing TAB  - NOTE StringTrimLeft is different from that in mql4

   data += TAB + "is_market_closed="+(IsMarketClosed == true ? "true": "false");

   data  = ensureEndWithNewLine(data);


   if(!is_ping) {
      //Print("sendData ",data);//TESTING!!!
   }


   uint   size_str=StringLen(data);

   int result = Send(data);

   if(result == -1) {
      if(!IsSocketConnected()) {

         if(!is_ping) {
            Print("Client: failed to send data because connection is closed [",GetSyncLastError(),"]");
            lblAlert.Text(lastSyncTradeErrorDesc());
         } else {
            Print("Pinging detected connection closed.");
            lblAlert.Text("Pinging detected connection closed.");
         }

         //isConnectionOpen = false; //force the EA to reinitialize
         sendEADisconnectionNotification();

         return;
      } else {
         Print("Client: failed to send data [",GetSyncLastError(),"]");
         Print("Client: Contact Administrator to revolve send operation failure.");
         lblAlert.Text("Client: Contact Administrator to revolve send operation failure.");
      }

   }

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string lastSyncTradeErrorDesc() {

   char errStr [255];
   GetSyncLastErrorDesc(errStr, 255);
   return CharArrayToString(errStr);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string receiveData() {

   int last_error = GetLastError();
   if(last_error != 0) {
      Print("Client: Error occured [", ErrorDescription(last_error),"]");
      lblAlert.Text(ErrorDescription(last_error));
      ResetLastError();
   }

   string data;

   int dataLen = GetData();

   if(dataLen >= 0) {

      fialReadCount = 0;

      //char buffer [10]; //@Deprecated - since it is static array it can not be resize in mql5. instead use 'char buffer []'

      char buffer []; //Dynamic array which can be resize in mql5

      ArrayResize(buffer, dataLen); //resize the buffer to length of data available

      if(dataLen > 0) {
         PacketReceived(buffer, dataLen);
         data = CharArrayToString(buffer);
      }


   } else { //error occured

      fialReadCount++;

      string str_last_error = lastSyncTradeErrorDesc();


      if(!IsSocketConnected()) {
         reconnect(str_last_error);
      } else if(IsSocketConnected() && fialReadCount >= 3) {

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
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade() {
//---

}
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result) {
//---

}

//+------------------------------------------------------------------+
//| returns trade server return code description                     |
//+------------------------------------------------------------------+
string TradeServerReturnCodeDescription(int return_code) {
//---
   switch(return_code) {
   case TRADE_RETCODE_REQUOTE:
      return("Requote");
   case TRADE_RETCODE_REJECT:
      return("Request rejected");
   case TRADE_RETCODE_CANCEL:
      return("Request canceled by trader");
   case TRADE_RETCODE_PLACED:
      return("Order placed");
   case TRADE_RETCODE_DONE:
      return("Request completed");
   case TRADE_RETCODE_DONE_PARTIAL:
      return("Only part of the request was completed");
   case TRADE_RETCODE_ERROR:
      return("Request processing error");
   case TRADE_RETCODE_TIMEOUT:
      return("Request canceled by timeout");
   case TRADE_RETCODE_INVALID:
      return("Invalid request");
   case TRADE_RETCODE_INVALID_VOLUME:
      return("Invalid volume in the request");
   case TRADE_RETCODE_INVALID_PRICE:
      return("Invalid price in the request");
   case TRADE_RETCODE_INVALID_STOPS:
      return("Invalid stops in the request");
   case TRADE_RETCODE_TRADE_DISABLED:
      return("Trade is disabled");
   case TRADE_RETCODE_MARKET_CLOSED:
      return("Market is closed");
   case TRADE_RETCODE_NO_MONEY:
      return("There is not enough money to complete the request");
   case TRADE_RETCODE_PRICE_CHANGED:
      return("Prices changed");
   case TRADE_RETCODE_PRICE_OFF:
      return("There are no quotes to process the request");
   case TRADE_RETCODE_INVALID_EXPIRATION:
      return("Invalid order expiration date in the request");
   case TRADE_RETCODE_ORDER_CHANGED:
      return("Order state changed");
   case TRADE_RETCODE_TOO_MANY_REQUESTS:
      return("Too frequent requests");
   case TRADE_RETCODE_NO_CHANGES:
      return("No changes in request");
   case TRADE_RETCODE_SERVER_DISABLES_AT:
      return("Autotrading disabled by server");
   case TRADE_RETCODE_CLIENT_DISABLES_AT:
      return("Autotrading disabled by client terminal");
   case TRADE_RETCODE_LOCKED:
      return("Request locked for processing");
   case TRADE_RETCODE_FROZEN:
      return("Order or position frozen");
   case TRADE_RETCODE_INVALID_FILL:
      return("Invalid order filling type");
   case TRADE_RETCODE_CONNECTION:
      return("No connection with the trade server");
   case TRADE_RETCODE_ONLY_REAL:
      return("Operation is allowed only for live accounts");
   case TRADE_RETCODE_LIMIT_ORDERS:
      return("The number of pending orders has reached the limit");
   case TRADE_RETCODE_LIMIT_VOLUME:
      return("The volume of orders and positions for the symbol has reached the limit");
   }
//---
   return("Invalid return code of the trade server");
}
//+------------------------------------------------------------------+
//| returns runtime error code description                           |
//+------------------------------------------------------------------+
string ErrorDescription(int err_code) {
//---
   switch(err_code) {
   //--- Constant Description
   case ERR_SUCCESS:
      return("The operation completed successfully");
   case ERR_INTERNAL_ERROR:
      return("Unexpected internal error");
   case ERR_WRONG_INTERNAL_PARAMETER:
      return("Wrong parameter in the inner call of the client terminal function");
   case ERR_INVALID_PARAMETER:
      return("Wrong parameter when calling the system function");
   case ERR_NOT_ENOUGH_MEMORY:
      return("Not enough memory to perform the system function");
   case ERR_STRUCT_WITHOBJECTS_ORCLASS:
      return("The structure contains objects of strings and/or dynamic arrays and/or structure of such objects and/or classes");
   case ERR_INVALID_ARRAY:
      return("Array of a wrong type, wrong size, or a damaged object of a dynamic array");
   case ERR_ARRAY_RESIZE_ERROR:
      return("Not enough memory for the relocation of an array, or an attempt to change the size of a static array");
   case ERR_STRING_RESIZE_ERROR:
      return("Not enough memory for the relocation of string");
   case ERR_NOTINITIALIZED_STRING:
      return("Not initialized string");
   case ERR_INVALID_DATETIME:
      return("Invalid date and/or time");
   case ERR_ARRAY_BAD_SIZE:
      return("Requested array size exceeds 2 GB");
   case ERR_INVALID_POINTER:
      return("Wrong pointer");
   case ERR_INVALID_POINTER_TYPE:
      return("Wrong type of pointer");
   case ERR_FUNCTION_NOT_ALLOWED:
      return("System function is not allowed to call");
   //--- Charts
   case ERR_CHART_WRONG_ID:
      return("Wrong chart ID");
   case ERR_CHART_NO_REPLY:
      return("Chart does not respond");
   case ERR_CHART_NOT_FOUND:
      return("Chart not found");
   case ERR_CHART_NO_EXPERT:
      return("No Expert Advisor in the chart that could handle the event");
   case ERR_CHART_CANNOT_OPEN:
      return("Chart opening error");
   case ERR_CHART_CANNOT_CHANGE:
      return("Failed to change chart symbol and period");
   case ERR_CHART_WRONG_PARAMETER:
      return("Error value of the parameter for the function of working with charts");
   case ERR_CHART_CANNOT_CREATE_TIMER:
      return("Failed to create timer");
   case ERR_CHART_WRONG_PROPERTY:
      return("Wrong chart property ID");
   case ERR_CHART_SCREENSHOT_FAILED:
      return("Error creating screenshots");
   case ERR_CHART_NAVIGATE_FAILED:
      return("Error navigating through chart");
   case ERR_CHART_TEMPLATE_FAILED:
      return("Error applying template");
   case ERR_CHART_WINDOW_NOT_FOUND:
      return("Subwindow containing the indicator was not found");
   case ERR_CHART_INDICATOR_CANNOT_ADD:
      return("Error adding an indicator to chart");
   case ERR_CHART_INDICATOR_CANNOT_DEL:
      return("Error deleting an indicator from the chart");
   case ERR_CHART_INDICATOR_NOT_FOUND:
      return("Indicator not found on the specified chart");
   //--- Graphical Objects
   case ERR_OBJECT_ERROR:
      return("Error working with a graphical object");
   case ERR_OBJECT_NOT_FOUND:
      return("Graphical object was not found");
   case ERR_OBJECT_WRONG_PROPERTY:
      return("Wrong ID of a graphical object property");
   case ERR_OBJECT_GETDATE_FAILED:
      return("Unable to get date corresponding to the value");
   case ERR_OBJECT_GETVALUE_FAILED:
      return("Unable to get value corresponding to the date");
   //--- MarketInfo
   case ERR_MARKET_UNKNOWN_SYMBOL:
      return("Unknown symbol");
   case ERR_MARKET_NOT_SELECTED:
      return("Symbol is not selected in MarketWatch");
   case ERR_MARKET_WRONG_PROPERTY:
      return("Wrong identifier of a symbol property");
   case ERR_MARKET_LASTTIME_UNKNOWN:
      return("Time of the last tick is not known (no ticks)");
   case ERR_MARKET_SELECT_ERROR:
      return("Error adding or deleting a symbol in MarketWatch");
   //--- History Access
   case ERR_HISTORY_NOT_FOUND:
      return("Requested history not found");
   case ERR_HISTORY_WRONG_PROPERTY:
      return("Wrong ID of the history property");
   //--- Global_Variables
   case ERR_GLOBALVARIABLE_NOT_FOUND:
      return("Global variable of the client terminal is not found");
   case ERR_GLOBALVARIABLE_EXISTS:
      return("Global variable of the client terminal with the same name already exists");
   case ERR_MAIL_SEND_FAILED:
      return("Email sending failed");
   case ERR_PLAY_SOUND_FAILED:
      return("Sound playing failed");
   case ERR_MQL5_WRONG_PROPERTY:
      return("Wrong identifier of the program property");
   case ERR_TERMINAL_WRONG_PROPERTY:
      return("Wrong identifier of the terminal property");
   case ERR_FTP_SEND_FAILED:
      return("File sending via ftp failed");
   case ERR_NOTIFICATION_SEND_FAILED:
      return("Error in sending notification");
   //--- Custom Indicator Buffers
   case ERR_BUFFERS_NO_MEMORY:
      return("Not enough memory for the distribution of indicator buffers");
   case ERR_BUFFERS_WRONG_INDEX:
      return("Wrong indicator buffer index");
   //--- Custom Indicator Properties
   case ERR_CUSTOM_WRONG_PROPERTY:
      return("Wrong ID of the custom indicator property");
   //--- Account
   case ERR_ACCOUNT_WRONG_PROPERTY:
      return("Wrong account property ID");
   case ERR_TRADE_WRONG_PROPERTY:
      return("Wrong trade property ID");
   case ERR_TRADE_DISABLED:
      return("Trading by Expert Advisors prohibited");
   case ERR_TRADE_POSITION_NOT_FOUND:
      return("Position not found");
   case ERR_TRADE_ORDER_NOT_FOUND:
      return("Order not found");
   case ERR_TRADE_DEAL_NOT_FOUND:
      return("Deal not found");
   case ERR_TRADE_SEND_FAILED:
      return("Trade request sending failed");
   //--- Indicators
   case ERR_INDICATOR_UNKNOWN_SYMBOL:
      return("Unknown symbol");
   case ERR_INDICATOR_CANNOT_CREATE:
      return("Indicator cannot be created");
   case ERR_INDICATOR_NO_MEMORY:
      return("Not enough memory to add the indicator");
   case ERR_INDICATOR_CANNOT_APPLY:
      return("The indicator cannot be applied to another indicator");
   case ERR_INDICATOR_CANNOT_ADD:
      return("Error applying an indicator to chart");
   case ERR_INDICATOR_DATA_NOT_FOUND:
      return("Requested data not found");
   case ERR_INDICATOR_WRONG_HANDLE:
      return("Wrong indicator handle");
   case ERR_INDICATOR_WRONG_PARAMETERS:
      return("Wrong number of parameters when creating an indicator");
   case ERR_INDICATOR_PARAMETERS_MISSING:
      return("No parameters when creating an indicator");
   case ERR_INDICATOR_CUSTOM_NAME:
      return("The first parameter in the array must be the name of the custom indicator");
   case ERR_INDICATOR_PARAMETER_TYPE:
      return("Invalid parameter type in the array when creating an indicator");
   case ERR_INDICATOR_WRONG_INDEX:
      return("Wrong index of the requested indicator buffer");
   //--- Depth of Market
   case ERR_BOOKS_CANNOT_ADD:
      return("Depth Of Market can not be added");
   case ERR_BOOKS_CANNOT_DELETE:
      return("Depth Of Market can not be removed");
   case ERR_BOOKS_CANNOT_GET:
      return("The data from Depth Of Market can not be obtained");
   case ERR_BOOKS_CANNOT_SUBSCRIBE:
      return("Error in subscribing to receive new data from Depth Of Market");
   //--- File Operations
   case ERR_TOO_MANY_FILES:
      return("More than 64 files cannot be opened at the same time");
   case ERR_WRONG_FILENAME:
      return("Invalid file name");
   case ERR_TOO_LONG_FILENAME:
      return("Too long file name");
   case ERR_CANNOT_OPEN_FILE:
      return("File opening error");
   case ERR_FILE_CACHEBUFFER_ERROR:
      return("Not enough memory for cache to read");
   case ERR_CANNOT_DELETE_FILE:
      return("File deleting error");
   case ERR_INVALID_FILEHANDLE:
      return("A file with this handle was closed, or was not opening at all");
   case ERR_WRONG_FILEHANDLE:
      return("Wrong file handle");
   case ERR_FILE_NOTTOWRITE:
      return("The file must be opened for writing");
   case ERR_FILE_NOTTOREAD:
      return("The file must be opened for reading");
   case ERR_FILE_NOTBIN:
      return("The file must be opened as a binary one");
   case ERR_FILE_NOTTXT:
      return("The file must be opened as a text");
   case ERR_FILE_NOTTXTORCSV:
      return("The file must be opened as a text or CSV");
   case ERR_FILE_NOTCSV:
      return("The file must be opened as CSV");
   case ERR_FILE_READERROR:
      return("File reading error");
   case ERR_FILE_BINSTRINGSIZE:
      return("String size must be specified, because the file is opened as binary");
   case ERR_INCOMPATIBLE_FILE:
      return("A text file must be for string arrays, for other arrays - binary");
   case ERR_FILE_IS_DIRECTORY:
      return("This is not a file, this is a directory");
   case ERR_FILE_NOT_EXIST:
      return("File does not exist");
   case ERR_FILE_CANNOT_REWRITE:
      return("File can not be rewritten");
   case ERR_WRONG_DIRECTORYNAME:
      return("Wrong directory name");
   case ERR_DIRECTORY_NOT_EXIST:
      return("Directory does not exist");
   case ERR_FILE_ISNOT_DIRECTORY:
      return("This is a file, not a directory");
   case ERR_CANNOT_DELETE_DIRECTORY:
      return("The directory cannot be removed");
   case ERR_CANNOT_CLEAN_DIRECTORY:
      return("Failed to clear the directory (probably one or more files are blocked and removal operation failed)");
   case ERR_FILE_WRITEERROR:
      return("Failed to write a resource to a file");
   //--- String Casting
   case ERR_NO_STRING_DATE:
      return("No date in the string");
   case ERR_WRONG_STRING_DATE:
      return("Wrong date in the string");
   case ERR_WRONG_STRING_TIME:
      return("Wrong time in the string");
   case ERR_STRING_TIME_ERROR:
      return("Error converting string to date");
   case ERR_STRING_OUT_OF_MEMORY:
      return("Not enough memory for the string");
   case ERR_STRING_SMALL_LEN:
      return("The string length is less than expected");
   case ERR_STRING_TOO_BIGNUMBER:
      return("Too large number, more than ULONG_MAX");
   case ERR_WRONG_FORMATSTRING:
      return("Invalid format string");
   case ERR_TOO_MANY_FORMATTERS:
      return("Amount of format specifiers more than the parameters");
   case ERR_TOO_MANY_PARAMETERS:
      return("Amount of parameters more than the format specifiers");
   case ERR_WRONG_STRING_PARAMETER:
      return("Damaged parameter of string type");
   case ERR_STRINGPOS_OUTOFRANGE:
      return("Position outside the string");
   case ERR_STRING_ZEROADDED:
      return("0 added to the string end, a useless operation");
   case ERR_STRING_UNKNOWNTYPE:
      return("Unknown data type when converting to a string");
   case ERR_WRONG_STRING_OBJECT:
      return("Damaged string object");
   //--- Operations with Arrays
   case ERR_INCOMPATIBLE_ARRAYS:
      return("Copying incompatible arrays. String array can be copied only to a string array, and a numeric array - in numeric array only");
   case ERR_SMALL_ASSERIES_ARRAY:
      return("The receiving array is declared as AS_SERIES, and it is of insufficient size");
   case ERR_SMALL_ARRAY:
      return("Too small array, the starting position is outside the array");
   case ERR_ZEROSIZE_ARRAY:
      return("An array of zero length");
   case ERR_NUMBER_ARRAYS_ONLY:
      return("Must be a numeric array");
   case ERR_ONEDIM_ARRAYS_ONLY:
      return("Must be a one-dimensional array");
   case ERR_SERIES_ARRAY:
      return("Timeseries cannot be used");
   case ERR_DOUBLE_ARRAY_ONLY:
      return("Must be an array of type double");
   case ERR_FLOAT_ARRAY_ONLY:
      return("Must be an array of type float");
   case ERR_LONG_ARRAY_ONLY:
      return("Must be an array of type long");
   case ERR_INT_ARRAY_ONLY:
      return("Must be an array of type int");
   case ERR_SHORT_ARRAY_ONLY:
      return("Must be an array of type short");
   case ERR_CHAR_ARRAY_ONLY:
      return("Must be an array of type char");
   //--- Operations with OpenCL
   case ERR_OPENCL_NOT_SUPPORTED:
      return("OpenCL functions are not supported on this computer");
   case ERR_OPENCL_INTERNAL:
      return("Internal error occurred when running OpenCL");
   case ERR_OPENCL_INVALID_HANDLE:
      return("Invalid OpenCL handle");
   case ERR_OPENCL_CONTEXT_CREATE:
      return("Error creating the OpenCL context");
   case ERR_OPENCL_QUEUE_CREATE:
      return("Failed to create a run queue in OpenCL");
   case ERR_OPENCL_PROGRAM_CREATE:
      return("Error occurred when compiling an OpenCL program");
   case ERR_OPENCL_TOO_LONG_KERNEL_NAME:
      return("Too long kernel name (OpenCL kernel)");
   case ERR_OPENCL_KERNEL_CREATE:
      return("Error creating an OpenCL kernel");
   case ERR_OPENCL_SET_KERNEL_PARAMETER:
      return("Error occurred when setting parameters for the OpenCL kernel");
   case ERR_OPENCL_EXECUTE:
      return("OpenCL program runtime error");
   case ERR_OPENCL_WRONG_BUFFER_SIZE:
      return("Invalid size of the OpenCL buffer");
   case ERR_OPENCL_WRONG_BUFFER_OFFSET:
      return("Invalid offset in the OpenCL buffer");
   case ERR_OPENCL_BUFFER_CREATE:
      return("Failed to create and OpenCL buffer");
   //--- User-Defined Errors
   default:
      if(err_code>=ERR_USER_ERROR_FIRST && err_code<ERR_USER_ERROR_LAST)
         return("User error "+string(err_code-ERR_USER_ERROR_FIRST));
   }
//---
   return("Unknown error");
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
