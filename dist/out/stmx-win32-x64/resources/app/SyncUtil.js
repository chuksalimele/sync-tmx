"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SyncUtil = void 0;
const app_1 = require("./app");
const Config_1 = require("./Config");
const Constants_1 = require("./Constants");
const Logger_1 = require("./Logger");
class SyncUtil {
    /**
     * asynchronously delay a call to a function while a condition is true
     * and ignores the call to the function if another condition is true
     * @param fun
     * @param wait_condition - keep waiting while this condition is true
     * @param stop_condition (optional)- just cancel and ignore the call to the function if this condition is true
     */
    static AsyncWaitWhile(fun, wait_condition, stop_condition = null) {
        if (stop_condition != null && stop_condition()) {
            return;
        }
        if (wait_condition()) {
            setImmediate(this.AsyncWaitWhile.bind(this), fun, wait_condition, stop_condition);
        }
        else {
            fun();
        }
    }
    static isErrorString(error) {
        return typeof error === 'string';
    }
    static isErrorObject(error) {
        return typeof error === 'object' && error !== null && 'message' in error;
    }
    static GetEAPathsMQL4(lead_path, callback) {
        return this.GetEAPaths0(lead_path, this.MQL4, callback);
    }
    static GetEAPathsMQL5(lead_path, callback) {
        return this.GetEAPaths0(lead_path, this.MQL5, callback);
    }
    static GetEAPathsDLL4(lead_path, callback) {
        return this.GetEAPaths0(lead_path, this.DLL4, callback);
    }
    static GetEAPathsDLL5(lead_path, callback) {
        return this.GetEAPaths0(lead_path, this.DLL5, callback);
    }
    static GetEAPaths(lead_path, callback) {
        return this.GetEAPaths0(lead_path, null, callback);
    }
    static GetEAPaths0(lead_path, mql, callback) {
        var required_files = [];
        var sep_index = lead_path.length;
        var pre_sep_index = lead_path.length;
        var sep_count_back = 0;
        var word = '';
        var terminal_dir = ''; //location of all the MT platforms
        for (var i = lead_path.length - 1; i > -1; i--) {
            var char = lead_path.charAt(i);
            if (char == app_1.path.sep ||
                ((app_1.os.platform() == 'win32' || app_1.os.platform() == 'win64')
                    && (char == '\\' || char == '/'))) {
                pre_sep_index = sep_index;
                sep_index = i;
                sep_count_back++;
                word = lead_path.substring(sep_index + 1, pre_sep_index).trim();
                if (word == 'Terminal') {
                    terminal_dir = lead_path.substring(0, pre_sep_index).trim();
                    break;
                }
            }
        }
        var that = this;
        app_1.fs.readdir(terminal_dir, (err, files) => {
            if (err) {
                return callback(err);
            }
            var try_dirs = [];
            files.forEach(function (file_name) {
                var req_dir_ex4 = terminal_dir + app_1.path.sep +
                    file_name + app_1.path.sep +
                    'MQL4' + app_1.path.sep +
                    'Experts';
                var req_dir_ex5 = terminal_dir + app_1.path.sep +
                    file_name + app_1.path.sep +
                    'MQL5' + app_1.path.sep +
                    'Experts';
                var req_dir_mql4_dll = terminal_dir + app_1.path.sep +
                    file_name + app_1.path.sep +
                    'MQL4' + app_1.path.sep +
                    'Libraries';
                var req_dir_mql5_dll = terminal_dir + app_1.path.sep +
                    file_name + app_1.path.sep +
                    'MQL5' + app_1.path.sep +
                    'Libraries';
                try_dirs.push(req_dir_ex4);
                try_dirs.push(req_dir_ex5);
                try_dirs.push(req_dir_mql4_dll);
                try_dirs.push(req_dir_mql5_dll);
            });
            try_dirs.forEach(function (try_dir_name, index) {
                var resultFn = function (exists) {
                    if (exists) {
                        var req_file = this;
                        var req_mql = SyncUtil.PathMQL(req_file);
                        //req_file = req_mql === SyncUtil.MQL4
                        //? req_file + path.sep + Config.MT4_EA_EXEC_FILE_SIMPLE_NAME 
                        //: req_file + path.sep + Config.MT5_EA_EXEC_FILE_SIMPLE_NAME; //old
                        var is_mql4_dir = false;
                        var is_mql5_dir = false;
                        var is_dll4_dir = false;
                        var is_dll5_dir = false;
                        if (req_mql === SyncUtil.MQL4 && req_file.endsWith(app_1.path.sep + "Experts")) { //new
                            req_file = req_file + app_1.path.sep + Config_1.Config.MT4_EA_EXEC_FILE_SIMPLE_NAME;
                            is_mql4_dir = true;
                        }
                        else if (req_mql === SyncUtil.MQL5 && req_file.endsWith(app_1.path.sep + "Experts")) {
                            req_file = req_file + app_1.path.sep + Config_1.Config.MT5_EA_EXEC_FILE_SIMPLE_NAME;
                            is_mql5_dir = true;
                        }
                        else if (req_mql === SyncUtil.MQL4 && req_file.endsWith(app_1.path.sep + "Libraries")) { //DLL FOR MT4
                            req_file = req_file + app_1.path.sep + Config_1.Config.MT4_EA_DLL_FILE_SIMPLE_NAME;
                            is_dll4_dir = true;
                        }
                        else if (req_mql === SyncUtil.MQL5 && req_file.endsWith(app_1.path.sep + "Libraries")) { //DLL FOR MT5
                            req_file = req_file + app_1.path.sep + Config_1.Config.MT5_EA_DLL_FILE_SIMPLE_NAME;
                            is_dll5_dir = true;
                        }
                        if (!mql) {
                            required_files.push(req_file);
                        }
                        else if (mql === SyncUtil.MQL4 || is_mql4_dir) {
                            required_files.push(req_file);
                        }
                        else if (mql === SyncUtil.MQL5 || is_mql5_dir) {
                            required_files.push(req_file);
                        }
                        else if (mql === SyncUtil.DLL4 || is_dll4_dir) {
                            required_files.push(req_file);
                        }
                        else if (mql === SyncUtil.DLL5 || is_dll5_dir) {
                            required_files.push(req_file);
                        }
                    }
                    if (index == try_dirs.length - 1) {
                        callback(null, required_files);
                    }
                };
                var resultFnBind = resultFn.bind(try_dir_name);
                that.checkFileExists(try_dir_name)
                    .then(resultFnBind);
            });
        });
        return; //todo
    }
    static PathMQL(lead_path) {
        var sep_index = -1;
        var pre_sep_index = -1;
        var sep_count_back = 0;
        var word = '';
        for (var i = lead_path.length - 1; i > -1; i--) {
            var char = lead_path.charAt(i);
            if (char == app_1.path.sep ||
                ((app_1.os.platform() == 'win32' || app_1.os.platform() == 'win64')
                    && (char == '\\' || char == '/'))) {
                pre_sep_index = sep_index;
                sep_index = i;
                sep_count_back++;
                if (pre_sep_index > -1) {
                    word = lead_path.substring(sep_index + 1, pre_sep_index).trim();
                    if (word == 'MQL4') {
                        return SyncUtil.MQL4;
                    }
                    if (word == 'MQL5') {
                        return SyncUtil.MQL5;
                    }
                }
            }
        }
        return null;
    }
    static IsPathMQL4(lead_path) {
        return this.PathMQL(lead_path) === this.MQL4;
    }
    static IsPathMQL5(lead_path) {
        return this.PathMQL(lead_path) === this.MQL5;
    }
    static checkFileExists(filepath) {
        return new Promise((resolve, reject) => {
            app_1.fs.exists(filepath, exists => {
                resolve(exists);
            });
        });
    }
    static checkFileReadAndWritePemission(filepath) {
        return new Promise((resolve, reject) => {
            app_1.fs.access(filepath, app_1.fs.constants.R_OK | app_1.fs.constants.W_OK, error => {
                resolve(!error);
            });
        });
    }
    static checkFileWritePemission(filepath) {
        return new Promise((resolve, reject) => {
            app_1.fs.access(filepath, app_1.fs.constants.W_OK, error => {
                resolve(!error);
            });
        });
    }
    static checkFileReadPemission(filepath) {
        return new Promise((resolve, reject) => {
            app_1.fs.access(filepath, app_1.fs.constants.R_OK, error => {
                resolve(!error);
            });
        });
    }
    static checkFileExecutePemission(filepath) {
        return new Promise((resolve, reject) => {
            app_1.fs.access(filepath, app_1.fs.constants.X_OK, error => {
                resolve(!error);
            });
        });
    }
    static checkFileFullPemission(filepath) {
        return new Promise((resolve, reject) => {
            app_1.fs.access(filepath, app_1.fs.constants.F_OK, error => {
                resolve(!error);
            });
        });
    }
    static Unique() {
        return "" + (++this.CountSeq) + this.InitUnique;
    }
    static NormalizePrice(order) {
        if (order.Digits() == 0) {
            return order;
        }
        order.open_price = Number(order.open_price.toFixed(order.Digits()));
        order.close_price = Number(order.close_price.toFixed(order.Digits()));
        order.target = Number(order.target.toFixed(order.Digits()));
        order.stoploss = Number(order.stoploss.toFixed(order.Digits()));
        return order;
    }
    static ArrayRemove(arr, element) {
        const objIndex = arr.findIndex(obj => obj === element);
        if (objIndex > -1) {
            arr.splice(objIndex, 1);
        }
    }
    static MapToObject(map) {
        let obj = {};
        map.forEach(function (value, key) {
            obj[key] = value;
        });
        return obj;
    }
    static replaceAll(name, search, replacement) {
        while (true) {
            var d_name = name;
            d_name = d_name.replace(search, replacement);
            if (d_name == name) {
                break;
            }
            name = d_name;
        }
        return name;
    }
    static SymbolSafetySpread(broker, account_number, symbol) {
        var general_symbol = SyncUtil.GeneralSymbol(broker, account_number, symbol);
        if (general_symbol) {
            var spread_config = this.AppConfigMap.get('spread');
            if (spread_config) {
                var spread_digit = spread_config[general_symbol] - 0; //implicitly convert to number
                if (spread_digit > 0) {
                    return spread_digit;
                }
            }
        }
        return 0;
    }
    static SymbolSafetySpreadPiont(broker, account_number, symbol, symbol_point) {
        return SyncUtil.SymbolSafetySpread(broker, account_number, symbol) * symbol_point;
    }
    static GeneralSymbol(broker, account_number, symbol) {
        var _a, _b;
        var symbol_config = this.AppConfigMap.get('symbol');
        if (symbol_config) {
            for (var general_symbol in symbol_config) {
                var broker_relative_symbol = (_b = (_a = symbol_config[general_symbol][broker]) === null || _a === void 0 ? void 0 : _a[account_number]) === null || _b === void 0 ? void 0 : _b['symbol'];
                var symbol_no_slash = SyncUtil.replaceAll(symbol, '/', '');
                if (broker_relative_symbol == symbol || broker_relative_symbol == symbol_no_slash) {
                    return general_symbol;
                }
            }
        }
        return '';
    }
    static SaveAppConfig(json, callback) {
        var that = this;
        //overwrite the file content
        app_1.fs.writeFile(Config_1.Config.APP_CONFIG_FILE, JSON.stringify(json), { encoding: 'utf8', flag: 'w' }, function (err) {
            if (err) {
                return console.log(err);
                callback(false);
            }
            else {
                that.AppConfigMap = new Map(Object.entries(json));
                callback(true);
            }
        });
    }
    static LoadSavedSyncTrade() {
        //first load the sync state of the trades
        var file = Config_1.Config.SYNC_LOG_FILE;
        var dirname = app_1.path.dirname(file);
        if (!app_1.fs.existsSync(dirname)) {
            app_1.mkdirp.sync(dirname);
        }
        var fd = null;
        if (app_1.fs.existsSync(file)) {
            //file exists
            //according to doc - Open file for reading and writing.
            //An exception occurs if the file does not exist
            //So since we know that at this point the file exists we are not bothered about exception
            //since it will definitely not be thrown
            fd = app_1.fs.openSync(file, "r+");
        }
        else {
            //file does not exist
            //according to doc - Open file for reading and writing.
            //The file is created(if it does not exist) or truncated(if it exists).
            //So since we known that at this point it does not we are not bothered about the truncation
            fd = app_1.fs.openSync(file, "w+");
        }
        var stats = app_1.fs.statSync(file);
        var size = stats["size"];
        var rq_size = size;
        var readPos = size > rq_size ? size - rq_size : 0;
        var length = size - readPos;
        var buffer = Buffer.alloc(length);
        if (length > 0) {
            app_1.fs.readSync(fd, buffer, 0, length, readPos);
            var data = buffer.toString(); //toString(0, length) did not work but toString() worked for me
            var json_arr = JSON.parse(data);
            //validate structure
            json_arr = this.ValidateSyncLogStructure(json_arr);
            if (json_arr) {
                return new Map(json_arr);
            }
        }
        return new Map([]);
    }
    static ValidateSyncLogStructure(json_arr) {
        if (json_arr.constructor !== Array) {
            console.error('invalid sync log format detected - expected json array');
            return;
        }
        for (var i = 0; i < json_arr.length; i++) {
            if (json_arr[i].constructor !== Array) {
                console.error('invalid sync log format detected - expected array of paired accounts');
                return;
            }
            var json_arr_i = json_arr[i];
            if (typeof json_arr_i[0] !== 'string') {
                console.error('invalid sync log format detected - expected string type of paired accounts');
                return;
            }
            if (json_arr_i[1].constructor !== Array) {
                console.error('invalid sync log format detected - expected array of paired bit orders');
                return;
            }
            var json_arr_i_1 = json_arr_i[1];
            for (var j = 0; j < json_arr_i_1.length; j++) {
                if (json_arr_i_1[j].constructor !== Array) {
                    console.error('invalid sync log format detected - expected array of bit order');
                    return;
                }
                var json_arr_i_1_j = json_arr_i_1[j];
                if (json_arr_i_1_j.length !== 2) {
                    console.error('invalid sync log format detected - expected array of 2 bit orders');
                    return;
                }
                if ((typeof json_arr_i_1_j[0] === 'object' && typeof json_arr_i_1_j[1] !== 'object')
                    || (typeof json_arr_i_1_j[1] === 'object' && typeof json_arr_i_1_j[0] !== 'object')) {
                    console.error('invalid sync log format detected - expected same type for paired bit orders');
                    return;
                }
                var old_structure_group_id = SyncUtil.Unique();
                for (var k = 0; k < json_arr_i_1_j.length; k++) {
                    var pair = json_arr_i_1_j[k];
                    if (typeof pair === 'string' || typeof pair === 'number') {
                        // this was the old structure which was string ticket.
                        // we will replace with new structure - converting to object representation
                        json_arr_i_1_j[k] = {
                            ticket: pair,
                            group_id: old_structure_group_id,
                            group_order_count: 1 // 
                        };
                    }
                    else if (typeof pair !== 'object') {
                        console.error('invalid sync log format detected - invalid bit order type');
                        return;
                    }
                    if (!('ticket' in json_arr_i_1_j[k])) {
                        console.error('invalid sync log format detected - ticket property missing');
                        return;
                    }
                    if (!('group_id' in json_arr_i_1_j[k])) {
                        console.error('invalid sync log format detected - group_id property missing');
                        return;
                    }
                    if (!('group_order_count' in json_arr_i_1_j[k])) {
                        console.error('invalid sync log format detected - group_order_count property missing');
                        return;
                    }
                }
            }
        }
        return json_arr;
    }
    static LoadAappConfig() {
        var file = Config_1.Config.APP_CONFIG_FILE;
        var dirname = app_1.path.dirname(file);
        if (!app_1.fs.existsSync(dirname)) {
            app_1.mkdirp.sync(dirname);
        }
        var fd = app_1.fs.openSync(file, 'a+'); //open for reading and appending
        var stats = app_1.fs.statSync(file);
        var size = stats['size'];
        var buffer = Buffer.alloc(size);
        app_1.fs.readSync(fd, buffer, 0, size, null);
        var data = buffer.toString(); //toString(0, length) did not work but toString() worked for me
        try {
            this.AppConfigMap = new Map(Object.entries(JSON.parse(data)));
        }
        catch (e) {
            Logger_1.default.error(e.message);
            console.error(e);
        }
    }
    static UnpairedNotificationPacket(peer_broker, peer_account_number) {
        return `peer_broker=${peer_broker}${Constants_1.Constants.TAB}`
            + `peer_account_number=${peer_account_number}${Constants_1.Constants.TAB}`
            + `action=unpaired_notification`;
    }
    static CommandPacket(command, command_id, prop) {
        var packet = "";
        for (var n in prop) {
            packet += `${n}=${prop[n]}${Constants_1.Constants.TAB}`;
        }
        return `${packet}command_id=${command_id}${Constants_1.Constants.TAB}command=${command}`;
    }
    static SyncPlackeOrderPacket(placement, broker, account_number) {
        return SyncUtil.PlackeOrderPacket(placement, broker, account_number, 'sync_place_order');
    }
    static SyncPlackeValidateOrderPacket(placement, broker, account_number) {
        return SyncUtil.PlackeOrderPacket(placement, broker, account_number, 'sync_validate_place_order');
    }
    static SyncStatePairIDPacket(state_pair_id) {
        return `sync_state_paird_id=` + state_pair_id + Constants_1.Constants.TAB
            + `action=sync_state_paird_id`;
    }
    static SymbolDigitsPacket(peer_symbol_digit) {
        return `peer_symbol_digits=` + peer_symbol_digit;
    }
    static PlackeOrderPacket(placement, broker, account_number, action) {
        return `uuid=` + placement.paired_uuid + Constants_1.Constants.TAB
            + `symbol=` + placement.symbol + Constants_1.Constants.TAB
            + `relative_symbol=` + SyncUtil.GetRelativeSymbol(placement.symbol, broker, account_number) + Constants_1.Constants.TAB
            + `position=` + placement.position + Constants_1.Constants.TAB
            + `lot_size=` + placement.lot_size + Constants_1.Constants.TAB
            + `action=` + action;
    }
    static TradePropertiesPacket(obj) {
        return `sync_copy_manual_entry=` + obj.sync_copy_manual_entry + Constants_1.Constants.TAB
            + `exit_clearance_factor=` + obj.exit_clearance_factor + Constants_1.Constants.TAB
            + `only_trade_with_credit=` + obj.only_trade_with_credit + Constants_1.Constants.TAB
            + `enable_exit_at_peer_stoploss=` + obj.enable_exit_at_peer_stoploss;
    }
    static SetTakeProfit(account) {
        return `peer_account_margin=` + account.AccountMargin() + Constants_1.Constants.TAB
            + `peer_stopout_level=` + account.AccountStopoutLevel() + Constants_1.Constants.TAB
            + `peer_account_balance=` + account.AccountBalance() + Constants_1.Constants.TAB
            + `peer_account_credit=` + account.AccountCredit() + Constants_1.Constants.TAB
            + `peer_total_commission=` + account.TotalCommission() + Constants_1.Constants.TAB
            + `peer_total_swap=` + account.TotalSwap() + Constants_1.Constants.TAB
            + `peer_total_lot_size=` + account.TotalLotSize() + Constants_1.Constants.TAB
            + `peer_contract_size=` + account.ContractSize() + Constants_1.Constants.TAB
            + `peer_base_open_price=` + account.BaseOpenPrice() + Constants_1.Constants.TAB
            + `peer_position=` + account.Position() + Constants_1.Constants.TAB
            + `peer_safety_spread=` + SyncUtil.SymbolSafetySpread(account.Broker(), account.AccountNumber(), account.ChartSymbol()) + Constants_1.Constants.TAB
            + `action=set_take_profit`;
    }
    static SyncCopyPacket(order, trade_copy_type, broker, account_number, peer_broker, peer_account_number) {
        if (order.ticket == -1 &&
            order.position == undefined &&
            order.symbol == undefined) {
            console.log("Why is this? Please resolve.");
        }
        //try for symbol and that of raw_symbol for whichever is configured
        var relative_symbol = SyncUtil.GetRelativePeerSymbol(order.symbol, peer_broker, peer_account_number, broker, account_number)
            || SyncUtil.GetRelativePeerSymbol(order.raw_symbol, peer_broker, peer_account_number, broker, account_number);
        return `ticket=` + order.ticket + Constants_1.Constants.TAB
            + `position=` + order.position + Constants_1.Constants.TAB
            + `target=` + order.stoploss + Constants_1.Constants.TAB //yes, target becomes the stoploss of the sender - according to the strategy
            + `stoploss=` + order.target + Constants_1.Constants.TAB //yes, stoploss becomes the target of the sender - according to the strategy
            + `symbol=` + order.symbol + Constants_1.Constants.TAB
            + `raw_symbol=` + order.raw_symbol + Constants_1.Constants.TAB
            + `relative_symbol=` + relative_symbol + Constants_1.Constants.TAB
            + `lot_size=` + order.lot_size + Constants_1.Constants.TAB +
            `trade_copy_type=` + trade_copy_type + Constants_1.Constants.TAB + `action=sync_copy`;
    }
    static VirtualSyncPacket(own_ticket, peer_ticket, peer_stoploss, peer_spread_point) {
        return `own_ticket=` + own_ticket + Constants_1.Constants.TAB
            + `peer_ticket=` + peer_ticket + Constants_1.Constants.TAB
            + `peer_stoploss=` + peer_stoploss + Constants_1.Constants.TAB
            + `peer_spread_point=` + peer_spread_point + Constants_1.Constants.TAB
            + `command=virtual_sync`;
    }
    static SyncClosePacket(ticket, origin_ticket, spread_point) {
        return `ticket=` + ticket + Constants_1.Constants.TAB // the ticket to be closed
            + `origin_ticket=` + origin_ticket + Constants_1.Constants.TAB
            + `spread_point=` + spread_point + Constants_1.Constants.TAB
            + `action=sync_close`;
    }
    static OwnClosePacket(ticket, spread_point, force, reason = '') {
        return `ticket=` + ticket + Constants_1.Constants.TAB // the ticket to be closed
            + `spread_point=` + spread_point + Constants_1.Constants.TAB
            + `force=` + force + Constants_1.Constants.TAB
            + `reason=` + reason + Constants_1.Constants.TAB
            + `action=own_close`;
    }
    static SyncModifyTargetPacket(price, ticket, origin_ticket) {
        return `target=` + price + Constants_1.Constants.TAB
            + `ticket=` + ticket + Constants_1.Constants.TAB
            + `origin_ticket=` + origin_ticket + Constants_1.Constants.TAB
            + `action=sync_modify_target`;
    }
    static RequestingTakeProfitParam() {
        return `action=request_take_profit_param`;
    }
    static SyncModifyStoplossPacket(price, ticket, origin_ticket) {
        return `stoploss=` + price + Constants_1.Constants.TAB
            + `ticket=` + ticket + Constants_1.Constants.TAB
            + `origin_ticket=` + origin_ticket + Constants_1.Constants.TAB
            + `action=sync_modify_stoploss`;
    }
    static Intro() {
        return "action=intro";
    }
    static PingPacket() {
        return "ping=pong";
    }
    static GetRelativeSymbol(symbol, broker, account_number) {
        var symb_config = this.AppConfigMap.get('symbol');
        if (symb_config) {
            var rel_symbols = symb_config[symbol];
            if (rel_symbols) {
                var obj;
                if (typeof rel_symbols[broker] === 'object'
                    && typeof (obj = rel_symbols[broker][account_number]) === 'object') {
                    return obj['symbol']; // using new configuration
                }
            }
        }
        return '';
    }
    static GetRelativePeerSymbol(peer_symbol, peer_broker, peer_account_number, broker, account_number) {
        var symb_config = this.AppConfigMap.get('symbol');
        if (!symb_config) {
            return '';
        }
        for (var n in symb_config) {
            var sc = symb_config[n];
            var obj;
            if (typeof sc[peer_broker] === 'object'
                && typeof (obj = sc[peer_broker][peer_account_number]) === 'object'
                && obj['symbol'] === peer_symbol) {
                if (typeof sc[broker] === 'object'
                    && typeof (obj = sc[broker][account_number]) === 'object') {
                    return obj['symbol'];
                }
            }
        }
        return '';
    }
    /* @Deprecated
    public static GetAllowableEntrySpread(symbol: string, broker: string, account_number: string) {
        var symb_config: Map<string, any> = this.AppConfigMap.get('symbol');
        if (symb_config) {
            var allowable_entry_spread = symb_config[symbol];
            if (allowable_entry_spread) {
                var obj;
                if (typeof allowable_entry_spread[broker] === 'object'
                        && (obj = allowable_entry_spread[broker][account_number]) === 'object') {
                    return obj['allowable_entry_spread'];// using new configuration
                }
            }
        }

        return '';
    }
    */
    static NormalizeName(name) {
        name = name.trim();
        var single_space = " ";
        var double_space = single_space + single_space;
        while (true) {
            var d_name = name;
            d_name = d_name.replace(double_space, single_space);
            d_name = d_name.replace(",", "");
            d_name = d_name.replace(".", "");
            if (d_name == name) {
                break;
            }
            name = d_name;
        }
        return name;
    }
    static LogPlaceOrderRetry(account, id, attempts) {
        var final = attempts >= Constants_1.Constants.MAX_PLACE_ORDER_RETRY ? "FINAL " : "";
        console.log(`[${attempts}] ${final}COYP RETRY : Sending place order to [${account.Broker()}, ${account.AccountNumber()}] placement id ${id}`);
    }
    static LogCopyRetry(account, origin_ticket, attempts) {
        var final = attempts >= Constants_1.Constants.MAX_COPY_RETRY ? "FINAL " : "";
        console.log(`[${attempts}] ${final}COYP RETRY : Sending copy #${origin_ticket} from [${account.Broker()}, ${account.AccountNumber()}] to [${account.Peer().Broker()}, ${account.Peer().AccountNumber()}]`);
    }
    static LogCloseRetry(account, origin_ticket, peer_ticket, attempts) {
        var final = attempts >= Constants_1.Constants.MAX_CLOSE_RETRY ? "FINAL " : "";
        console.log(`[${attempts}] ${final}CLOSE RETRY : Sending close of #${origin_ticket} to target #${peer_ticket} - from [${account.Broker()}, ${account.AccountNumber()}] to [${account.Peer().Broker()}, ${account.Peer().AccountNumber()}]`);
    }
    static LogOwnCloseRetry(account, ticket, attempts) {
        var final = attempts >= Constants_1.Constants.MAX_CLOSE_RETRY ? "FINAL " : "";
        console.log(`[${attempts}] ${final}CLOSE RETRY : Sending close of #${ticket} from [${account.Broker()}, ${account.AccountNumber()}]`);
    }
    static LogModifyTargetRetry(account, origin_ticket, peer_ticket, attempts) {
        var final = attempts >= Constants_1.Constants.MAX_MODIFY_RETRY ? "FINAL " : "";
        console.log(`[${attempts}] ${final}MODIFY TARGET RETRY : Sending changed stoploss(${origin_ticket})  of #${origin_ticket} to modify target price of #${peer_ticket} - from [${account.Broker()}, ${account.AccountNumber()}] to [${account.Peer().Broker()}, ${account.Peer().AccountNumber()}]`);
    }
}
exports.SyncUtil = SyncUtil;
SyncUtil.InitUnique = (new Date()).getTime().toString(36) + Math.random().toString(36).slice(2);
SyncUtil.CountSeq = 0;
SyncUtil.AppConfigMap = new Map();
SyncUtil.MQL4 = 'MQL4';
SyncUtil.MQL5 = 'MQL5';
SyncUtil.DLL4 = 'DLL4';
SyncUtil.DLL5 = 'DLL5';
//# sourceMappingURL=SyncUtil.js.map