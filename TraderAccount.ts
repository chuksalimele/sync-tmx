

import {ipcSend } from "./main";
import { Order } from "./Order";
import { SyncUtil } from "./SyncUtil";
import { Config } from "./Config";
import { Constants } from "./Constants"; 
import { OrderPlacement } from "./OrderPlacement"; 
import { SyncTraderException } from "./SyncTraderException";
import { MessageBuffer } from './MessageBuffer';
import { PairAccount, PairOrder, PairBitOrder } from "./Types"
import logger from "./Logger";

export class TraderAccount {
   
    private version: string;
    private intro_time: number;
    private broker: string;
    private account_number: string;
    private account_name: string;
    private chart_symbol: string;
    private chart_symbol_digits: number;
    private only_trade_with_credit : boolean;
    private chart_symbol_trade_allowed : boolean;
    private terminal_connected : boolean;
    private platform_type: string;
    private sync_copy_manual_entry: boolean = false;
    private sync_state_pair_id : string = "";
    private open_tickets : Array<string> = [];
    private icon_file: string;
    private chart_symbol_max_lot_size: number = 0;
    private chart_symbol_min_lot_size: number = 0;
    private chart_symbol_tick_value: number = 0;
    private chart_symbol_tick_size: number = 0;    
    private chart_symbol_swap_long: number = 0;
    private chart_symbol_swap_short: number = 0;
    private chart_symbol_trade_units: number = 0;    
    private chart_symbol_spread: number = 0;    
    private account_balance: number = 0;
    private account_equity: number = 0;
    private account_credit: number = 0;
    private account_currency: string = "";
    private account_leverage: number = 0;
    private account_margin: number = 0;
    private account_stopout_level: number = 0;
    private account_profit: number = 0;
    private account_free_margin: number = 0;
    private account_swap_per_day: number = 0; 
    private account_trade_cost: number = 0;
    private account_swap_cost: number = 0;
    private account_commission_cost: number = 0;
    private expected_exit_profit: number = 0;
    private expected_target_profit: number = 0;
    private expected_exit_balance: number = 0;
    private expected_target_balance: number = 0;
    private total_commission: number = 0;
    private total_swap: number = 0;
    private total_lot_size: number = 0;
    private total_open_orders: number = 0;    
    private contract_size: number = 0;
    private base_open_price: number = 0;
    private position: string = "";
    private chart_market_price: number = 0;//this is the current market price on the chart where the EA is loaded
    private exchange_rate_for_margin_requirement: number = 0;
    private hedge_profit: number = 0;
    private trade_copy_type: string;
    private ea_executable_file: string = '';
    private is_market_closed: boolean;
    private is_live_account: boolean|null;
    private is_requesting_take_profit_param = false;
    private is_modifying_take_profit = false;
    private ea_up_to_date: boolean|null = null;//unknown
    private orders: Map<number, Order> = new Map<number, Order>();
    private CopyRetryAttempt: Map<number, number> = new Map<number, number>();
    private CloseRetryAttempt: Map<number, number> = new Map<number, number>();
    private ModifyTargetRetryAttempt: Map<number, number> = new Map<number, number>();
    private PlaceOrderRetryAttempt: Map<string, number> = new Map<string, number>();        
    private message: MessageBuffer = new MessageBuffer(Constants.NEW_LINE);
    private last_error: string = "";
    private peer: TraderAccount | null = null;
    private lastPeerBroker: string = "";
    private lastPeerAccountNumber: string= "";
    private readonly SEP: string = "_";
    private IsSockConnected: boolean;
    private socket: any;
    private readonly MODIFY_TARGET: number = 1;
    private readonly MODIFY_STOPLOSS: number = 2;
    public SyncPlacingOrders: Map<string, OrderPlacement> = new Map<string, OrderPlacement>();
    public EACommandList: Map<string, IEACommand> =  new Map<string, IEACommand>();
    public test :number = 0;
    constructor(socket: any) {
        this.test = 7;
        this.socket = socket;
        this.IsSockConnected = true;
        socket.on('data', this.OnSocketData.bind(this));
        socket.on('end', this.OnSocketEnd.bind(this));
        socket.on('close', this.OnSocketClose.bind(this));
        socket.on('error', this.OnSocketError.bind(this));
    }

    public Close(){
        this.socket.destroy();
    }

    /**
     *Create a uncircular object of itself so that we don't get circular reference error 
     * when serializing e.g in ipc transmission
     **/
    public CopyAttr() {

        var column_index = this.peer !=null ? this.PairColumnIndex() : -1;
        var pair_id = this.peer != null ? this.PairID() : '';
        
        var peer_column_index = -1;
        if(column_index == 1){
            peer_column_index = 0;
        }else if(column_index == 0){
            peer_column_index = 1;
        }

        var peer_pair_id = pair_id; // is the same

        return {
            version: this.version,
            broker: this.broker,
            account_number: this.account_number,
            account_name: this.account_name,
            account_balance: this.account_balance,
            account_equity: this.account_equity,
            account_credit: this.account_credit,
            account_currency: this.account_currency,
            account_leverage: this.account_leverage,
            account_margin: this.account_margin,
            account_stopout_level: this.account_stopout_level,
            account_profit: this.account_profit,
            account_free_margin: this.account_free_margin,
            account_trade_cost: this.account_trade_cost,
            account_swap_cost: this.account_swap_cost,
            account_commission_cost: this.account_commission_cost,
            hedge_profit: this.hedge_profit,
            terminal_connected : this.terminal_connected,
            only_trade_with_credit: this.only_trade_with_credit,
            chart_symbol: this.chart_symbol,         
            chart_symbol_digits: this.chart_symbol_digits,                     
            chart_symbol_trade_allowed: this.chart_symbol_trade_allowed,   
            chart_symbol_max_lot_size: this.chart_symbol_max_lot_size,
            chart_symbol_min_lot_size: this.chart_symbol_min_lot_size,
            chart_symbol_tick_value: this.chart_symbol_tick_value,
            chart_symbol_swap_long: this.chart_symbol_swap_long,
            chart_symbol_swap_short: this.chart_symbol_swap_short,
            chart_symbol_trade_units: this.chart_symbol_trade_units,    
            chart_symbol_spread: this.chart_symbol_spread,                        
            chart_market_price: this.chart_market_price,
            exchange_rate_for_margin_requirement: this.exchange_rate_for_margin_requirement,            
            expected_exit_profit: this.expected_exit_profit,
            expected_target_profit: this.expected_target_profit,
            expected_exit_balance: this.expected_exit_balance,
            expected_target_balance: this.expected_target_balance,
            platform_type: this.platform_type,
            icon_file: this.icon_file,
            is_market_closed: this.is_market_closed,
            ea_executable_file:this.ea_executable_file,
            is_live_account: this.is_live_account,
            ea_up_to_date: this.ea_up_to_date,            
            trade_copy_type: this.trade_copy_type,
            orders: this.Orders(),//array of orders - important!
            column_index: column_index,
            pair_id: pair_id,
            last_error: this.last_error,

            peer: this.peer == null ? null : {
                version: this.peer.version,
                broker: this.peer.broker,
                account_number: this.peer.account_number,
                account_name: this.peer.account_name,
                account_balance: this.peer.account_balance,
                account_equity: this.peer.account_equity,
                account_credit: this.peer.account_credit,
                account_currency: this.peer.account_currency,
                account_leverage: this.peer.account_leverage,
                account_margin: this.peer.account_margin,
                account_stopout_level: this.peer.account_stopout_level,
                account_profit: this.peer.account_profit,
                account_free_margin: this.peer.account_free_margin,
                account_trade_cost: this.peer.account_trade_cost,
                account_swap_cost: this.peer.account_swap_cost,
                account_commission_cost: this.peer.account_commission_cost,
                hedge_profit: this.peer.hedge_profit,
                terminal_connected : this.peer.terminal_connected,
                only_trade_with_credit: this.peer.only_trade_with_credit,
                chart_symbol: this.peer.chart_symbol,
                chart_symbol_digits: this.peer.chart_symbol_digits,
                chart_symbol_trade_allowed: this.peer.chart_symbol_trade_allowed,
                chart_symbol_max_lot_size: this.peer.chart_symbol_max_lot_size,
                chart_symbol_min_lot_size: this.peer.chart_symbol_min_lot_size,
                chart_symbol_tick_value: this.peer.chart_symbol_tick_value,
                chart_symbol_swap_long: this.peer.chart_symbol_swap_long,
                chart_symbol_swap_short: this.peer.chart_symbol_swap_short,
                chart_symbol_trade_units: this.peer.chart_symbol_trade_units,     
                chart_symbol_spread: this.peer.chart_symbol_spread,                                
                chart_market_price: this.peer.chart_market_price,
                exchange_rate_for_margin_requirement: this.peer.exchange_rate_for_margin_requirement,                
                expected_exit_profit: this.peer.expected_exit_profit,
                expected_target_profit: this.peer.expected_target_profit,
                expected_exit_balance: this.peer.expected_exit_balance,
                expected_target_balance: this.peer.expected_target_balance,
                platform_type: this.peer.platform_type,
                icon_file: this.peer.icon_file,
                is_market_closed: this.peer.is_market_closed,
                ea_executable_file:this.peer.ea_executable_file,
                is_live_account: this.peer.is_live_account,
                ea_up_to_date: this.peer.ea_up_to_date,            
                trade_copy_type: this.peer.trade_copy_type,
                orders: this.peer.Orders(),//array of orders - important!
                column_index: peer_column_index, 
                pair_id: peer_pair_id,
                last_error: this.peer.last_error,

                
            }
        }
    }

    public Peer(): TraderAccount { return this.peer };

    public RemovePeer() { 
        if(!this.peer) return;
        
        this.SendData(SyncUtil.UnpairedNotificationPacket(this.peer.broker, this.peer.account_number));
        return this.peer = null
    };

    public LastPeerBroker(){
        return this.lastPeerBroker;
    }

    public LastPeerAccountNumber(){
        return this.lastPeerAccountNumber;
    }

    public Version(): string { return this.version };

    public SetIntroTime(){
        if(!this.intro_time){
            this.intro_time = Date.now();
        }
    }

    public GetIntroTime():number {return this.intro_time; }

    public Broker(): string { return this.broker };

    public AccountNumber(): string { return this.account_number };

    public AccountName(): string { return this.account_name };

    public AccountBalance(): number { return this.account_balance };

    public AccountEquity(): number { return this.account_equity };

    public AccountCredit(): number { return this.account_credit };

    public AccountCurrency(): string { return this.account_currency };

    public AccountMargin(): number { return this.account_margin };

    public AccountFreeMargin(): number { return this.account_free_margin };

    public AccountLeverage(): number { return this.account_leverage };

    public AccountStopoutLevel(): number { return this.account_stopout_level };

    public AccountProfit(): number { return this.account_profit };

    public AccountSwapPerDay(): number { return this.account_swap_per_day };

    public AccountTradeCost(): number { return this.account_trade_cost };

    public AccountSwapCost(): number { return this.account_swap_cost };
    
    public AccountCommissionCost(): number { return this.account_commission_cost };

    public HedgeProfit(): number { return this.hedge_profit };
    
    public TotalCommission(): number { return this.total_commission };
    
    public TotalSwap(): number { return this.total_swap };
    
    public TotalLotSize(): number { return this.total_lot_size };

    public TotalOpenOrders(): number { return this.total_open_orders };
    
    public ContractSize(): number { return this.contract_size };

    public BaseOpenPrice(): number { return this.base_open_price};

    public Position(): string { return this.position };            

    public TerminalConnected(): boolean { return this.terminal_connected };

    public OnlyTradeWithCredit(): boolean { return this.only_trade_with_credit };

    public ChartSymbol(): string { return this.chart_symbol };

    public ChartSymbolDigits(): number { return this.chart_symbol_digits };

    public ChartSymbolTradeAllowed(): boolean { return this.chart_symbol_trade_allowed };

    public ChartSymbolMaxLotSize(): number { return this.chart_symbol_max_lot_size; };

    public ChartSymbolMinLotSize(): number { return this.chart_symbol_min_lot_size; };

    public ChartSymbolTickValue(): number { return this.chart_symbol_tick_value; };

    public ChartSymbolTickSize(): number { return this.chart_symbol_tick_size; };
    
    public ChartSymbolSwapLong(): number { return this.chart_symbol_swap_long; };

    public ChartSymbolSwapShort(): number { return this.chart_symbol_swap_short; };

    public ChartSymbolTradeUnits(): number { return this.chart_symbol_trade_units; };

    public ChartSymbolSpread(): number { return this.chart_symbol_spread; };

    public ChartMarketPrice(): number { return this.chart_market_price; };
    
    public ExchangeRateForMarginRequirement(): number { return this.exchange_rate_for_margin_requirement; };
    
    public PlatformType(): string { return this.platform_type };

    public SyncCopyManualEntry() {return this.sync_copy_manual_entry};

    public IconFile(): string { return this.icon_file };

    public EAExecutableFile():string{return this.ea_executable_file};

    public IsMT4():boolean{
        return this.ea_executable_file.endsWith('.ex4');
    }

    public IsMT5():boolean{
        return this.ea_executable_file.endsWith('.ex5');
    }

    public IsMarketClosed(): boolean { return this.is_market_closed };

    public IsLiveAccount(): boolean { return this.is_live_account };

    public IsEAUpToDate(): boolean|null { return this.ea_up_to_date };

    public GetLastError(): string { return this.last_error };

    public SyncStatePairID(){return this.sync_state_pair_id;}


    TradeCopyType(): string { return this.trade_copy_type };

    public Dispose(): void { this.socket = null }


    private OnSocketData(data: string) {
        this.message.push(data);
    }

    private OnSocketEnd() {
        this.IsSockConnected = false;
        ipcSend('account-disconnect', this.CopyAttr());
    }

    private OnSocketError() {
        this.IsSockConnected = false;
        ipcSend('account-disconnect', this.CopyAttr());
    }

    private OnSocketClose() {
        this.IsSockConnected = false;
        ipcSend('account-disconnect', this.CopyAttr());
    }

    public IsPlacementOrderClosed(uuid: string): boolean {
        var placement = this.SyncPlacingOrders.get(uuid);
        if (!placement) {
            return true;//meaning we have deleted it
        }
        if (placement.ticket == -1) {
            return false;//most likely the order placement is inprogress
        }

        var order: Order = this.GetOrder(placement.ticket);
        if (!order) {
            //return false if order is not found. this is logically correct because the order is yet to be created so it is not really closed.
            //We are only concerned about orders that was open (ie once created) and then closed with a close timestamp on it.
            return false; 
        }
        return order.IsClosed(); 
    }

    /*
     * Ensure that all the orders that are marked to be syncing are reset to false
     * 
     */

    public ResetOrdersSyncing() {
        var orders = this.Orders();
        for (var order of orders) {
            order.SyncCopying(false);
            order.Closing(false);
            order.SyncModifyingStoploss(false);
            order.SyncModifyingTarget(false);
        }
    }

    public IsSyncingInProgress(): boolean {
        var orders = this.Orders();
        for (var order of orders) {
            if (order.IsSyncCopying()
                || order.IsClosing()
                || order.IsSyncModifyingStoploss()
                || order.IsSyncModifyingTarget()) {
                return true;
            }
        }

        //check for peer also

        if (!this.peer) {
            return false;
        }

        var peer_orders = this.peer.Orders();
        for (var peer_order of peer_orders) {
            if (peer_order.IsSyncCopying()
                || peer_order.IsClosing()
                || peer_order.IsSyncModifyingStoploss()
                || peer_order.IsSyncModifyingTarget()) {
                return true;
            }
        }

        return false;
    }

    public SendData(data: string): void {
                
        if (!data.endsWith(Constants.NEW_LINE)) {
            data += Constants.NEW_LINE;
        }
        
        try {
            this.socket.write(Buffer.from(data));
        } catch (e) {
            logger.error(e.message);
            console.log(e);
        }
    }

    public HasReceived(): boolean {
        return !this.message.isFinished();
    }

    public ReceiveData(): string {
        return this.message.getMessage();
    }

    
    public SetVersion(version: string): void {
        this.version = version
    }
    
    public SetBroker(broker: string): void {
        this.broker = broker
    }

    public SetIconFile(icon_file: string): void {
        this.icon_file = icon_file
    }


    public SetAccountNumber(account_number: string): void {
        this.account_number = account_number
    }


    public SetAccountName(account_name: string): void {
        this.account_name = account_name
    }

    public SetAccountBalance(account_balance: number): void {
        this.account_balance = account_balance
    }

    public SetAccountEquity(account_equity: number): void {
        this.account_equity = account_equity
    }

    public SetAccountCredit(account_credit: number): void {
        this.account_credit = account_credit
    }


    public SetAccountCurrency(account_currency: string): void {
        this.account_currency = account_currency
    }


    public SetAccountLeverage(account_leverage: number): void {
        this.account_leverage = account_leverage
    }


    public SetAccountMargin(account_margin: number): void {
        this.account_margin = account_margin
    }


    public SetAccountStopoutLevel(account_stopout_level: number): void {
        this.account_stopout_level = account_stopout_level
    }


    public SetAccountProfit(account_profit: number): void {
        this.account_profit = account_profit
    }


    public SetAccountFreeMargin(account_free_margin: number): void {
        this.account_free_margin = account_free_margin
    }


    public SetAccountSwapPerDay(account_swap_per_day: number): void {
        this.account_swap_per_day = account_swap_per_day
    }

    public SetAccountTradeCost(account_trade_cost: number): void {
        this.account_trade_cost = account_trade_cost
    }

    public SetAccountSwapCost(account_swap_cost: number): void {
        this.account_swap_cost = account_swap_cost
    }

    public SetAccountCommissionCost(account_commission_cost: number): void {
        this.account_commission_cost = account_commission_cost
    }

    public SetHedgeProfit(hedge_profit: number): void {
        this.hedge_profit = hedge_profit
    }

    private GetCommissionPerLot(symbol: string): number|string{
        
        var commsionConfig = SyncUtil.AppConfigMap.get('brokers_commission_per_lot')

        if(!commsionConfig 
            || !commsionConfig[this.broker] 
            || !commsionConfig[this.broker][this.account_number]){
            return "unknown"
        }

        var commission = commsionConfig[this.broker][this.account_number][symbol];

        if(commission === 0 || commission < 0 || commission > 0){
            return commission;
        }

        return 'unknown'

    }

    public SetSymbolCommissionPerLot(symbol: string, conmission_per_lot: number): void {
        var saved_conmission_per_lot = this.GetCommissionPerLot(symbol)

        if(saved_conmission_per_lot === conmission_per_lot){
            return;
        }

        var commsionConfig = SyncUtil.AppConfigMap.get('brokers_commission_per_lot')

        if(!commsionConfig){
            commsionConfig = {};
        }

        if(!commsionConfig[this.broker]){
            commsionConfig[this.broker] = {};
        }
        if(!commsionConfig[this.broker][this.account_number]){
            commsionConfig[this.broker][this.account_number] = {};
        }

        if(!commsionConfig[this.broker][this.account_number][symbol]){
            commsionConfig[this.broker][this.account_number][symbol] = conmission_per_lot;
        }

        SyncUtil.AppConfigMap.set('brokers_commission_per_lot', commsionConfig);

        var configObj = SyncUtil.MapToObject(SyncUtil.AppConfigMap);

        SyncUtil.SaveAppConfig(configObj, function (success) {
           //TODO - report error if any
        })


    }
    
    public SetTerminalConnected(terminal_connected: boolean): void {
        this.terminal_connected = terminal_connected
    }

    public SetOnlyTradeWithCredit(only_trade_with_credit: boolean): void {
        this.only_trade_with_credit = only_trade_with_credit
    }
    
    public SetChartSymbol(chart_symbol: string): void {
        this.chart_symbol = chart_symbol
    }
    
    public SetChartSymbolDigits(chart_symbol_digits: number): void {
        this.chart_symbol_digits = chart_symbol_digits
    }
    
    public SetChartSymbolTradeAllowed(chart_symbol_trade_allowed: boolean): void {
        this.chart_symbol_trade_allowed = chart_symbol_trade_allowed
    }
    
    public SetChartSymbolMaxLotSize(chart_symbol_max_lot_size: number): void {
        this.chart_symbol_max_lot_size = chart_symbol_max_lot_size
    }

    public SetChartSymbolMinLotSize(chart_symbol_min_lot_size: number): void {
        this.chart_symbol_min_lot_size = chart_symbol_min_lot_size
    }

    public SetChartSymbolTickValue(chart_symbol_tick_value: number): void {
        this.chart_symbol_tick_value = chart_symbol_tick_value
    }

    public SetChartSymbolTickSize(chart_symbol_tick_size: number): void {
        this.chart_symbol_tick_size = chart_symbol_tick_size
    }

    public SetChartSymbolSwapLong(chart_symbol_swap_long: number): void {
        this.chart_symbol_swap_long = chart_symbol_swap_long
    }

    public SetChartSymbolSwapShort(chart_symbol_swap_short: number): void {
        this.chart_symbol_swap_short = chart_symbol_swap_short
    }

    public SetChartSymbolTradeUnits(chart_symbol_trade_units: number): void {
        this.chart_symbol_trade_units = chart_symbol_trade_units
    }

    public SetChartSymbolSpread(chart_symbol_spread: number): void {
        this.chart_symbol_spread = chart_symbol_spread
    }

    public SetChartMarketPrice(chart_market_price: number): void {
        this.chart_market_price = chart_market_price
    }

    public SetExchangeRateForMarginRequirement(exchange_rate_for_margin_requirement: number): void {
        this.exchange_rate_for_margin_requirement = exchange_rate_for_margin_requirement
    }    
    
    public SetExpectedExitProfit(expected_exit_profit: number): void {
        this.expected_exit_profit = expected_exit_profit
    }

    public SetExpectedTargetProfit(expected_target_profit: number): void {
        this.expected_target_profit = expected_target_profit
    }

    public SetExpectedExitBalance(expected_exit_balance: number): void {
        this.expected_exit_balance = expected_exit_balance
    }

    public SetExpectedTargetBalance(expected_target_balance: number): void {
        this.expected_target_balance = expected_target_balance
    }

    public SetTotalCommission(total_commission: number): void {
        this.total_commission = total_commission
    }

    public SetTotalSwap(total_swap: number): void {
        this.total_swap = total_swap
    }

    public SetTotalLotSize(total_lot_size: number): void {
        this.total_lot_size = total_lot_size
    }

    public SetTotalOpenOrder(total_open_orders: number): void {
        this.total_open_orders = total_open_orders
    }    
    
    public SetContractSize(contract_size: number): void {
        this.contract_size = contract_size
    }

    public SetBaseOpenPrice(base_open_price: number): void {
        this.base_open_price = base_open_price
    }    
    
    public SetPosition(position: string): void {
        this.position = position
    }
                       
    public SetPlatformType(platform_type: string): void {
        this.platform_type = platform_type
    }
    
    public SetSyncCopyManualEntry(sync_copy_manual_entry: boolean): void {
        this.sync_copy_manual_entry = sync_copy_manual_entry
    }
    
    public SetEAExecutableFile(ea_executable_file: string): void {
        this.ea_executable_file = ea_executable_file || ''
    }

    public SetMarketClosed(is_market_closed: boolean): void {
        this.is_market_closed = is_market_closed
    }

    public SetIsLiveAccount(is_live_account: boolean): void {
        this.is_live_account = is_live_account
    }
    
    public SetEAUpToDate(ea_up_to_date: boolean|null): void {
        this.ea_up_to_date = ea_up_to_date
    }

    public SetTradeCopyType(trade_copy_type: string): void {
        this.trade_copy_type = trade_copy_type
    }

    public SetLastError(last_error: string): void {
        this.last_error = last_error
    }

    public SetSyncStatePairID(sync_state_pair_id: string){
        this.sync_state_pair_id = sync_state_pair_id;
    }
    
    public SetOpenTickets(open_tickets: Array<string>){
        this.open_tickets = open_tickets;
    }
    
    public SetPeer(peer: TraderAccount): void {
        if (peer == null) {
            throw new SyncTraderException("Peer cannot be null");
        }
        if (this.StrID() === peer.StrID()) {
            throw new SyncTraderException("Compared TraderAccount cannot be the same as peer!");
        }
        this.peer = peer;

        this.lastPeerBroker = this.peer.Broker();
        this.lastPeerAccountNumber = this.peer.AccountNumber();
    }

    public EnsureTicketPeer(bitOrderPairs: Map<string, PairBitOrder[]>) {
        if (!this.peer) {
            return;
        }
        
        var paired_bit_orders = bitOrderPairs.get(this.PairID());
        if (!paired_bit_orders) {
            return;
        }
        for (var pair_ticket of paired_bit_orders) {
            
            var own_bit_order: BitOrder = pair_ticket[this.PairColumnIndex()];//modified111
            var own_order = this.orders.get(own_bit_order?.ticket);//modified111

            var peer_bit_order: BitOrder = pair_ticket[this.peer.PairColumnIndex()];//modified111
            var peer_order = this.peer.orders.get(peer_bit_order?.ticket);//modified111

            if (own_order) {
                own_order.peer_ticket = peer_bit_order.ticket;//modified111
            }

            if (peer_order) {
                peer_order.peer_ticket = own_bit_order.ticket;//modified111
            }

        }
        
    }

    public IsConnected(): boolean {
        return this.IsSockConnected;
    }

    public Ping(): void {
        this.SendData(SyncUtil.PingPacket());
    }

    public IsKnown() {
        return this.broker !== null && this.broker.length > 0 && this.account_number !== null && this.account_number.length > 0;
    }


    public SetOrder(bit_order: BitOrder) {
        
        if (bit_order && !this.orders.get(bit_order.ticket)) {
            this.orders.set(bit_order.ticket, new Order(bit_order));
        }
    }

    public GetOrder(ticket: number): Order {
        return this.orders.get(ticket);
    }

    public Orders(): Order[] {
        if (this.orders == null)
            return new Order[0];
        var arr: Array<Order> = Array.from(this.orders.values());

        return arr;
    }

    public OpenOrdersCount(): number {
        var count: number = 0;       
        this.orders.forEach(function (order: Order, key, map) {
            if (order.close_time == 0) {
                count++;
            }
        })
        return count;
    }

    private TrueSymbolPointForSpread(){

        var own_point: number = this.ChartSymbolTickSize() / this.ChartSymbolTickValue();

        if(this.peer == null){
            return this.ChartSymbolTickSize();
        }

        var peer_point: number = this.peer.ChartSymbolTickSize() / this.peer.ChartSymbolTickValue();

        if(own_point == peer_point){ // it is expected to be the same
            return own_point;
        }

        return own_point; // this should not happen!
    }

    public CalculateMarginRequire(lot: number){
        return lot
                *this.ChartSymbolTradeUnits()
                *this.ExchangeRateForMarginRequirement()
                /this.AccountLeverage();
    }

    public CalculateCommision(lot: number, symbol: string = this.chart_symbol): number{
        var comm_per_lot: any = this.GetCommissionPerLot(symbol);
        return !isNaN(comm_per_lot) ? (comm_per_lot * lot): 0;
    }

    public IsCommisionKnown(symbol: string = this.chart_symbol): boolean{
        var comm_per_lot: any = this.GetCommissionPerLot(symbol);
        return !isNaN(comm_per_lot);
    }

    public CalculateSpreadCost(lot: number): number{
        var cost = -Math.abs(this.ChartSymbolSpread() * lot);//must alway return negative
        return  parseFloat(cost.toFixed(2))  * this.ChartSymbolTickValue() ;
    }

    public CalculateSwapPerDay(position:string, lot: number): number{
        var swap = 0;
        if(position== 'BUY'){
            swap = this.ChartSymbolSwapLong();
        }else if(position== 'SELL'){
            swap = this.ChartSymbolSwapShort();
        }
        var cost = swap * lot;
        return  parseFloat(cost.toFixed(2))  * this.ChartSymbolTickValue();
    }

    public AmmountToPips(amount: number,  lots: number): number{
        return amount /(lots);
    }
        
    public DetermineLotSizefromPips(pips: number): number|string {

       /*var lot: number  = 
       (this.AccountBalance() + this.AccountCredit()) /
        (pips *  this.ChartSymbolTickValue() + this.ChartSymbolTradeUnits()*this.ChartMarketPrice()/this.AccountLeverage() * this.AccountStopoutLevel() / 100)
        */

        var lot: number  = 
       (this.AccountBalance() + this.AccountCredit()) /
        (pips * 1 + this.ChartSymbolTradeUnits()*this.ChartMarketPrice()/this.AccountLeverage() * this.AccountStopoutLevel() / 100)

        return parseFloat(lot.toFixed(2));
    }

    public DetermineLossAtStopout(position:string, lot: number): number|string {
        
        /*double margin =  AccountMargin();
        double stopout_margin = margin * AccountStopoutLevel() / 100;    
        double stopout_loss = AccountBalance() + AccountCredit() + OrderCommission() + OrderSwap() - stopout_margin;   
        double stopout_pip_move = ammountToPips(stopout_loss, OrderLots(), OrderSymbol());*/

        var margin = this.CalculateMarginRequire(lot);
        var stopout_margin = margin * this.AccountStopoutLevel() / 100;
        var stopout_loss = this.AccountBalance() + this.AccountCredit() + this.CalculateCommision(lot) - stopout_margin;   

        return parseFloat(stopout_loss.toFixed(2));
    }


    public DeterminePipsMoveAtStopout(position:string, lot: number): number|string {
        
        var stopout_loss: any = this.DetermineLossAtStopout(position, lot);

        if(isNaN(stopout_loss)){
            return stopout_loss;
        }
        var stoput_pip_move = this.AmmountToPips(stopout_loss, lot);

        return parseFloat(stoput_pip_move.toFixed(2));
    }
    
    public sendEACommand(commmand: string, prop: object = {}, callback: Function = null){
        var command_id:string = SyncUtil.Unique();
        var cmdObj = {
            name : commmand,
            callback: callback
        }
        if(callback!== null){
            this.EACommandList.set(command_id, cmdObj);
        }
        
        this.SendData(SyncUtil.CommandPacket(cmdObj.name, command_id, prop));
    }

    /**
     *This method will be used to position each peer in the appropriate column when pairing for consistent access location  
     */
    public PairColumnIndex(): number {
        if (this.peer == null) {
            throw new SyncTraderException("Peer cannot be null");
        }
        if (this.StrID() == this.peer.StrID()) {
            throw new SyncTraderException("Compared TraderAccount cannot be the same as peer!");
        }
        return this.StrID() < this.peer.StrID() ? 0 : 1;
    }

    public CreateAndAtachSyncStatePairID(){

        if(!this.Peer()){
            return;
        }

        if(this.open_tickets.length !== this.Peer().open_tickets.length){
            return;
        }

        var peer_open_tickets = this.Peer().open_tickets;

        var own_tickets = "";
        var peer_tickets = "";

        for(var i=0; i < this.open_tickets.length; i++){
            own_tickets += this.SEP + this.open_tickets[i];
            peer_tickets += this.SEP + peer_open_tickets[i];
        }

        var state_pair_id = this.PairColumnIndex() === 0 
                        ? this.StrID() + this.SEP + this.peer.StrID()  + this.SEP + own_tickets + this.SEP + peer_tickets
                        : this.peer.StrID() + this.SEP + this.StrID() + this.SEP + peer_tickets+ this.SEP + own_tickets;  
                        
         //send to both peers               
         this.SendData(SyncUtil.SyncStatePairIDPacket(state_pair_id));
         this.Peer().SendData(SyncUtil.SyncStatePairIDPacket(state_pair_id));
    }

    public SendPeerSymbolDigits(){
        if(!this.Peer()){
            return;
        }

        this.SendData(SyncUtil.SymbolDigitsPacket(this.Peer().ChartSymbolDigits()));
    }
    
    public DetachSyncStatePairID(){
         this.SendData(SyncUtil.SyncStatePairIDPacket(""));
    }

    

    /**
     * Generate an id that uniquely identifies the pair
     */
    public PairID(): string {
        if (this.peer == null) {
            throw new SyncTraderException("Peer cannot be null");
        }
        if (this.StrID() == this.peer.StrID()) {
            throw new SyncTraderException("Compared TraderAccount cannot be the same as peer!");
        }
        return this.PairColumnIndex() === 0 ? this.StrID() + this.SEP + this.peer.StrID() : this.peer.StrID() + this.SEP + this.StrID();
    }

    public StrID(): string {
        return this.broker + this.SEP + this.account_number;
    }

    public SendGetIntro() {
        this.SendData(SyncUtil.Intro());
    }

    public PlaceOrder(placement: OrderPlacement) {
        this.SendData(SyncUtil.SyncPlackeOrderPacket(placement, this.broker, this.account_number));

        ipcSend('sending-place-order', {
            account: this.CopyAttr()
        });
    }

    ValidatePlaceOrder(symbol: string, lot_size: number, max_percent_diff_in_account_balances: number = Infinity, is_triggered: boolean= false): boolean {

        var valid = false;    

        var perecent = 0;   
        
        if (
            max_percent_diff_in_account_balances >= 0 &&
            this.AccountBalance() > 0 &&
            this.Peer().AccountBalance() > 0
        ) {
            perecent = Math.abs(
            ((this.AccountBalance() - this.Peer().AccountBalance()) /
                this.AccountBalance()) *
                100
            );
        }
  
        var err_prefix = is_triggered? "Trigger validation error!\n" : "";

        if(!this.TerminalConnected()){
            this.SetLastError(`${err_prefix}Terminal is disconnected!`);
        }else if(this.AccountBalance() <= 0){
            this.SetLastError(`${err_prefix}Not allowed! Account balance must be greater than zero.`);
        }else if(this.OnlyTradeWithCredit() && this.IsLiveAccount() && this.AccountCredit() == 0){
            this.SetLastError(`${err_prefix}Not allowed for live account! Credit cannot be zero.`);
        }else if(lot_size > this.ChartSymbolMaxLotSize()){
            this.SetLastError(`${err_prefix}Maximum lot size of ${this.ChartSymbolMaxLotSize()} exceeded! The specified lot size of ${lot_size} is too big.`);
        }else if(lot_size < this.ChartSymbolMinLotSize()){
            this.SetLastError(`${err_prefix}Cannot be below mininiun lot size of ${this.ChartSymbolMinLotSize()}. The specified lot size of ${lot_size} is too small.`);
        }else if(this.IsMarketClosed()){
            this.SetLastError(`${err_prefix}Market is closed!`);
        }else if(!this.ChartSymbolTradeAllowed()){
            this.SetLastError(`${err_prefix}Trade not allowed for ${this.ChartSymbol()}. Check if symbol is disabled or market is closed.`);
        }else if(this.ChartSymbol() !== SyncUtil.GetRelativeSymbol(symbol, this.Broker(), this.AccountNumber())){
            this.SetLastError(`${err_prefix}Not allowed! Chart symbol must be same as trade symbol. Symbol on chart is ${this.ChartSymbol()} while trade is ${symbol}`);
        }else if(perecent > max_percent_diff_in_account_balances){
            this.SetLastError(`${err_prefix}Percent difference in account balance, ${this
                .AccountBalance()
                .toFixed(
                  2
                )}${this.AccountCurrency()} of [${this.Broker()} , ${this.AccountNumber()}]  from that of ${this.Peer()
                .AccountBalance()
                .toFixed(
                  2
                )}${this.Peer().AccountCurrency()} of [${this.Peer().Broker()} , ${this.Peer().AccountNumber()}] which is ${perecent.toFixed(
                2
              )}% is greater than the allowable maximum of ${max_percent_diff_in_account_balances}%`);
        }else{
            valid = true;
        }    
 
        if(!valid){
            ipcSend("validate-place-order-fail", this.CopyAttr());            
        }

        return valid;
    }
    
    private IsModificationInProgress(own_order: Order, peer_order: Order){
        return own_order.IsSyncModifyingTarget()
                || own_order.IsSyncModifyingStoploss()
                || peer_order.IsSyncModifyingTarget()
                || peer_order.IsSyncModifyingStoploss()

    }

    private IsAllGroupOrdersOpenAndNotClosing(own_order: Order, peer_order: Order): boolean{

        var orders = this.Orders();
        var own_group_order_open_count = 0;

        for (let order of orders) {
            if(order.GropuId()
                && order.GropuId() === own_order.GropuId() 
                && order.IsOpen() //order must be open
                && !order.IsClosing() //order must not be in closing state
                ){
                    own_group_order_open_count++;
                }

        }

        if(!this.Peer()) return false;

        var peer_orders = this.Peer().Orders();
        var peer_group_order_open_count = 0;

        for (let order of peer_orders) {

            if(order.GropuId() 
                && order.GropuId() === peer_order.GropuId() 
                && order.IsOpen() //order must be open
                && !order.IsClosing() //order must not be in closing state
                ){
                    peer_group_order_open_count++;
                }

        }

        return own_group_order_open_count === own_order.GroupOrderCount() 
                    && peer_group_order_open_count === peer_order.GroupOrderCount();
    }

    public RetrySendPlaceOrderOrForceClosePeer(placement: OrderPlacement) {
        var attempts = this.PlaceOrderRetryAttempt.get(placement.id);
        if (!attempts) {
            attempts = 0;
        }

        attempts++;

        if (attempts > Constants.MAX_PLACE_ORDER_RETRY) {
            placement.SetOperationCompleteStatus(OrderPlacement.COMPLETE_FAIL);
            var peer_placement: OrderPlacement = this.Peer().SyncPlacingOrders.get(placement.paired_uuid);
            if (peer_placement) {
                var peer_ticket: number = peer_placement.ticket;
                var reason: string = this.ForceCloseReasonForFailedOrderPlacement(peer_ticket);
                this.Peer().ForceCloseMe(peer_ticket, reason);//forcibly close the peer order
            }
            return;
        }

        this.PlaceOrderRetryAttempt.set(placement.id, attempts);

        this.PlaceOrder(placement);

        SyncUtil.LogPlaceOrderRetry(this, placement.id, attempts);
    }

    private DoSendCopy(order: Order) {

        //mark as copying to avoid duplicate copies
        order.SyncCopying(true);
        this.peer.SendData(
            SyncUtil.SyncCopyPacket(order, 
                    this.peer.trade_copy_type,
                    this.peer.broker, 
                    this.peer.account_number, 
                    this.broker, 
                    this.account_number)
                 );

        ipcSend('sending-sync-copy', {
            account: this.CopyAttr(),
            order: order
        });
    }

    public KnowMyPeer(){
        this.SendData(SyncUtil.KnowMyPeerPacket(this.peer?.broker, this.peer?.account_number));
    }

    public RegisterPeerTicket(peer_ticket: number){        
        this.peer?.SendData(SyncUtil.RegisterPeerTicketPacket(peer_ticket, this.broker, this.account_number));
    }

    public ClosePeerByTicket(peer_ticket: number){        
        this.peer?.SendData(SyncUtil.CloseByTicketPacket(peer_ticket));
    }

    public NotifyPeerOpenPosition(peer_ticket: number, peer_total_orders_open: number){                   
        this.peer?.SendData(SyncUtil.NotifyPeerOpenPositionPacket(peer_ticket, peer_total_orders_open, this.broker, this.account_number));        
    }    

    private DoSendClose(own_order: Order, peer_order: Order) {

        //mark as sync closing to avoid duplicate operation
        own_order.Closing(true);
        var true_point: number = this.TrueSymbolPointForSpread();

        var spread_point: number = SyncUtil.SymbolSafetySpreadPiont(this.peer.Broker(),
                                                        this.peer.AccountNumber(), 
                                                        peer_order.raw_symbol, 
                                                        true_point);

        this.peer.SendData(SyncUtil.SyncClosePacket(peer_order.ticket, own_order.ticket, spread_point));

        ipcSend('sending-sync-close', {
            account: this.CopyAttr(),
            order: own_order,
            peer_order: peer_order
        });
    }

    private DoSendOwnClose(order: Order, force: boolean = false, reason: string='') {

        //mark as closing to avoid duplicate operation
        order.Closing(true);
        var true_point: number = this.TrueSymbolPointForSpread();
        
        var spread_point: number = SyncUtil.SymbolSafetySpreadPiont(this.Broker(),
                                                        this.AccountNumber(), 
                                                        order.raw_symbol,
                                                        true_point);

        this.SendData(SyncUtil.OwnClosePacket(order.ticket, spread_point, force, reason));

        ipcSend('sending-own-close', {
            account: this.CopyAttr(),
            order: order,
            force: force,
            reason:reason
        });
    }

    public IsRequestingTakeProfitParam(): boolean{return this.is_requesting_take_profit_param}

    public IsModifyingTakeProfit(): boolean{return this.is_modifying_take_profit}

    public SetRequestingTakeProfitParam(b:boolean){
        this.is_requesting_take_profit_param = b;
    }
    
    public SetModifyingTakeProfit(b:boolean){
        this.is_modifying_take_profit = b;
    }

    private RequestTakeProfitParam(){
        this.SetRequestingTakeProfitParam(true);
        this.peer.SendData(SyncUtil.RequestingTakeProfitParam());
    }

    private DoSendModifyTarget(own_order: Order, peer_order: Order, new_target: number) {

        //mark as sync modifying target to avoid duplicate operation
        own_order.SyncModifyingTarget(true);

        this.peer.SendData(SyncUtil.SyncModifyTargetPacket(new_target, peer_order.ticket, own_order.ticket));

        ipcSend('sending-modify-target', {
            account: this.CopyAttr(),
            order: own_order,
            peer_order: peer_order
        });
    }

    public ForceCloseReasonForFailedSyncCopy(ticket: number) {
        return `Forcibly closed order #${ticket} because sync copy failed after maximum retry attempts of ${Constants.MAX_COPY_RETRY}.`;
    }

    public ForceCloseReasonForFailedOrderPlacement(ticket: number) {
        return `Forcibly closed order #${ticket} because sync order placement failed after maximum retry attempts of ${Constants.MAX_PLACE_ORDER_RETRY}.`;
    }

    public DefaultForceCloseReason(ticket: number) {
        return `Forcibly closed order #${ticket} because possibly sync copy or order placement failed`;
    }

    public ForceCloseMe(ticket: number, reason: string = this.DefaultForceCloseReason(ticket)) {       
        let order: Order = this.orders.get(ticket);
        if (order) {
            this.DoSendOwnClose(order, true, reason);
        }
    }

    public CloseAllTrades(event: string = null, comment: string = null) {

        var atleastOne = false;

        this.orders.forEach((order: Order, ticket: number) => {
            if (order.IsClosed() || order.IsClosing()) {
                return;
            }

            atleastOne = true;

            this.DoSendOwnClose(order);
        })

        if (this.peer) {
            this.peer.orders.forEach((order: Order, ticket: number) => {
                if (order.IsClosed() || order.IsClosing()) {
                    return;
                }

                atleastOne = true;

                this.DoSendOwnClose(order);
            })

        }
        
        if (atleastOne && event) {
            ipcSend(event, comment);
        }
        
    }

    public SendTradeProperties(config){
        if(!config){
            return;
        }
        var prop  = config[this.Broker()]?.(this.AccountNumber()+"");
        prop = prop || config;

        this.SendData(SyncUtil.TradePropertiesPacket(prop));        
    }

    public SendPeerSetTakeProfit(){
        if(!this.peer){
            return;
        }
        
        this.peer.SetRequestingTakeProfitParam(false);
        this.peer.SetModifyingTakeProfit(true);

        this.peer.SendData(SyncUtil.SetTakeProfit(this));  
    }

    /**
     * Send copy to peer
     */
    public SendCopy(unsynced_orders: Array<Order>) {
        for (let order of unsynced_orders) {

            //skip for those that are already closed or copying is in progress
            if (!order.IsCopyable() || order.IsClosed() || order.IsSyncCopying())
                continue;

            //at this point check manual entry order
            //we know that orders without group id were enter manual
            if(!order.GropuId()){
                //in this block we will block orders whose sync copy for manual entry is disabled
                if(!this.SyncCopyManualEntry() 
                    || !this.Peer().SyncCopyManualEntry()){
                        //skip since at least one of the pairing EAs disabled sync copy for manual entry
                    continue;
                }

            }    

            this.DoSendCopy(order);
        }
    }    

    public RetrySendCopyOrForceCloseMe(origin_ticket: number) {
        var attempts = this.CopyRetryAttempt.get(origin_ticket); 
        if (!attempts) {
            attempts = 0;
        }

        attempts++;

        if (attempts > Constants.MAX_COPY_RETRY) {
            var reason: string = this.ForceCloseReasonForFailedSyncCopy(origin_ticket);
            this.ForceCloseMe(origin_ticket, reason);//forcely close the order
            return;
        }

        this.CopyRetryAttempt.set(origin_ticket , attempts);

        let order: Order = this.orders.get(origin_ticket);
        this.DoSendCopy(order);

        SyncUtil.LogCopyRetry(this, origin_ticket, attempts);
    }

    public SendClose(synced_orders: Array<PairOrder>) {

        for (let paired of synced_orders) {
            let own_column: number = this.PairColumnIndex();
            let peer_column: number = this.peer.PairColumnIndex();
            var own_order = paired[own_column];
            var peer_order = paired[peer_column];
            //skip for those that are still open or sync closing is in progress
            if (!own_order.IsClosed() || own_order.IsClosing() || own_order.IsLockInProfit())
                continue;

            this.DoSendClose(own_order, peer_order);
        }
    }

    public SendCloseToGroup(ticket: number): boolean{
        let orderObj: Order = this.orders.get(ticket);
        var orders = this.Orders();
        var found:boolean = false;
        for (var order of orders) {
            if(orderObj.IsClosed()
                 && orderObj.GropuId() === order.GropuId()
                 && !order.IsClosed() 
                 && !order.IsClosing()
                 && !order.IsLockInProfit()){                
                this.DoSendOwnClose(order); 
                found = true       
            }
        }
        return found;
    }

    public RetrySendOwnClose(ticket: number) {

        var attempts = this.CloseRetryAttempt.get(ticket);
        if (!attempts) {
            attempts = 0;
        }

        if (attempts > Constants.MAX_CLOSE_RETRY)
            return;

        this.CloseRetryAttempt.set(ticket, attempts);

        let order: Order = this.orders.get(ticket);
        this.DoSendOwnClose(order);

        SyncUtil.LogOwnCloseRetry(this, ticket, attempts);
    }

    public RetrySendClose(origin_ticket: number, peer_ticket: number) {

        var attempts = this.CloseRetryAttempt.get(origin_ticket);
        if (!attempts) {
            attempts = 0;
        }

        if (attempts > Constants.MAX_CLOSE_RETRY)
            return;

        this.CloseRetryAttempt.set(origin_ticket, attempts);

        let order: Order = this.orders.get(origin_ticket);
        let peer_order: Order = this.Peer().orders.get(peer_ticket);
        this.DoSendClose(order, peer_order);

        SyncUtil.LogCloseRetry(this, origin_ticket, peer_ticket, attempts);
    }
    
    VirtualSync(own_ticket: number, bitOrderPairs: Map<string, PairBitOrder[]>) {


        if (!this.peer) {
            return;
        }
        
        var paired_bit_orders = bitOrderPairs.get(this.PairID());
        if (!paired_bit_orders) {
            return;
        }

        for (var pair_ticket of paired_bit_orders) {
            
            var own_bit_order: BitOrder = pair_ticket[this.PairColumnIndex()];//modified111

            if(own_bit_order.ticket !== own_ticket){
                continue
            }

            var own_order = this.orders.get(own_bit_order.ticket);

            var peer_bit_order: BitOrder = pair_ticket[this.peer.PairColumnIndex()];
            var peer_order = this.peer.orders.get(peer_bit_order.ticket);

            var own_spread_point =  this.ChartSymbolSpread() * this.TrueSymbolPointForSpread();
                
            this.peer.SendData(
                SyncUtil.VirtualSyncPacket(
                        peer_order.ticket,
                        own_order.ticket,
                        own_order.stoploss,
                        own_spread_point
                    ));
        }
        
    }
       
    private DeterminePeerTarget(own_order: Order, peer_order: Order): number{
                        
         //get the absolute distance in points
        //between the own order stoploss and PEER order open price
        var pip_piont = Math.abs(own_order.stoploss - peer_order.open_price);
                    
        //negate the value since the target is below open in SELL position
        if(peer_order.position == 'SELL'){
            pip_piont = -pip_piont;
        }
        
        var tg_safety_srpread = SyncUtil.SymbolSafetySpreadPiont(this.peer.Broker(),
                                                this.peer.AccountNumber(), 
                                                peer_order.raw_symbol, 
                                                this.TrueSymbolPointForSpread());

        peer_order.SetSafetySpreadInUse(tg_safety_srpread);                                                

        if(peer_order.position == "BUY"){
            tg_safety_srpread = -tg_safety_srpread;
        }

        var peer_target_price = peer_order.open_price + pip_piont + tg_safety_srpread;

        return peer_target_price
    }
    
    public ApplySafetySpreadConfig(){
        var orders:  Order[] = this.Orders();
        for(let order of orders){
            var true_point: number = this.TrueSymbolPointForSpread();
            var safety_spread = SyncUtil.SymbolSafetySpreadPiont(this.Broker(), this.AccountNumber(), order.raw_symbol, true_point);
                        
            if(safety_spread != order.SafetySpreadInUse()){
                order.SetSafetySpreadApplied(false); //trigger the modified saftety spread to be applied
            }

        }                
    }
    
    public EnsureTakeProfitIsSet(synced_orders: Array<PairOrder>, when_no_target: boolean = false) {

        //First ensure both paired accounts have the same number
        //of open orders
        if(!this.Peer() 
            || this.TotalOpenOrders() != this.Peer().TotalOpenOrders()){
            return;
        }

        

        var is_all_group_orders_open: boolean = false;
        for (let paired of synced_orders) {
            let own_column: number = this.PairColumnIndex();
            let peer_column: number = this.peer.PairColumnIndex();
            var own_order = paired[own_column];
            var peer_order = paired[peer_column];

            if (own_order.IsClosed() || peer_order.IsClosed()) {
                continue;
            }


            //Well before we  send modification we should ensure all the group orders
            //are open and not in closing state. We don't what the stoploss and target
            //to be modified when orders are being closed, it is pointless
            if(!is_all_group_orders_open){
                is_all_group_orders_open = this.IsAllGroupOrdersOpenAndNotClosing(own_order, peer_order);
                if(!is_all_group_orders_open){
                    return;//wait till all group orders are open
                }
            }

            if((when_no_target && own_order.target == 0) 
                || !when_no_target){
                 
                if(!this.IsModifyingTakeProfit()
                    && !this.IsRequestingTakeProfitParam())   {
                        this.RequestTakeProfitParam();       
                } 

            }


        }

    }
    
    public SendModify(synced_orders: Array<PairOrder>) {

        var is_all_group_orders_open: boolean = false;
        for (let paired of synced_orders) {
            let own_column: number = this.PairColumnIndex();
            let peer_column: number = this.peer.PairColumnIndex();
            var own_order = paired[own_column];
            var peer_order = paired[peer_column];

            if (own_order.IsClosed() || peer_order.IsClosed()) {
                continue;
            }
            
            //Well before we  send modification we should ensure all the group orders
            //are open and not in closing state. We don't what the stoploss and target
            //to be modified when orders are being closed, it is pointless
            if(!is_all_group_orders_open){
                is_all_group_orders_open = this.IsAllGroupOrdersOpenAndNotClosing(own_order, peer_order);
                if(!is_all_group_orders_open){
                    return;//wait till all group orders are open
                }
            }


            //normalize relevant price variables

            SyncUtil.NormalizePrice(own_order);
            SyncUtil.NormalizePrice(peer_order);
            

            if( (own_order.stoploss != 0 && peer_order.target == 0)
                    || own_order.IsStoplossChanged() 
                    || !peer_order.IsSafetySpreadApplied() ){
                
                SyncUtil.AsyncWaitWhile(()=>{
                    var new_target: number = this.DeterminePeerTarget(own_order, peer_order);

                    //making sure the new target is different before we modify
                    if(new_target != peer_order.target){
                        this.DoSendModifyTarget(own_order, peer_order, new_target);//modify peer target be equal to own stoploss
                    }
                    
                    own_order.SetStoplossChanged(false);
                    peer_order.SetSafetySpreadApplied(true);

                }, () => this.IsModificationInProgress(own_order, peer_order))

                /*if (!this.IsModificationInProgress(own_order, peer_order)) { //there must be no modification in progerss - whether targe or stoploss
                    var new_target: number = this.DeterminePeerTarget(own_order, peer_order, signed_srpread);
                    this.DoSendModifyTarget(own_order, peer_order, new_target);//modify peer target be equal to own stoploss
                }*/
            }            

            
        }
    }

    public RetrySendModifyTarget(origin_ticket: number, peer_ticket: number, new_target: number) {

        var attempts = this.ModifyTargetRetryAttempt.get(origin_ticket);
        if (!attempts) {
            attempts = 0;
        }

        if (attempts > Constants.MAX_MODIFY_RETRY)
            return;

        attempts++;    

        this.ModifyTargetRetryAttempt.set(origin_ticket, attempts);

        let order: Order = this.orders.get(origin_ticket);
        let peer_order: Order = this.Peer().orders.get(peer_ticket);
        this.DoSendModifyTarget(order, peer_order, new_target);

        SyncUtil.LogModifyTargetRetry(this, origin_ticket, peer_ticket, attempts);
    }           

}
