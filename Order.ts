
import { SyncUtil } from "./SyncUtil";


export class Order{

    public ticket: number;
    public peer_ticket: number = -1;//greater than -1 if it is synced
    public group_id: string; // trade split group id
    public group_order_count: number = 0;
    public position: string;
    public symbol: string;
    public raw_symbol: string;
    public open_price: number = 0;
    public open_time: number = 0;
    public stoploss: number = 0;
    public target: number = 0;
    public close_price: number = 0;
    public close_time: number = 0;
    public lot_size: number = 0;
    public point: number = 0;
    public digits: number = 0;
    public stoploss_change_time: number = 0;
    public target_change_time: number = 0;
    public copy_signal_time: number = 0;
    public close_signal_time: number = 0;
    public modify_target_signal_time: number = 0;
    public modify_stoploss_signal_time: number = 0;
    public copy_execution_time: number = 0;
    public close_execution_time: number = 0;
    public modify_target_execution_time: number = 0;
    public modify_stoploss_execution_time: number = 0;
    public force: boolean = false;//force close or a forced operation
    public reason: string = '';// reason for the last forced operation
    public is_lock_in_profit = false;
    public spread = 0;

    private default_spread: number = 0;
    private safety_spread: number = 0;//do not call this directly    
    private is_sync_copying: boolean = false;
    private is_closing: boolean = false;
    private is_sync_modifying_target: boolean = false;
    private is_sync_modifying_stoploss: boolean = false;
    private is_copyable: boolean = true;    
    private stoploss_changed = false;
    private is_safety_spread_applied = false;


    constructor(bit_order: BitOrder) {
        this.ticket = bit_order.ticket;
        this.group_id = bit_order.group_id;
        this.group_order_count = bit_order.group_order_count        
    }

    public snap(): BitOrder{
        return {
            ticket: this.ticket,
            group_id: this.group_id,
            group_order_count: this.group_order_count
        };
    }

    public GropuId(): string { return this.group_id; }
    
    public GroupOrderCount(){return this.group_order_count;}

    public IsOpen(): boolean { return this.open_time > 0 && this.close_time == 0; }

    public IsClosed(): boolean { return this.close_time > 0 };

    public SyncCopying(copying: boolean) { return this.is_sync_copying = copying };    

    public SetStoplossChanged(stoploss_changed: boolean){this.stoploss_changed = stoploss_changed}

    /**
     * Sync or own closing
     * @param closing
     */
    public Closing(closing: boolean) { return this.is_closing = closing };

    public SyncModifyingTarget(modifying_target: boolean) { return this.is_sync_modifying_target = modifying_target };   

    public SyncModifyingStoploss(modifying_stoploss: boolean) { return this.is_sync_modifying_stoploss = modifying_stoploss };   

    public IsSyncCopying(): boolean { return this.is_sync_copying };
 
    /**
     * Sync or own closing
     */
    public IsClosing(): boolean { return this.is_closing };

    public IsSyncModifyingTarget(): boolean { return this.is_sync_modifying_target };

    public IsSyncModifyingStoploss(): boolean { return this.is_sync_modifying_stoploss };

    public SetCopyable(copyable: boolean) { this.is_copyable = copyable; }

    public IsCopyable(): boolean { return this.is_copyable; };

    public IsLockInProfit(): boolean { return this.is_lock_in_profit; };

    public IsStoplossChanged(): boolean{return this.stoploss_changed}

    SetGroupId(trade_split_group_id: string) {
        this.group_id = trade_split_group_id;
      }

    SetGroupOderCount(group_order_count: number){
        this.group_order_count = group_order_count;
    }   

    public Digits(): number{
        return this.digits;
    }

    public SetSafetySpreadInUse(spread: number){
      this.safety_spread = spread;
      this.spread = this.safety_spread; //important
    }
    
    public SafetySpreadInUse(): number{
        return this.safety_spread;
    }
    
    public IsSafetySpreadApplied(): boolean{
        return this.is_safety_spread_applied;
    }
    

    public SetSafetySpreadApplied(applied: boolean){
         this.is_safety_spread_applied = applied;
    }

}