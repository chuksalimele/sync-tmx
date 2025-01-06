"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Config = void 0;
var os = require('os');
var path = require('path');
class Config {
}
exports.Config = Config;
Config.VERSION = '15.0.0';
Config.APP_HOME_DIRECTORY = `${os.homedir()}/.stmx`;
Config.HOST = "localhost";
Config.PORT = "4000";
Config.SYNC_LOG_FILE = Config.APP_HOME_DIRECTORY + "/log/sync_log.sync";
Config.APP_CONFIG_FILE = Config.APP_HOME_DIRECTORY + "/config.conf";
Config.TERMINAL_ICON_NAME = "terminal";
Config.TERMINAL_ICON_TYPE = ".ico";
Config.USER_DATA_DIR = process.env.APPDATA || (process.platform == 'darwin' ? process.env.HOME + '/Library/Preferences' : process.env.HOME + "/.local/share");
Config.MT_ALL_TERMINALS_DATA_ROOT = Config.USER_DATA_DIR + path.sep + 'MetaQuotes' + path.sep + 'Terminal';
Config.MT4_EA_EXEC_FILE_SIMPLE_NAME = "SyncClientX.ex4";
Config.MT5_EA_EXEC_FILE_SIMPLE_NAME = "SyncClientX5.ex5";
Config.MT4_EA_DLL_FILE_SIMPLE_NAME = "SyncTradeConnector.dll";
Config.MT5_EA_DLL_FILE_SIMPLE_NAME = "SyncTradeConnector5.dll";
Config.STMX_UPTODATE_EX4 = Config.APP_HOME_DIRECTORY + "/uptodate/" + Config.MT4_EA_EXEC_FILE_SIMPLE_NAME;
Config.STMX_UPTODATE_EX5 = Config.APP_HOME_DIRECTORY + "/uptodate/" + Config.MT5_EA_EXEC_FILE_SIMPLE_NAME;
Config.STMX_UPTODATE_MT4_DLL = Config.APP_HOME_DIRECTORY + "/uptodate/" + Config.MT4_EA_DLL_FILE_SIMPLE_NAME;
Config.STMX_UPTODATE_MT5_DLL = Config.APP_HOME_DIRECTORY + "/uptodate/" + Config.MT5_EA_DLL_FILE_SIMPLE_NAME;
Config.STMX_UPTODATE_METADATA = Config.APP_HOME_DIRECTORY + "/uptodate/metadata.json";
Config.STMX_LOG_INFO = Config.APP_HOME_DIRECTORY + "/log/info.log";
Config.STMX_LOG_ERROR = Config.APP_HOME_DIRECTORY + "/log/error.log";
Config.STMX_LOG_COMBINE = Config.APP_HOME_DIRECTORY + "/log/combine.log";
//# sourceMappingURL=Config.js.map