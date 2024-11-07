

var os = require('os');
var path = require('path');

export class Config {
    public static readonly VERSION: string = '13.0.0';
    static readonly APP_HOME_DIRECTORY: string = `${os.homedir()}/.stmx`;
    public static readonly HOST: string = "localhost";
    public static readonly PORT: string = "4000";
    public static readonly SYNC_LOG_FILE: string = Config.APP_HOME_DIRECTORY + "/log/sync_log.sync";
    
    
    public static readonly APP_CONFIG_FILE: string = Config.APP_HOME_DIRECTORY + "/config.conf";
    public static readonly TERMINAL_ICON_NAME: string = "terminal";
    public static readonly TERMINAL_ICON_TYPE: string = ".ico";   
    public static readonly USER_DATA_DIR: string =  process.env.APPDATA || (process.platform == 'darwin' ? process.env.HOME + '/Library/Preferences' : process.env.HOME + "/.local/share")
    public static readonly MT_ALL_TERMINALS_DATA_ROOT = Config.USER_DATA_DIR + path.sep +'MetaQuotes' + path.sep + 'Terminal';

    public static readonly MT4_EA_EXEC_FILE_SIMPLE_NAME: string = "SyncClientX.ex4";   
    public static readonly MT5_EA_EXEC_FILE_SIMPLE_NAME: string = "SyncClientX5.ex5";   
    public static readonly MT4_EA_DLL_FILE_SIMPLE_NAME: string = "SyncTradeConnector.dll";
    public static readonly MT5_EA_DLL_FILE_SIMPLE_NAME: string = "SyncTradeConnector5.dll";

    public static readonly STMX_UPTODATE_EX4: string = Config.APP_HOME_DIRECTORY + "/uptodate/"+Config.MT4_EA_EXEC_FILE_SIMPLE_NAME;
    public static readonly STMX_UPTODATE_EX5: string = Config.APP_HOME_DIRECTORY + "/uptodate/"+Config.MT5_EA_EXEC_FILE_SIMPLE_NAME;
    public static readonly STMX_UPTODATE_MT4_DLL: string = Config.APP_HOME_DIRECTORY + "/uptodate/"+Config.MT4_EA_DLL_FILE_SIMPLE_NAME;
    public static readonly STMX_UPTODATE_MT5_DLL: string = Config.APP_HOME_DIRECTORY + "/uptodate/"+Config.MT5_EA_DLL_FILE_SIMPLE_NAME;
    public static readonly STMX_UPTODATE_METADATA: string = Config.APP_HOME_DIRECTORY + "/uptodate/metadata.json";
    
    public static readonly STMX_LOG_INFO: string = Config.APP_HOME_DIRECTORY + "/log/info.log";
    public static readonly STMX_LOG_ERROR: string = Config.APP_HOME_DIRECTORY + "/log/error.log";
    public static readonly STMX_LOG_COMBINE: string = Config.APP_HOME_DIRECTORY + "/log/combine.log";

    /*public static readonly SYMBOLS_MAP_INITIAL_TXT = 
`DJz; US30; WS30; DJ30; WALLSTREET; DOWJONES; DowJones; WallStreet; 

XBRUSD; UKOIL; UKOUSD; BRENT;

XTIUSD; USOIL; USOUSD; WTI;

USDX; DOLLARINDEX; 

VIX; VIXINDEX;`;*/

}
