
export class Constants {
    
    public static readonly TAB: string = "\t";
    public static readonly NEW_LINE: string = "\n";

    public static readonly MAX_COPY_RETRY: number = 3;
    public static readonly MAX_CLOSE_RETRY: number = 3;
    public static readonly MAX_MODIFY_RETRY: number = 3;
    public static readonly MAX_PLACE_ORDER_RETRY: number = 3; 
    
    public static readonly APPROX_ZERO_TOLERANCE: number = 0.000000001;

    public static readonly IN_PROGRESS: number = 0;
    public static readonly SUCCESS: number = 1;
    public static readonly FAILED: number = 2;
    public static readonly VALIDATION_SUCCESS: number = 3;
    public static readonly VALIDATION_FAIL: number = 4;
    
    public static readonly BUY : string = "BUY";
    public static readonly SELL: string = "SELL";

    public static readonly Instant_when_both_accounts_have_credit_bonuses: string = 'Instant when both accounts have credit bonuses';
    public static readonly Pending_at_price: string = 'Pending at price';
    public static readonly Pending_at_price_when_both_accounts_have_credit_bonuses: string = 'Pending at price when both accounts have credit bonuses';

    //errors
    public static readonly ERR_DUPLICATE_EA: string = "DUPLICATE EA";
    public static readonly ERR_TRADE_CONDITION_NOT_CHANGED: string = "no error, trade conditions not changed";
    public static readonly ERR_NO_CHANGES: string = "no changes";
    
    //commands
    public static readonly CMD_DUPLICATE_EA: string = "duplicate_ea";
    public static readonly CMD_CHECK_ENOUGH_MONEY: string = "check_enough_money";
    public static readonly CMD_CHECK_TRADABLE: string = "check_tradable";    
    public static readonly CMD_SHUTDOWN_TERMINAL_FOR_RESTART: string = "shutdown_terminal_for_restart";
    public static readonly CMD_RE_ESTABLISHED_PAIRING: string = "re_established_pairing";
    public static readonly CMD_RE_STARTED_TERMINAL: string = "re_started_terminal";
    public static readonly CMD_PEER_TERMINAL_TO_RESTART: string = "peer_terminal_to_restart";
    public static readonly CMD_PEER_TERMINAL_TO_RESTART_CONFIRM: string = "peer_terminal_to_restart_confirm";
    public static readonly CMD_REPORT_PEER_TERMINAL_TO_RESTART_FAILED: string = "report_peer_terminal_to_restart_failed";
    
    
    public static readonly TRADE_PROPERTIES: string = "trade_properties";

    
}
