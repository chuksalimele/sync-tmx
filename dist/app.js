'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
exports.App = exports.google = exports.readline = exports.mkdirp = exports.os = exports.path = exports.fs = exports.ipcMain = void 0;
const main_1 = require("./main");
const SyncService_1 = require("./SyncService");
const TraderAccount_1 = require("./TraderAccount");
const Config_1 = require("./Config");
var net = require('net');
exports.ipcMain = require('electron').ipcMain;
exports.fs = require("fs");
exports.path = require('path');
exports.os = require('os');
exports.mkdirp = require('mkdirp');
exports.readline = require('readline');
exports.google = require('googleapis').google;
class App {
    constructor() {
        this.service = new SyncService_1.SyncService();
        this.server = null;
        this.isStop = false;
    }
    connectionListener(socket) {
        this.service.AddClient(new TraderAccount_1.TraderAccount(socket));
    }
    GetSyncService() {
        return this.service;
    }
    Run() {
        this.service.Start();
        this.server = net.createServer(this.connectionListener.bind(this));
        this.server.on('close', this.OnClose.bind(this));
        try {
            var listenFunc = () => {
                //console.log('Stream server pipe listening on ' + Config.PIPE_PATH);//deprecated
                //console.log(`Server listening on ${Config.HOST}:${Config.PORT}`);
            };
            //this.server.listen(Config.PIPE_PATH, listenFunc);//Deprecated
            this.server.listen(Config_1.Config.PORT, Config_1.Config.HOST, listenFunc);
            main_1.ipcSend('sync-running', {
                version: Config_1.Config.VERSION
            });
            setTimeout(() => {
                this.GetSyncService().EnsureInstallUptodate(true); //finalize installation if not
            }, 500);
        }
        catch (error) {
            console.log(error);
        }
    }
    Close(accounts) {
        this.isStop = true;
        this.server.close();
        try {
            for (var account of accounts) {
                account.Close();
            }
        }
        catch (error) {
            console.log(error);
        }
    }
    OnClose() {
        //console.log('Stream server pipe closed');
        main_1.ipcSend('sync-close', true);
        if (!this.isStop) { // only restart if we did not intentionally stop the server
            setTimeout(function () {
                //console.log('Stream server pipe restarting...');
                main_1.ipcSend('sync-restart', true);
            }, 1000);
        }
    }
}
exports.App = App;
//# sourceMappingURL=app.js.map