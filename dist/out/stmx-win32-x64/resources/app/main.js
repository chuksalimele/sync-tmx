'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
exports.GetSyncService = exports.ipcSend = exports.Shutdown = void 0;
Object.defineProperty(exports, "__esModule", { value: true });
const app_1 = require("./app");
const Config_1 = require("./Config");
const Constants_1 = require("./Constants");
const PlaceOrderTrigger_1 = require("./PlaceOrderTrigger");
const SyncUtil_1 = require("./SyncUtil");
const { app, ipcMain, BrowserWindow } = require('electron');
var win;
var mainApp = new app_1.App();
const Shutdown = (accounts) => {
    mainApp.Close(accounts);
};
exports.Shutdown = Shutdown;
var ipcSend = function (event, data) {
    var _a;
    (_a = win === null || win === void 0 ? void 0 : win.webContents) === null || _a === void 0 ? void 0 : _a.send(event, data);
};
exports.ipcSend = ipcSend;
class GuiMsgBox {
    constructor() {
        this.promptMessageMap = new Map();
        this.confirmMessageMap = new Map();
        this.alertMessageMap = new Map();
        this.notifyMessageMap = new Map();
    }
    prompt(prop) {
        var id = SyncUtil_1.SyncUtil.Unique();
        this.promptMessageMap.set(id, Object.assign({ id: id }, prop));
        exports.ipcSend('gui-prompt-box', this.makeJsonable(this.promptMessageMap.get(id)));
    }
    confirm(prop) {
        var id = SyncUtil_1.SyncUtil.Unique();
        this.confirmMessageMap.set(id, Object.assign({ id: id }, prop));
        exports.ipcSend('gui-confirm-box', this.makeJsonable(this.confirmMessageMap.get(id)));
    }
    alert(prop) {
        var id = SyncUtil_1.SyncUtil.Unique();
        this.alertMessageMap.set(id, Object.assign({ id: id }, prop));
        exports.ipcSend('gui-alert-box', this.makeJsonable(this.alertMessageMap.get(id)));
    }
    notify(prop) {
        var id = SyncUtil_1.SyncUtil.Unique();
        this.notifyMessageMap.set(id, Object.assign({ id: id }, prop));
        exports.ipcSend('gui-notify-box', this.makeJsonable(this.notifyMessageMap.get(id)));
        return id;
    }
    feedback(id, result) {
        var _a, _b, _c, _d, _e, _f, _g, _h;
        if (result.type === 'prompt') {
            switch (result.action) {
                case 'input':
                    {
                        (_a = this.promptMessageMap.get(id)) === null || _a === void 0 ? void 0 : _a.input(result.value);
                    }
                    break;
                case 'cancel':
                    {
                        (_b = this.promptMessageMap.get(id)) === null || _b === void 0 ? void 0 : _b.cancel();
                    }
                    break;
            }
            this.promptMessageMap.delete(id);
        }
        else if (result.type === 'confirm') {
            switch (result.action) {
                case 'yes':
                    {
                        (_c = this.confirmMessageMap.get(id)) === null || _c === void 0 ? void 0 : _c.yes(result.value);
                    }
                    break;
                case 'no':
                    {
                        (_d = this.confirmMessageMap.get(id)) === null || _d === void 0 ? void 0 : _d.no();
                    }
                    break;
            }
            this.confirmMessageMap.delete(id);
        }
        else if (result.type === 'alert') {
            (_f = (_e = this.alertMessageMap.get(id)) === null || _e === void 0 ? void 0 : _e.close) === null || _f === void 0 ? void 0 : _f.call(_e);
            this.alertMessageMap.delete(id);
        }
        else if (result.type === 'notify') {
            (_h = (_g = this.notifyMessageMap.get(id)) === null || _g === void 0 ? void 0 : _g.close) === null || _h === void 0 ? void 0 : _h.call(_g);
            this.notifyMessageMap.delete(id);
        }
    }
    makeJsonable(obj) {
        var jsobj = Object.assign({}, obj);
        for (var n in jsobj) {
            if (typeof jsobj[n] === 'function') {
                jsobj[n] = undefined;
            }
        }
        return jsobj;
    }
}
var guiMsgBox = new GuiMsgBox();
exports.default = guiMsgBox;
function GetSyncService() {
    return mainApp.GetSyncService();
}
exports.GetSyncService = GetSyncService;
;
Main();
function Main() {
    //The easiest way to handle these arguments and stop your app launching multiple times
    //during install is to use electron - squirrel - startup as one of the first things your app does
    if (require('electron-squirrel-startup')) { //come back to verify this!!!
        app.quit();
        return;
    }
    function createWindow() {
        win = new BrowserWindow({
            width: 1300,
            height: 750,
            title: `Sync TMX v${Config_1.Config.VERSION}`,
            webPreferences: {
                nodeIntegration: true
            }
        });
        // and load the index.html of the app. 
        win.loadFile(`${__dirname}/../index.html`);
        win.removeMenu(); //remove the default menu
        // Open the DevTools. 
        //win.webContents.openDevTools()//UNCOMMENT IN PRODUCTION TO HIDE DEBUGGER VIEW
        //Quit app when main BrowserWindow Instance is closed
        win.on('closed', function () {
            app.quit();
        });
    }
    // This method will be called when the Electron has finished 
    // initialization and is ready to create browser windows. 
    // Some APIs can only be used after this event occurs. 
    app.whenReady().then(createWindow);
    app.on('window-all-closed', () => {
        // On macOS it is common for applications and their menu bar    
        // to stay active until the user quits explicitly with Cmd + Q 
        if (process.platform !== 'darwin') {
            app.quit();
        }
    });
    app.on('activate', () => {
        // On macOS it's common to re-create a window in the app when the 
        // dock icon is clicked and there are no other windows open. 
        if (BrowserWindow.getAllWindows().length === 0) {
            createWindow();
        }
    });
    ipcMain.on('start-sync', function (event, arg) {
        mainApp.Run();
    });
    ipcMain.on('refresh-sync', function (event, arg) {
        mainApp.GetSyncService().RevalidateSyncAll();
    });
    ipcMain.on('gui-msg-box-feedback', function (event, obj) {
        guiMsgBox.feedback(obj.id, obj);
    });
    ipcMain.on('ensure-install-uptodate', function (event, obj) {
        mainApp.GetSyncService().EnsureInstallUptodate();
    });
    ipcMain.on('pair-accounts', function (event, arg) {
        var service = mainApp.GetSyncService();
        var accountA = service.getTraderAccount(arg[0].broker, arg[0].account_number);
        var accountB = service.getTraderAccount(arg[1].broker, arg[1].account_number);
        service.PairTraderAccountWith(accountA, accountB, true);
    });
    ipcMain.on('remove-pairing', function (event, pairs) {
        for (let pair of pairs) {
            var service = mainApp.GetSyncService();
            var accountA = service.getTraderAccount(pair[0].broker, pair[0].account_number);
            var accountB = service.getTraderAccount(pair[1].broker, pair[1].account_number);
            if (accountA.Peer() != null
                && accountA.Peer().Broker() == accountB.Broker()
                && accountA.Peer().AccountNumber() == accountB.AccountNumber()) {
                service.RemovePairing(accountA);
            }
            else {
                exports.ipcSend('was-not-paired', `[${accountA.Broker()}, ${accountA.AccountNumber()}] was not paired with [${accountB.Broker()}, ${accountB.AccountNumber()}]`);
            }
        }
    });
    ipcMain.on('place-order', function (event, obj) {
        var service = mainApp.GetSyncService();
        var account_buy = service.getTraderAccount(obj.account_buy.broker, obj.account_buy.account_number);
        var account_a = service.getTraderAccount(obj.account_a.broker, obj.account_a.account_number);
        var account_b = service.getTraderAccount(obj.account_b.broker, obj.account_b.account_number);
        service.SyncPlaceOrders(account_buy, account_a, account_b, obj.symbol, obj.lot_size_a, obj.lot_size_b, parseFloat(obj.trade_split_count), parseFloat(obj.max_percent_diff_in_account_balances));
    });
    ipcMain.on('place-order-trigger', function (event, obj) {
        var service = mainApp.GetSyncService();
        var account_buy = service.getTraderAccount(obj.account_buy.broker, obj.account_buy.account_number);
        var account_a = service.getTraderAccount(obj.account_a.broker, obj.account_a.account_number);
        var account_b = service.getTraderAccount(obj.account_b.broker, obj.account_b.account_number);
        var trigger = new PlaceOrderTrigger_1.PlaceOrderTrigger();
        trigger.buy_trader = account_buy;
        trigger.buy_lot_size = account_buy.StrID() == account_a.StrID() ? obj.lot_size_a : obj.lot_size_b;
        trigger.sell_lot_size = account_buy.StrID() == account_a.StrID() ? obj.lot_size_b : obj.lot_size_a;
        trigger.pair_id = account_buy.PairID();
        trigger.price = obj.trigger_price;
        trigger.pivot_price = account_buy.ChartMarketPrice();
        trigger.type = obj.trigger_type;
        trigger.symbol = obj.symbol;
        trigger.trade_split_count = parseFloat(obj.trade_split_count);
        trigger.max_percent_diff_in_account_balances = parseFloat(obj.max_percent_diff_in_account_balances);
        `<option value="Instant now">Instant now</option>
                            <option value="Instant when both accounts have credit bonuses">Instant when both accounts have credit bonuses</option>
                            <option value="Pending at price">Pending at price</option>
                            <option value="Pending at price when both accounts have credit bonuses">Pending at price when both accounts have credit bonuses</option>
`;
        if (trigger.type == Constants_1.Constants.Pending_at_price
            || trigger.type == Constants_1.Constants.Pending_at_price_when_both_accounts_have_credit_bonuses) {
            if (obj.trigger_price > trigger.pivot_price) {
                trigger.remark = `The order will be execute immediately when market price gets to or goes above ${obj.trigger_price}`;
            }
            else {
                trigger.remark = `The order will be execute immediately when market price gets to or goes below ${obj.trigger_price}`;
            }
        }
        if (trigger.type == Constants_1.Constants.Pending_at_price_when_both_accounts_have_credit_bonuses) {
            trigger.remark += ` and credit bonuses are available for both accounts`;
        }
        if (trigger.type == Constants_1.Constants.Instant_when_both_accounts_have_credit_bonuses) {
            trigger.remark = `The order will be execute immediately when credit bonuses are available for both accounts`;
        }
        service.AddPlaceOrderTrigger(trigger);
    });
    ipcMain.on('cancel-place-order-trigger', function (event, uuid) {
        var service = mainApp.GetSyncService();
        service.CancelPlaceOrderTrigger(uuid);
    });
    ipcMain.on('save-trade-properties', function (event, obj) {
        var service = mainApp.GetSyncService();
        for (var i = 0; i < obj.account_list.length; i++) {
            var account = service.getTraderAccount(obj.account_list[i].broker, obj.account_list[i].account_number);
            account.SendTradeProperties(obj.config[Constants_1.Constants.TRADE_PROPERTIES]);
        }
        SyncUtil_1.SyncUtil.SaveAppConfig(obj.config, function (success) {
            if (success) {
                exports.ipcSend('trade-properties-save-success', obj.config);
            }
            else {
                exports.ipcSend('trade-properties-save-fail', false);
            }
        });
    });
    ipcMain.on('save-symbols-config', function (event, obj) {
        SyncUtil_1.SyncUtil.SaveAppConfig(obj, function (success) {
            if (success) {
                var service = mainApp.GetSyncService();
                var account_list = service.getAccounts();
                for (var i = 0; i < account_list.length; i++) {
                    account_list[i].ApplySafetySpreadConfig();
                    //update target
                    account_list[i].EnsureTakeProfitIsSet(service.GetSyncedOrders(account_list[i]));
                }
                exports.ipcSend('symbols-config-save-success', obj);
            }
            else {
                exports.ipcSend('symbols-config-save-fail', false);
            }
        });
    });
    ipcMain.on('get-app-config', function (event, defaultConfigObj) {
        var configObj = SyncUtil_1.SyncUtil.MapToObject(SyncUtil_1.SyncUtil.AppConfigMap);
        for (var n in defaultConfigObj) {
            //set to default if the property is not present in the saved config
            if (!(n in configObj)) {
                configObj[n] = defaultConfigObj[n];
            }
        }
        //Re-save the config
        SyncUtil_1.SyncUtil.SaveAppConfig(configObj, function (success) {
            if (success) {
                exports.ipcSend('app-config', configObj);
            }
            else {
                exports.ipcSend('app-config-init-fail', false);
            }
        });
    });
    ipcMain.on('save-general-settings', function (event, obj) {
        SyncUtil_1.SyncUtil.SaveAppConfig(obj, function (success) {
            if (success) {
                exports.ipcSend('general-settings-save-success', obj);
            }
            else {
                exports.ipcSend('general-settings-save-fail', false);
            }
        });
    });
    ipcMain.on('save-email-notification-config', function (event, obj) {
        SyncUtil_1.SyncUtil.SaveAppConfig(obj, function (success) {
            if (success) {
                exports.ipcSend('email-notification-config-save-success', obj);
            }
            else {
                exports.ipcSend('email-notification-config-save-fail', false);
            }
        });
    });
    ipcMain.on('verify-email-notification-connection', function (event, obj) {
        mainApp.GetSyncService().GetEmailer().verifyConnection(obj, function (error, success) {
            if (success) {
                exports.ipcSend('email-notification-connection-verify-success', obj);
            }
            else {
                exports.ipcSend('email-notification-connection-verify-fail', error);
            }
        });
    });
    ipcMain.on("compute-lot-stoploss-loss-at-stopout", function (event, obj) {
        var service = mainApp.GetSyncService();
        var account = service.getTraderAccount(obj.broker, obj.account_number);
        var lot_size;
        var stoploss_pips; //same as pips at stopout
        var loss_at_stopout;
        var spread_cost;
        var swap_cost_per_day;
        var crash_balance;
        var is_commission_known;
        var commission;
        if (obj.stoploss_pips > 0) {
            stoploss_pips = obj.stoploss_pips;
            lot_size = account.DetermineLotSizefromPips(obj.stoploss_pips);
            loss_at_stopout = account.DetermineLossAtStopout(obj.position, lot_size);
            swap_cost_per_day = account.CalculateSwapPerDay(obj.position, lot_size);
            commission = account.CalculateCommision(lot_size);
        }
        else if (obj.lot_size > 0) {
            lot_size = obj.lot_size;
            stoploss_pips = account.DeterminePipsMoveAtStopout(obj.position, obj.lot_size);
            loss_at_stopout = account.DetermineLossAtStopout(obj.position, obj.lot_size);
            swap_cost_per_day = account.CalculateSwapPerDay(obj.position, obj.lot_size);
            commission = account.CalculateCommision(obj.lot_size);
        }
        is_commission_known = account.IsCommisionKnown();
        spread_cost = account.CalculateSpreadCost(lot_size);
        crash_balance = parseFloat((account.AccountBalance() - loss_at_stopout).toFixed(2));
        var result = {
            account: account.CopyAttr(),
            lot_size: lot_size || '',
            stoploss_pips: stoploss_pips || '',
            loss_at_stopout: loss_at_stopout || 0,
            swap_cost_per_day: swap_cost_per_day || 0,
            spread_cost: spread_cost || 0,
            crash_balance: crash_balance || 0,
            commission: commission || 0,
            is_commission_known: is_commission_known,
        };
        exports.ipcSend('lot-stoploss-loss-at-stopout-result', result);
    });
    ipcMain.on('accept-warning-place-order', function (event, uuid) {
        var service = mainApp.GetSyncService();
        service.handlePendingAccountOrderPlacement(uuid, true);
    });
    ipcMain.on('reject-warning-place-order', function (event, uuid) {
        var service = mainApp.GetSyncService();
        service.handlePendingAccountOrderPlacement(uuid, false);
    });
}
//# sourceMappingURL=main.js.map