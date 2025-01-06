"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TraderAccount = void 0;
const main_1 = require("./main");
const Order_1 = require("./Order");
const SyncUtil_1 = require("./SyncUtil");
const Constants_1 = require("./Constants");
const OrderPlacement_1 = require("./OrderPlacement");
const SyncTraderException_1 = require("./SyncTraderException");
const MessageBuffer_1 = require("./MessageBuffer");
const Logger_1 = require("./Logger");
class TraderAccount {
    constructor(socket) {
        this.sync_copy_manual_entry = false;
        this.sync_state_pair_id = "";
        this.open_tickets = [];
        this.chart_symbol_max_lot_size = 0;
        this.chart_symbol_min_lot_size = 0;
        this.chart_symbol_tick_value = 0;
        this.chart_symbol_tick_size = 0;
        this.chart_symbol_swap_long = 0;
        this.chart_symbol_swap_short = 0;
        this.chart_symbol_trade_units = 0;
        this.chart_symbol_spread = 0;
        this.account_balance = 0;
        this.account_equity = 0;
        this.account_credit = 0;
        this.account_currency = "";
        this.account_leverage = 0;
        this.account_margin = 0;
        this.account_stopout_level = 0;
        this.account_profit = 0;
        this.account_free_margin = 0;
        this.account_swap_per_day = 0;
        this.account_trade_cost = 0;
        this.account_swap_cost = 0;
        this.account_commission_cost = 0;
        this.expected_exit_profit = 0;
        this.expected_target_profit = 0;
        this.expected_exit_balance = 0;
        this.expected_target_balance = 0;
        this.total_commission = 0;
        this.total_swap = 0;
        this.total_lot_size = 0;
        this.total_open_orders = 0;
        this.contract_size = 0;
        this.base_open_price = 0;
        this.position = "";
        this.chart_market_price = 0; //this is the current market price on the chart where the EA is loaded
        this.exchange_rate_for_margin_requirement = 0;
        this.hedge_profit = 0;
        this.ea_executable_file = '';
        this.is_requesting_take_profit_param = false;
        this.is_modifying_take_profit = false;
        this.ea_up_to_date = null; //unknown
        this.orders = new Map();
        this.CopyRetryAttempt = new Map();
        this.CloseRetryAttempt = new Map();
        this.ModifyTargetRetryAttempt = new Map();
        this.PlaceOrderRetryAttempt = new Map();
        this.message = new MessageBuffer_1.MessageBuffer(Constants_1.Constants.NEW_LINE);
        this.last_error = "";
        this.peer = null;
        this.lastPeerBroker = "";
        this.lastPeerAccountNumber = "";
        this.SEP = "_";
        this.MODIFY_TARGET = 1;
        this.MODIFY_STOPLOSS = 2;
        this.SyncPlacingOrders = new Map();
        this.EACommandList = new Map();
        this.test = 0;
        this.test = 7;
        this.socket = socket;
        this.IsSockConnected = true;
        socket.on('data', this.OnSocketData.bind(this));
        socket.on('end', this.OnSocketEnd.bind(this));
        socket.on('close', this.OnSocketClose.bind(this));
        socket.on('error', this.OnSocketError.bind(this));
    }
    Close() {
        this.socket.destroy();
    }
    /**
     *Create a uncircular object of itself so that we don't get circular reference error
     * when serializing e.g in ipc transmission
     **/
    CopyAttr() {
        var column_index = this.peer != null ? this.PairColumnIndex() : -1;
        var pair_id = this.peer != null ? this.PairID() : '';
        var peer_column_index = -1;
        if (column_index == 1) {
            peer_column_index = 0;
        }
        else if (column_index == 0) {
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
            terminal_connected: this.terminal_connected,
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
            ea_executable_file: this.ea_executable_file,
            is_live_account: this.is_live_account,
            ea_up_to_date: this.ea_up_to_date,
            trade_copy_type: this.trade_copy_type,
            orders: this.Orders(),
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
                terminal_connected: this.peer.terminal_connected,
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
                ea_executable_file: this.peer.ea_executable_file,
                is_live_account: this.peer.is_live_account,
                ea_up_to_date: this.peer.ea_up_to_date,
                trade_copy_type: this.peer.trade_copy_type,
                orders: this.peer.Orders(),
                column_index: peer_column_index,
                pair_id: peer_pair_id,
                last_error: this.peer.last_error,
            }
        };
    }
    Peer() { return this.peer; }
    ;
    RemovePeer() {
        if (!this.peer)
            return;
        this.SendData(SyncUtil_1.SyncUtil.UnpairedNotificationPacket(this.peer.broker, this.peer.account_number));
        return this.peer = null;
    }
    ;
    LastPeerBroker() {
        return this.lastPeerBroker;
    }
    LastPeerAccountNumber() {
        return this.lastPeerAccountNumber;
    }
    Version() { return this.version; }
    ;
    SetIntroTime() {
        if (!this.intro_time) {
            this.intro_time = Date.now();
        }
    }
    GetIntroTime() { return this.intro_time; }
    Broker() { return this.broker; }
    ;
    AccountNumber() { return this.account_number; }
    ;
    AccountName() { return this.account_name; }
    ;
    AccountBalance() { return this.account_balance; }
    ;
    AccountEquity() { return this.account_equity; }
    ;
    AccountCredit() { return this.account_credit; }
    ;
    AccountCurrency() { return this.account_currency; }
    ;
    AccountMargin() { return this.account_margin; }
    ;
    AccountFreeMargin() { return this.account_free_margin; }
    ;
    AccountLeverage() { return this.account_leverage; }
    ;
    AccountStopoutLevel() { return this.account_stopout_level; }
    ;
    AccountProfit() { return this.account_profit; }
    ;
    AccountSwapPerDay() { return this.account_swap_per_day; }
    ;
    AccountTradeCost() { return this.account_trade_cost; }
    ;
    AccountSwapCost() { return this.account_swap_cost; }
    ;
    AccountCommissionCost() { return this.account_commission_cost; }
    ;
    HedgeProfit() { return this.hedge_profit; }
    ;
    TotalCommission() { return this.total_commission; }
    ;
    TotalSwap() { return this.total_swap; }
    ;
    TotalLotSize() { return this.total_lot_size; }
    ;
    TotalOpenOrders() { return this.total_open_orders; }
    ;
    ContractSize() { return this.contract_size; }
    ;
    BaseOpenPrice() { return this.base_open_price; }
    ;
    Position() { return this.position; }
    ;
    TerminalConnected() { return this.terminal_connected; }
    ;
    OnlyTradeWithCredit() { return this.only_trade_with_credit; }
    ;
    ChartSymbol() { return this.chart_symbol; }
    ;
    ChartSymbolDigits() { return this.chart_symbol_digits; }
    ;
    ChartSymbolTradeAllowed() { return this.chart_symbol_trade_allowed; }
    ;
    ChartSymbolMaxLotSize() { return this.chart_symbol_max_lot_size; }
    ;
    ChartSymbolMinLotSize() { return this.chart_symbol_min_lot_size; }
    ;
    ChartSymbolTickValue() { return this.chart_symbol_tick_value; }
    ;
    ChartSymbolTickSize() { return this.chart_symbol_tick_size; }
    ;
    ChartSymbolSwapLong() { return this.chart_symbol_swap_long; }
    ;
    ChartSymbolSwapShort() { return this.chart_symbol_swap_short; }
    ;
    ChartSymbolTradeUnits() { return this.chart_symbol_trade_units; }
    ;
    ChartSymbolSpread() { return this.chart_symbol_spread; }
    ;
    ChartMarketPrice() { return this.chart_market_price; }
    ;
    ExchangeRateForMarginRequirement() { return this.exchange_rate_for_margin_requirement; }
    ;
    PlatformType() { return this.platform_type; }
    ;
    SyncCopyManualEntry() { return this.sync_copy_manual_entry; }
    ;
    IconFile() { return this.icon_file; }
    ;
    EAExecutableFile() { return this.ea_executable_file; }
    ;
    IsMT4() {
        return this.ea_executable_file.endsWith('.ex4');
    }
    IsMT5() {
        return this.ea_executable_file.endsWith('.ex5');
    }
    IsMarketClosed() { return this.is_market_closed; }
    ;
    IsLiveAccount() { return this.is_live_account; }
    ;
    IsEAUpToDate() { return this.ea_up_to_date; }
    ;
    GetLastError() { return this.last_error; }
    ;
    SyncStatePairID() { return this.sync_state_pair_id; }
    TradeCopyType() { return this.trade_copy_type; }
    ;
    Dispose() { this.socket = null; }
    OnSocketData(data) {
        this.message.push(data);
    }
    OnSocketEnd() {
        this.IsSockConnected = false;
        main_1.ipcSend('account-disconnect', this.CopyAttr());
    }
    OnSocketError() {
        this.IsSockConnected = false;
        main_1.ipcSend('account-disconnect', this.CopyAttr());
    }
    OnSocketClose() {
        this.IsSockConnected = false;
        main_1.ipcSend('account-disconnect', this.CopyAttr());
    }
    IsPlacementOrderClosed(uuid) {
        var placement = this.SyncPlacingOrders.get(uuid);
        if (!placement) {
            return true; //meaning we have deleted it
        }
        if (placement.ticket == -1) {
            return false; //most likely the order placement is inprogress
        }
        var order = this.GetOrder(placement.ticket);
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
    ResetOrdersSyncing() {
        var orders = this.Orders();
        for (var order of orders) {
            order.SyncCopying(false);
            order.Closing(false);
            order.SyncModifyingStoploss(false);
            order.SyncModifyingTarget(false);
        }
    }
    IsSyncingInProgress() {
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
    SendData(data) {
        if (!data.endsWith(Constants_1.Constants.NEW_LINE)) {
            data += Constants_1.Constants.NEW_LINE;
        }
        try {
            this.socket.write(Buffer.from(data));
        }
        catch (e) {
            Logger_1.default.error(e.message);
            console.log(e);
        }
    }
    HasReceived() {
        return !this.message.isFinished();
    }
    ReceiveData() {
        return this.message.getMessage();
    }
    SetVersion(version) {
        this.version = version;
    }
    SetBroker(broker) {
        this.broker = broker;
    }
    SetIconFile(icon_file) {
        this.icon_file = icon_file;
    }
    SetAccountNumber(account_number) {
        this.account_number = account_number;
    }
    SetAccountName(account_name) {
        this.account_name = account_name;
    }
    SetAccountBalance(account_balance) {
        this.account_balance = account_balance;
    }
    SetAccountEquity(account_equity) {
        this.account_equity = account_equity;
    }
    SetAccountCredit(account_credit) {
        this.account_credit = account_credit;
    }
    SetAccountCurrency(account_currency) {
        this.account_currency = account_currency;
    }
    SetAccountLeverage(account_leverage) {
        this.account_leverage = account_leverage;
    }
    SetAccountMargin(account_margin) {
        this.account_margin = account_margin;
    }
    SetAccountStopoutLevel(account_stopout_level) {
        this.account_stopout_level = account_stopout_level;
    }
    SetAccountProfit(account_profit) {
        this.account_profit = account_profit;
    }
    SetAccountFreeMargin(account_free_margin) {
        this.account_free_margin = account_free_margin;
    }
    SetAccountSwapPerDay(account_swap_per_day) {
        this.account_swap_per_day = account_swap_per_day;
    }
    SetAccountTradeCost(account_trade_cost) {
        this.account_trade_cost = account_trade_cost;
    }
    SetAccountSwapCost(account_swap_cost) {
        this.account_swap_cost = account_swap_cost;
    }
    SetAccountCommissionCost(account_commission_cost) {
        this.account_commission_cost = account_commission_cost;
    }
    SetHedgeProfit(hedge_profit) {
        this.hedge_profit = hedge_profit;
    }
    GetCommissionPerLot(symbol) {
        var commsionConfig = SyncUtil_1.SyncUtil.AppConfigMap.get('brokers_commission_per_lot');
        if (!commsionConfig
            || !commsionConfig[this.broker]
            || !commsionConfig[this.broker][this.account_number]) {
            return "unknown";
        }
        var commission = commsionConfig[this.broker][this.account_number][symbol];
        if (commission === 0 || commission < 0 || commission > 0) {
            return commission;
        }
        return 'unknown';
    }
    SetSymbolCommissionPerLot(symbol, conmission_per_lot) {
        var saved_conmission_per_lot = this.GetCommissionPerLot(symbol);
        if (saved_conmission_per_lot === conmission_per_lot) {
            return;
        }
        var commsionConfig = SyncUtil_1.SyncUtil.AppConfigMap.get('brokers_commission_per_lot');
        if (!commsionConfig) {
            commsionConfig = {};
        }
        if (!commsionConfig[this.broker]) {
            commsionConfig[this.broker] = {};
        }
        if (!commsionConfig[this.broker][this.account_number]) {
            commsionConfig[this.broker][this.account_number] = {};
        }
        if (!commsionConfig[this.broker][this.account_number][symbol]) {
            commsionConfig[this.broker][this.account_number][symbol] = conmission_per_lot;
        }
        SyncUtil_1.SyncUtil.AppConfigMap.set('brokers_commission_per_lot', commsionConfig);
        var configObj = SyncUtil_1.SyncUtil.MapToObject(SyncUtil_1.SyncUtil.AppConfigMap);
        SyncUtil_1.SyncUtil.SaveAppConfig(configObj, function (success) {
            //TODO - report error if any
        });
    }
    SetTerminalConnected(terminal_connected) {
        this.terminal_connected = terminal_connected;
    }
    SetOnlyTradeWithCredit(only_trade_with_credit) {
        this.only_trade_with_credit = only_trade_with_credit;
    }
    SetChartSymbol(chart_symbol) {
        this.chart_symbol = chart_symbol;
    }
    SetChartSymbolDigits(chart_symbol_digits) {
        this.chart_symbol_digits = chart_symbol_digits;
    }
    SetChartSymbolTradeAllowed(chart_symbol_trade_allowed) {
        this.chart_symbol_trade_allowed = chart_symbol_trade_allowed;
    }
    SetChartSymbolMaxLotSize(chart_symbol_max_lot_size) {
        this.chart_symbol_max_lot_size = chart_symbol_max_lot_size;
    }
    SetChartSymbolMinLotSize(chart_symbol_min_lot_size) {
        this.chart_symbol_min_lot_size = chart_symbol_min_lot_size;
    }
    SetChartSymbolTickValue(chart_symbol_tick_value) {
        this.chart_symbol_tick_value = chart_symbol_tick_value;
    }
    SetChartSymbolTickSize(chart_symbol_tick_size) {
        this.chart_symbol_tick_size = chart_symbol_tick_size;
    }
    SetChartSymbolSwapLong(chart_symbol_swap_long) {
        this.chart_symbol_swap_long = chart_symbol_swap_long;
    }
    SetChartSymbolSwapShort(chart_symbol_swap_short) {
        this.chart_symbol_swap_short = chart_symbol_swap_short;
    }
    SetChartSymbolTradeUnits(chart_symbol_trade_units) {
        this.chart_symbol_trade_units = chart_symbol_trade_units;
    }
    SetChartSymbolSpread(chart_symbol_spread) {
        this.chart_symbol_spread = chart_symbol_spread;
    }
    SetChartMarketPrice(chart_market_price) {
        this.chart_market_price = chart_market_price;
    }
    SetExchangeRateForMarginRequirement(exchange_rate_for_margin_requirement) {
        this.exchange_rate_for_margin_requirement = exchange_rate_for_margin_requirement;
    }
    SetExpectedExitProfit(expected_exit_profit) {
        this.expected_exit_profit = expected_exit_profit;
    }
    SetExpectedTargetProfit(expected_target_profit) {
        this.expected_target_profit = expected_target_profit;
    }
    SetExpectedExitBalance(expected_exit_balance) {
        this.expected_exit_balance = expected_exit_balance;
    }
    SetExpectedTargetBalance(expected_target_balance) {
        this.expected_target_balance = expected_target_balance;
    }
    SetTotalCommission(total_commission) {
        this.total_commission = total_commission;
    }
    SetTotalSwap(total_swap) {
        this.total_swap = total_swap;
    }
    SetTotalLotSize(total_lot_size) {
        this.total_lot_size = total_lot_size;
    }
    SetTotalOpenOrder(total_open_orders) {
        this.total_open_orders = total_open_orders;
    }
    SetContractSize(contract_size) {
        this.contract_size = contract_size;
    }
    SetBaseOpenPrice(base_open_price) {
        this.base_open_price = base_open_price;
    }
    SetPosition(position) {
        this.position = position;
    }
    SetPlatformType(platform_type) {
        this.platform_type = platform_type;
    }
    SetSyncCopyManualEntry(sync_copy_manual_entry) {
        this.sync_copy_manual_entry = sync_copy_manual_entry;
    }
    SetEAExecutableFile(ea_executable_file) {
        this.ea_executable_file = ea_executable_file || '';
    }
    SetMarketClosed(is_market_closed) {
        this.is_market_closed = is_market_closed;
    }
    SetIsLiveAccount(is_live_account) {
        this.is_live_account = is_live_account;
    }
    SetEAUpToDate(ea_up_to_date) {
        this.ea_up_to_date = ea_up_to_date;
    }
    SetTradeCopyType(trade_copy_type) {
        this.trade_copy_type = trade_copy_type;
    }
    SetLastError(last_error) {
        this.last_error = last_error;
    }
    SetSyncStatePairID(sync_state_pair_id) {
        this.sync_state_pair_id = sync_state_pair_id;
    }
    SetOpenTickets(open_tickets) {
        this.open_tickets = open_tickets;
    }
    SetPeer(peer) {
        if (peer == null) {
            throw new SyncTraderException_1.SyncTraderException("Peer cannot be null");
        }
        if (this.StrID() === peer.StrID()) {
            throw new SyncTraderException_1.SyncTraderException("Compared TraderAccount cannot be the same as peer!");
        }
        this.peer = peer;
        this.lastPeerBroker = this.peer.Broker();
        this.lastPeerAccountNumber = this.peer.AccountNumber();
    }
    EnsureTicketPeer(bitOrderPairs) {
        if (!this.peer) {
            return;
        }
        var paired_bit_orders = bitOrderPairs.get(this.PairID());
        if (!paired_bit_orders) {
            return;
        }
        for (var pair_ticket of paired_bit_orders) {
            var own_bit_order = pair_ticket[this.PairColumnIndex()]; //modified111
            var own_order = this.orders.get(own_bit_order === null || own_bit_order === void 0 ? void 0 : own_bit_order.ticket); //modified111
            var peer_bit_order = pair_ticket[this.peer.PairColumnIndex()]; //modified111
            var peer_order = this.peer.orders.get(peer_bit_order === null || peer_bit_order === void 0 ? void 0 : peer_bit_order.ticket); //modified111
            if (own_order) {
                own_order.peer_ticket = peer_bit_order.ticket; //modified111
            }
            if (peer_order) {
                peer_order.peer_ticket = own_bit_order.ticket; //modified111
            }
        }
    }
    IsConnected() {
        return this.IsSockConnected;
    }
    Ping() {
        this.SendData(SyncUtil_1.SyncUtil.PingPacket());
    }
    IsKnown() {
        return this.broker !== null && this.broker.length > 0 && this.account_number !== null && this.account_number.length > 0;
    }
    SetOrder(bit_order) {
        if (bit_order && !this.orders.get(bit_order.ticket)) {
            this.orders.set(bit_order.ticket, new Order_1.Order(bit_order));
        }
    }
    GetOrder(ticket) {
        return this.orders.get(ticket);
    }
    Orders() {
        if (this.orders == null)
            return new Order_1.Order[0];
        var arr = Array.from(this.orders.values());
        return arr;
    }
    OpenOrdersCount() {
        var count = 0;
        this.orders.forEach(function (order, key, map) {
            if (order.close_time == 0) {
                count++;
            }
        });
        return count;
    }
    TrueSymbolPointForSpread() {
        var own_point = this.ChartSymbolTickSize() / this.ChartSymbolTickValue();
        if (this.peer == null) {
            return this.ChartSymbolTickSize();
        }
        var peer_point = this.peer.ChartSymbolTickSize() / this.peer.ChartSymbolTickValue();
        if (own_point == peer_point) { // it is expected to be the same
            return own_point;
        }
        return own_point; // this should not happen!
    }
    CalculateMarginRequire(lot) {
        return lot
            * this.ChartSymbolTradeUnits()
            * this.ExchangeRateForMarginRequirement()
            / this.AccountLeverage();
    }
    CalculateCommision(lot, symbol = this.chart_symbol) {
        var comm_per_lot = this.GetCommissionPerLot(symbol);
        return !isNaN(comm_per_lot) ? (comm_per_lot * lot) : 0;
    }
    IsCommisionKnown(symbol = this.chart_symbol) {
        var comm_per_lot = this.GetCommissionPerLot(symbol);
        return !isNaN(comm_per_lot);
    }
    CalculateSpreadCost(lot) {
        var cost = -Math.abs(this.ChartSymbolSpread() * lot); //must alway return negative
        return parseFloat(cost.toFixed(2)) * this.ChartSymbolTickValue();
    }
    CalculateSwapPerDay(position, lot) {
        var swap = 0;
        if (position == 'BUY') {
            swap = this.ChartSymbolSwapLong();
        }
        else if (position == 'SELL') {
            swap = this.ChartSymbolSwapShort();
        }
        var cost = swap * lot;
        return parseFloat(cost.toFixed(2)) * this.ChartSymbolTickValue();
    }
    AmmountToPips(amount, lots) {
        return amount / (lots);
    }
    DetermineLotSizefromPips(pips) {
        /*var lot: number  =
        (this.AccountBalance() + this.AccountCredit()) /
         (pips *  this.ChartSymbolTickValue() + this.ChartSymbolTradeUnits()*this.ChartMarketPrice()/this.AccountLeverage() * this.AccountStopoutLevel() / 100)
         */
        var lot = (this.AccountBalance() + this.AccountCredit()) /
            (pips * 1 + this.ChartSymbolTradeUnits() * this.ChartMarketPrice() / this.AccountLeverage() * this.AccountStopoutLevel() / 100);
        return parseFloat(lot.toFixed(2));
    }
    DetermineLossAtStopout(position, lot) {
        /*double margin =  AccountMargin();
        double stopout_margin = margin * AccountStopoutLevel() / 100;
        double stopout_loss = AccountBalance() + AccountCredit() + OrderCommission() + OrderSwap() - stopout_margin;
        double stopout_pip_move = ammountToPips(stopout_loss, OrderLots(), OrderSymbol());*/
        var margin = this.CalculateMarginRequire(lot);
        var stopout_margin = margin * this.AccountStopoutLevel() / 100;
        var stopout_loss = this.AccountBalance() + this.AccountCredit() + this.CalculateCommision(lot) - stopout_margin;
        return parseFloat(stopout_loss.toFixed(2));
    }
    DeterminePipsMoveAtStopout(position, lot) {
        var stopout_loss = this.DetermineLossAtStopout(position, lot);
        if (isNaN(stopout_loss)) {
            return stopout_loss;
        }
        var stoput_pip_move = this.AmmountToPips(stopout_loss, lot);
        return parseFloat(stoput_pip_move.toFixed(2));
    }
    sendEACommand(commmand, prop = {}, callback = null) {
        var command_id = SyncUtil_1.SyncUtil.Unique();
        var cmdObj = {
            name: commmand,
            callback: callback
        };
        if (callback !== null) {
            this.EACommandList.set(command_id, cmdObj);
        }
        this.SendData(SyncUtil_1.SyncUtil.CommandPacket(cmdObj.name, command_id, prop));
    }
    /**
     *This method will be used to position each peer in the appropriate column when pairing for consistent access location
     */
    PairColumnIndex() {
        if (this.peer == null) {
            throw new SyncTraderException_1.SyncTraderException("Peer cannot be null");
        }
        if (this.StrID() == this.peer.StrID()) {
            throw new SyncTraderException_1.SyncTraderException("Compared TraderAccount cannot be the same as peer!");
        }
        return this.StrID() < this.peer.StrID() ? 0 : 1;
    }
    CreateAndAtachSyncStatePairID() {
        if (!this.Peer()) {
            return;
        }
        if (this.open_tickets.length !== this.Peer().open_tickets.length) {
            return;
        }
        var peer_open_tickets = this.Peer().open_tickets;
        var own_tickets = "";
        var peer_tickets = "";
        for (var i = 0; i < this.open_tickets.length; i++) {
            own_tickets += this.SEP + this.open_tickets[i];
            peer_tickets += this.SEP + peer_open_tickets[i];
        }
        var state_pair_id = this.PairColumnIndex() === 0
            ? this.StrID() + this.SEP + this.peer.StrID() + this.SEP + own_tickets + this.SEP + peer_tickets
            : this.peer.StrID() + this.SEP + this.StrID() + this.SEP + peer_tickets + this.SEP + own_tickets;
        //send to both peers               
        this.SendData(SyncUtil_1.SyncUtil.SyncStatePairIDPacket(state_pair_id));
        this.Peer().SendData(SyncUtil_1.SyncUtil.SyncStatePairIDPacket(state_pair_id));
    }
    SendPeerSymbolDigits() {
        if (!this.Peer()) {
            return;
        }
        this.SendData(SyncUtil_1.SyncUtil.SymbolDigitsPacket(this.Peer().ChartSymbolDigits()));
    }
    DetachSyncStatePairID() {
        this.SendData(SyncUtil_1.SyncUtil.SyncStatePairIDPacket(""));
    }
    /**
     * Generate an id that uniquely identifies the pair
     */
    PairID() {
        if (this.peer == null) {
            throw new SyncTraderException_1.SyncTraderException("Peer cannot be null");
        }
        if (this.StrID() == this.peer.StrID()) {
            throw new SyncTraderException_1.SyncTraderException("Compared TraderAccount cannot be the same as peer!");
        }
        return this.PairColumnIndex() === 0 ? this.StrID() + this.SEP + this.peer.StrID() : this.peer.StrID() + this.SEP + this.StrID();
    }
    StrID() {
        return this.broker + this.SEP + this.account_number;
    }
    SendGetIntro() {
        this.SendData(SyncUtil_1.SyncUtil.Intro());
    }
    PlaceOrder(placement) {
        this.SendData(SyncUtil_1.SyncUtil.SyncPlackeOrderPacket(placement, this.broker, this.account_number));
        main_1.ipcSend('sending-place-order', {
            account: this.CopyAttr()
        });
    }
    ValidatePlaceOrder(symbol, lot_size, max_percent_diff_in_account_balances = Infinity, is_triggered = false) {
        var valid = false;
        var perecent = 0;
        if (max_percent_diff_in_account_balances >= 0 &&
            this.AccountBalance() > 0 &&
            this.Peer().AccountBalance() > 0) {
            perecent = Math.abs(((this.AccountBalance() - this.Peer().AccountBalance()) /
                this.AccountBalance()) *
                100);
        }
        var err_prefix = is_triggered ? "Trigger validation error!\n" : "";
        if (!this.TerminalConnected()) {
            this.SetLastError(`${err_prefix}Terminal is disconnected!`);
        }
        else if (this.AccountBalance() <= 0) {
            this.SetLastError(`${err_prefix}Not allowed! Account balance must be greater than zero.`);
        }
        else if (this.OnlyTradeWithCredit() && this.IsLiveAccount() && this.AccountCredit() == 0) {
            this.SetLastError(`${err_prefix}Not allowed for live account! Credit cannot be zero.`);
        }
        else if (lot_size > this.ChartSymbolMaxLotSize()) {
            this.SetLastError(`${err_prefix}Maximum lot size of ${this.ChartSymbolMaxLotSize()} exceeded! The specified lot size of ${lot_size} is too big.`);
        }
        else if (lot_size < this.ChartSymbolMinLotSize()) {
            this.SetLastError(`${err_prefix}Cannot be below mininiun lot size of ${this.ChartSymbolMinLotSize()}. The specified lot size of ${lot_size} is too small.`);
        }
        else if (this.IsMarketClosed()) {
            this.SetLastError(`${err_prefix}Market is closed!`);
        }
        else if (!this.ChartSymbolTradeAllowed()) {
            this.SetLastError(`${err_prefix}Trade not allowed for ${this.ChartSymbol()}. Check if symbol is disabled or market is closed.`);
        }
        else if (this.ChartSymbol() !== SyncUtil_1.SyncUtil.GetRelativeSymbol(symbol, this.Broker(), this.AccountNumber())) {
            this.SetLastError(`${err_prefix}Not allowed! Chart symbol must be same as trade symbol. Symbol on chart is ${this.ChartSymbol()} while trade is ${symbol}`);
        }
        else if (perecent > max_percent_diff_in_account_balances) {
            this.SetLastError(`${err_prefix}Percent difference in account balance, ${this
                .AccountBalance()
                .toFixed(2)}${this.AccountCurrency()} of [${this.Broker()} , ${this.AccountNumber()}]  from that of ${this.Peer()
                .AccountBalance()
                .toFixed(2)}${this.Peer().AccountCurrency()} of [${this.Peer().Broker()} , ${this.Peer().AccountNumber()}] which is ${perecent.toFixed(2)}% is greater than the allowable maximum of ${max_percent_diff_in_account_balances}%`);
        }
        else {
            valid = true;
        }
        if (!valid) {
            main_1.ipcSend("validate-place-order-fail", this.CopyAttr());
        }
        return valid;
    }
    IsModificationInProgress(own_order, peer_order) {
        return own_order.IsSyncModifyingTarget()
            || own_order.IsSyncModifyingStoploss()
            || peer_order.IsSyncModifyingTarget()
            || peer_order.IsSyncModifyingStoploss();
    }
    IsAllGroupOrdersOpenAndNotClosing(own_order, peer_order) {
        var orders = this.Orders();
        var own_group_order_open_count = 0;
        for (let order of orders) {
            if (order.GropuId()
                && order.GropuId() === own_order.GropuId()
                && order.IsOpen() //order must be open
                && !order.IsClosing() //order must not be in closing state
            ) {
                own_group_order_open_count++;
            }
        }
        if (!this.Peer())
            return false;
        var peer_orders = this.Peer().Orders();
        var peer_group_order_open_count = 0;
        for (let order of peer_orders) {
            if (order.GropuId()
                && order.GropuId() === peer_order.GropuId()
                && order.IsOpen() //order must be open
                && !order.IsClosing() //order must not be in closing state
            ) {
                peer_group_order_open_count++;
            }
        }
        return own_group_order_open_count === own_order.GroupOrderCount()
            && peer_group_order_open_count === peer_order.GroupOrderCount();
    }
    RetrySendPlaceOrderOrForceClosePeer(placement) {
        var attempts = this.PlaceOrderRetryAttempt.get(placement.id);
        if (!attempts) {
            attempts = 0;
        }
        attempts++;
        if (attempts > Constants_1.Constants.MAX_PLACE_ORDER_RETRY) {
            placement.SetOperationCompleteStatus(OrderPlacement_1.OrderPlacement.COMPLETE_FAIL);
            var peer_placement = this.Peer().SyncPlacingOrders.get(placement.paired_uuid);
            if (peer_placement) {
                var peer_ticket = peer_placement.ticket;
                var reason = this.ForceCloseReasonForFailedOrderPlacement(peer_ticket);
                this.Peer().ForceCloseMe(peer_ticket, reason); //forcibly close the peer order
            }
            return;
        }
        this.PlaceOrderRetryAttempt.set(placement.id, attempts);
        this.PlaceOrder(placement);
        SyncUtil_1.SyncUtil.LogPlaceOrderRetry(this, placement.id, attempts);
    }
    DoSendCopy(order) {
        //mark as copying to avoid duplicate copies
        order.SyncCopying(true);
        this.peer.SendData(SyncUtil_1.SyncUtil.SyncCopyPacket(order, this.peer.trade_copy_type, this.peer.broker, this.peer.account_number, this.broker, this.account_number));
        main_1.ipcSend('sending-sync-copy', {
            account: this.CopyAttr(),
            order: order
        });
    }
    KnowMyPeer() {
        var _a, _b;
        this.SendData(SyncUtil_1.SyncUtil.KnowMyPeerPacket((_a = this.peer) === null || _a === void 0 ? void 0 : _a.broker, (_b = this.peer) === null || _b === void 0 ? void 0 : _b.account_number));
    }
    RegisterPeerTicket(peer_ticket) {
        var _a;
        (_a = this.peer) === null || _a === void 0 ? void 0 : _a.SendData(SyncUtil_1.SyncUtil.RegisterPeerTicketPacket(peer_ticket, this.broker, this.account_number));
    }
    ClosePeerByTicket(peer_ticket) {
        var _a;
        (_a = this.peer) === null || _a === void 0 ? void 0 : _a.SendData(SyncUtil_1.SyncUtil.CloseByTicketPacket(peer_ticket));
    }
    NotifyPeerOpenPosition(peer_ticket, peer_total_orders_open) {
        var _a;
        (_a = this.peer) === null || _a === void 0 ? void 0 : _a.SendData(SyncUtil_1.SyncUtil.NotifyPeerOpenPositionPacket(peer_ticket, peer_total_orders_open));
    }
    DoSendClose(own_order, peer_order) {
        //mark as sync closing to avoid duplicate operation
        own_order.Closing(true);
        var true_point = this.TrueSymbolPointForSpread();
        var spread_point = SyncUtil_1.SyncUtil.SymbolSafetySpreadPiont(this.peer.Broker(), this.peer.AccountNumber(), peer_order.raw_symbol, true_point);
        this.peer.SendData(SyncUtil_1.SyncUtil.SyncClosePacket(peer_order.ticket, own_order.ticket, spread_point));
        main_1.ipcSend('sending-sync-close', {
            account: this.CopyAttr(),
            order: own_order,
            peer_order: peer_order
        });
    }
    DoSendOwnClose(order, force = false, reason = '') {
        //mark as closing to avoid duplicate operation
        order.Closing(true);
        var true_point = this.TrueSymbolPointForSpread();
        var spread_point = SyncUtil_1.SyncUtil.SymbolSafetySpreadPiont(this.Broker(), this.AccountNumber(), order.raw_symbol, true_point);
        this.SendData(SyncUtil_1.SyncUtil.OwnClosePacket(order.ticket, spread_point, force, reason));
        main_1.ipcSend('sending-own-close', {
            account: this.CopyAttr(),
            order: order,
            force: force,
            reason: reason
        });
    }
    IsRequestingTakeProfitParam() { return this.is_requesting_take_profit_param; }
    IsModifyingTakeProfit() { return this.is_modifying_take_profit; }
    SetRequestingTakeProfitParam(b) {
        this.is_requesting_take_profit_param = b;
    }
    SetModifyingTakeProfit(b) {
        this.is_modifying_take_profit = b;
    }
    RequestTakeProfitParam() {
        this.SetRequestingTakeProfitParam(true);
        this.peer.SendData(SyncUtil_1.SyncUtil.RequestingTakeProfitParam());
    }
    DoSendModifyTarget(own_order, peer_order, new_target) {
        //mark as sync modifying target to avoid duplicate operation
        own_order.SyncModifyingTarget(true);
        this.peer.SendData(SyncUtil_1.SyncUtil.SyncModifyTargetPacket(new_target, peer_order.ticket, own_order.ticket));
        main_1.ipcSend('sending-modify-target', {
            account: this.CopyAttr(),
            order: own_order,
            peer_order: peer_order
        });
    }
    ForceCloseReasonForFailedSyncCopy(ticket) {
        return `Forcibly closed order #${ticket} because sync copy failed after maximum retry attempts of ${Constants_1.Constants.MAX_COPY_RETRY}.`;
    }
    ForceCloseReasonForFailedOrderPlacement(ticket) {
        return `Forcibly closed order #${ticket} because sync order placement failed after maximum retry attempts of ${Constants_1.Constants.MAX_PLACE_ORDER_RETRY}.`;
    }
    DefaultForceCloseReason(ticket) {
        return `Forcibly closed order #${ticket} because possibly sync copy or order placement failed`;
    }
    ForceCloseMe(ticket, reason = this.DefaultForceCloseReason(ticket)) {
        let order = this.orders.get(ticket);
        if (order) {
            this.DoSendOwnClose(order, true, reason);
        }
    }
    CloseAllTrades(event = null, comment = null) {
        var atleastOne = false;
        this.orders.forEach((order, ticket) => {
            if (order.IsClosed() || order.IsClosing()) {
                return;
            }
            atleastOne = true;
            this.DoSendOwnClose(order);
        });
        if (this.peer) {
            this.peer.orders.forEach((order, ticket) => {
                if (order.IsClosed() || order.IsClosing()) {
                    return;
                }
                atleastOne = true;
                this.DoSendOwnClose(order);
            });
        }
        if (atleastOne && event) {
            main_1.ipcSend(event, comment);
        }
    }
    SendTradeProperties(config) {
        var _a;
        if (!config) {
            return;
        }
        var prop = (_a = config[this.Broker()]) === null || _a === void 0 ? void 0 : _a.call(config, this.AccountNumber() + "");
        prop = prop || config;
        this.SendData(SyncUtil_1.SyncUtil.TradePropertiesPacket(prop));
    }
    SendPeerSetTakeProfit() {
        if (!this.peer) {
            return;
        }
        this.peer.SetRequestingTakeProfitParam(false);
        this.peer.SetModifyingTakeProfit(true);
        this.peer.SendData(SyncUtil_1.SyncUtil.SetTakeProfit(this));
    }
    /**
     * Send copy to peer
     */
    SendCopy(unsynced_orders) {
        for (let order of unsynced_orders) {
            //skip for those that are already closed or copying is in progress
            if (!order.IsCopyable() || order.IsClosed() || order.IsSyncCopying())
                continue;
            //at this point check manual entry order
            //we know that orders without group id were enter manual
            if (!order.GropuId()) {
                //in this block we will block orders whose sync copy for manual entry is disabled
                if (!this.SyncCopyManualEntry()
                    || !this.Peer().SyncCopyManualEntry()) {
                    //skip since at least one of the pairing EAs disabled sync copy for manual entry
                    continue;
                }
            }
            this.DoSendCopy(order);
        }
    }
    RetrySendCopyOrForceCloseMe(origin_ticket) {
        var attempts = this.CopyRetryAttempt.get(origin_ticket);
        if (!attempts) {
            attempts = 0;
        }
        attempts++;
        if (attempts > Constants_1.Constants.MAX_COPY_RETRY) {
            var reason = this.ForceCloseReasonForFailedSyncCopy(origin_ticket);
            this.ForceCloseMe(origin_ticket, reason); //forcely close the order
            return;
        }
        this.CopyRetryAttempt.set(origin_ticket, attempts);
        let order = this.orders.get(origin_ticket);
        this.DoSendCopy(order);
        SyncUtil_1.SyncUtil.LogCopyRetry(this, origin_ticket, attempts);
    }
    SendClose(synced_orders) {
        for (let paired of synced_orders) {
            let own_column = this.PairColumnIndex();
            let peer_column = this.peer.PairColumnIndex();
            var own_order = paired[own_column];
            var peer_order = paired[peer_column];
            //skip for those that are still open or sync closing is in progress
            if (!own_order.IsClosed() || own_order.IsClosing() || own_order.IsLockInProfit())
                continue;
            this.DoSendClose(own_order, peer_order);
        }
    }
    SendCloseToGroup(ticket) {
        let orderObj = this.orders.get(ticket);
        var orders = this.Orders();
        var found = false;
        for (var order of orders) {
            if (orderObj.IsClosed()
                && orderObj.GropuId() === order.GropuId()
                && !order.IsClosed()
                && !order.IsClosing()
                && !order.IsLockInProfit()) {
                this.DoSendOwnClose(order);
                found = true;
            }
        }
        return found;
    }
    RetrySendOwnClose(ticket) {
        var attempts = this.CloseRetryAttempt.get(ticket);
        if (!attempts) {
            attempts = 0;
        }
        if (attempts > Constants_1.Constants.MAX_CLOSE_RETRY)
            return;
        this.CloseRetryAttempt.set(ticket, attempts);
        let order = this.orders.get(ticket);
        this.DoSendOwnClose(order);
        SyncUtil_1.SyncUtil.LogOwnCloseRetry(this, ticket, attempts);
    }
    RetrySendClose(origin_ticket, peer_ticket) {
        var attempts = this.CloseRetryAttempt.get(origin_ticket);
        if (!attempts) {
            attempts = 0;
        }
        if (attempts > Constants_1.Constants.MAX_CLOSE_RETRY)
            return;
        this.CloseRetryAttempt.set(origin_ticket, attempts);
        let order = this.orders.get(origin_ticket);
        let peer_order = this.Peer().orders.get(peer_ticket);
        this.DoSendClose(order, peer_order);
        SyncUtil_1.SyncUtil.LogCloseRetry(this, origin_ticket, peer_ticket, attempts);
    }
    VirtualSync(own_ticket, bitOrderPairs) {
        if (!this.peer) {
            return;
        }
        var paired_bit_orders = bitOrderPairs.get(this.PairID());
        if (!paired_bit_orders) {
            return;
        }
        for (var pair_ticket of paired_bit_orders) {
            var own_bit_order = pair_ticket[this.PairColumnIndex()]; //modified111
            if (own_bit_order.ticket !== own_ticket) {
                continue;
            }
            var own_order = this.orders.get(own_bit_order.ticket);
            var peer_bit_order = pair_ticket[this.peer.PairColumnIndex()];
            var peer_order = this.peer.orders.get(peer_bit_order.ticket);
            var own_spread_point = this.ChartSymbolSpread() * this.TrueSymbolPointForSpread();
            this.peer.SendData(SyncUtil_1.SyncUtil.VirtualSyncPacket(peer_order.ticket, own_order.ticket, own_order.stoploss, own_spread_point));
        }
    }
    DeterminePeerTarget(own_order, peer_order) {
        //get the absolute distance in points
        //between the own order stoploss and PEER order open price
        var pip_piont = Math.abs(own_order.stoploss - peer_order.open_price);
        //negate the value since the target is below open in SELL position
        if (peer_order.position == 'SELL') {
            pip_piont = -pip_piont;
        }
        var tg_safety_srpread = SyncUtil_1.SyncUtil.SymbolSafetySpreadPiont(this.peer.Broker(), this.peer.AccountNumber(), peer_order.raw_symbol, this.TrueSymbolPointForSpread());
        peer_order.SetSafetySpreadInUse(tg_safety_srpread);
        if (peer_order.position == "BUY") {
            tg_safety_srpread = -tg_safety_srpread;
        }
        var peer_target_price = peer_order.open_price + pip_piont + tg_safety_srpread;
        return peer_target_price;
    }
    ApplySafetySpreadConfig() {
        var orders = this.Orders();
        for (let order of orders) {
            var true_point = this.TrueSymbolPointForSpread();
            var safety_spread = SyncUtil_1.SyncUtil.SymbolSafetySpreadPiont(this.Broker(), this.AccountNumber(), order.raw_symbol, true_point);
            if (safety_spread != order.SafetySpreadInUse()) {
                order.SetSafetySpreadApplied(false); //trigger the modified saftety spread to be applied
            }
        }
    }
    EnsureTakeProfitIsSet(synced_orders, when_no_target = false) {
        //First ensure both paired accounts have the same number
        //of open orders
        if (!this.Peer()
            || this.TotalOpenOrders() != this.Peer().TotalOpenOrders()) {
            return;
        }
        var is_all_group_orders_open = false;
        for (let paired of synced_orders) {
            let own_column = this.PairColumnIndex();
            let peer_column = this.peer.PairColumnIndex();
            var own_order = paired[own_column];
            var peer_order = paired[peer_column];
            if (own_order.IsClosed() || peer_order.IsClosed()) {
                continue;
            }
            //Well before we  send modification we should ensure all the group orders
            //are open and not in closing state. We don't what the stoploss and target
            //to be modified when orders are being closed, it is pointless
            if (!is_all_group_orders_open) {
                is_all_group_orders_open = this.IsAllGroupOrdersOpenAndNotClosing(own_order, peer_order);
                if (!is_all_group_orders_open) {
                    return; //wait till all group orders are open
                }
            }
            if ((when_no_target && own_order.target == 0)
                || !when_no_target) {
                if (!this.IsModifyingTakeProfit()
                    && !this.IsRequestingTakeProfitParam()) {
                    this.RequestTakeProfitParam();
                }
            }
        }
    }
    SendModify(synced_orders) {
        var is_all_group_orders_open = false;
        for (let paired of synced_orders) {
            let own_column = this.PairColumnIndex();
            let peer_column = this.peer.PairColumnIndex();
            var own_order = paired[own_column];
            var peer_order = paired[peer_column];
            if (own_order.IsClosed() || peer_order.IsClosed()) {
                continue;
            }
            //Well before we  send modification we should ensure all the group orders
            //are open and not in closing state. We don't what the stoploss and target
            //to be modified when orders are being closed, it is pointless
            if (!is_all_group_orders_open) {
                is_all_group_orders_open = this.IsAllGroupOrdersOpenAndNotClosing(own_order, peer_order);
                if (!is_all_group_orders_open) {
                    return; //wait till all group orders are open
                }
            }
            //normalize relevant price variables
            SyncUtil_1.SyncUtil.NormalizePrice(own_order);
            SyncUtil_1.SyncUtil.NormalizePrice(peer_order);
            if ((own_order.stoploss != 0 && peer_order.target == 0)
                || own_order.IsStoplossChanged()
                || !peer_order.IsSafetySpreadApplied()) {
                SyncUtil_1.SyncUtil.AsyncWaitWhile(() => {
                    var new_target = this.DeterminePeerTarget(own_order, peer_order);
                    //making sure the new target is different before we modify
                    if (new_target != peer_order.target) {
                        this.DoSendModifyTarget(own_order, peer_order, new_target); //modify peer target be equal to own stoploss
                    }
                    own_order.SetStoplossChanged(false);
                    peer_order.SetSafetySpreadApplied(true);
                }, () => this.IsModificationInProgress(own_order, peer_order));
                /*if (!this.IsModificationInProgress(own_order, peer_order)) { //there must be no modification in progerss - whether targe or stoploss
                    var new_target: number = this.DeterminePeerTarget(own_order, peer_order, signed_srpread);
                    this.DoSendModifyTarget(own_order, peer_order, new_target);//modify peer target be equal to own stoploss
                }*/
            }
        }
    }
    RetrySendModifyTarget(origin_ticket, peer_ticket, new_target) {
        var attempts = this.ModifyTargetRetryAttempt.get(origin_ticket);
        if (!attempts) {
            attempts = 0;
        }
        if (attempts > Constants_1.Constants.MAX_MODIFY_RETRY)
            return;
        attempts++;
        this.ModifyTargetRetryAttempt.set(origin_ticket, attempts);
        let order = this.orders.get(origin_ticket);
        let peer_order = this.Peer().orders.get(peer_ticket);
        this.DoSendModifyTarget(order, peer_order, new_target);
        SyncUtil_1.SyncUtil.LogModifyTargetRetry(this, origin_ticket, peer_ticket, attempts);
    }
}
exports.TraderAccount = TraderAccount;
//# sourceMappingURL=TraderAccount.js.map