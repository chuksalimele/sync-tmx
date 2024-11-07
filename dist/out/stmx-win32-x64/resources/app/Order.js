"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Order = void 0;
class Order {
    constructor(bit_order) {
        this.peer_ticket = -1; //greater than -1 if it is synced
        this.group_order_count = 0;
        this.open_price = 0;
        this.open_time = 0;
        this.stoploss = 0;
        this.target = 0;
        this.close_price = 0;
        this.close_time = 0;
        this.lot_size = 0;
        this.point = 0;
        this.digits = 0;
        this.stoploss_change_time = 0;
        this.target_change_time = 0;
        this.copy_signal_time = 0;
        this.close_signal_time = 0;
        this.modify_target_signal_time = 0;
        this.modify_stoploss_signal_time = 0;
        this.copy_execution_time = 0;
        this.close_execution_time = 0;
        this.modify_target_execution_time = 0;
        this.modify_stoploss_execution_time = 0;
        this.force = false; //force close or a forced operation
        this.reason = ''; // reason for the last forced operation
        this.is_lock_in_profit = false;
        this.spread = 0;
        this.default_spread = 0;
        this.safety_spread = 0; //do not call this directly    
        this.is_sync_copying = false;
        this.is_closing = false;
        this.is_sync_modifying_target = false;
        this.is_sync_modifying_stoploss = false;
        this.is_copyable = true;
        this.stoploss_changed = false;
        this.is_safety_spread_applied = false;
        this.ticket = bit_order.ticket;
        this.group_id = bit_order.group_id;
        this.group_order_count = bit_order.group_order_count;
    }
    snap() {
        return {
            ticket: this.ticket,
            group_id: this.group_id,
            group_order_count: this.group_order_count
        };
    }
    GropuId() { return this.group_id; }
    GroupOrderCount() { return this.group_order_count; }
    IsOpen() { return this.open_time > 0 && this.close_time == 0; }
    IsClosed() { return this.close_time > 0; }
    ;
    SyncCopying(copying) { return this.is_sync_copying = copying; }
    ;
    SetStoplossChanged(stoploss_changed) { this.stoploss_changed = stoploss_changed; }
    /**
     * Sync or own closing
     * @param closing
     */
    Closing(closing) { return this.is_closing = closing; }
    ;
    SyncModifyingTarget(modifying_target) { return this.is_sync_modifying_target = modifying_target; }
    ;
    SyncModifyingStoploss(modifying_stoploss) { return this.is_sync_modifying_stoploss = modifying_stoploss; }
    ;
    IsSyncCopying() { return this.is_sync_copying; }
    ;
    /**
     * Sync or own closing
     */
    IsClosing() { return this.is_closing; }
    ;
    IsSyncModifyingTarget() { return this.is_sync_modifying_target; }
    ;
    IsSyncModifyingStoploss() { return this.is_sync_modifying_stoploss; }
    ;
    SetCopyable(copyable) { this.is_copyable = copyable; }
    IsCopyable() { return this.is_copyable; }
    ;
    IsLockInProfit() { return this.is_lock_in_profit; }
    ;
    IsStoplossChanged() { return this.stoploss_changed; }
    SetGroupId(trade_split_group_id) {
        this.group_id = trade_split_group_id;
    }
    SetGroupOderCount(group_order_count) {
        this.group_order_count = group_order_count;
    }
    Digits() {
        return this.digits;
    }
    SetSafetySpreadInUse(spread) {
        this.safety_spread = spread;
        this.spread = this.safety_spread; //important
    }
    SafetySpreadInUse() {
        return this.safety_spread;
    }
    IsSafetySpreadApplied() {
        return this.is_safety_spread_applied;
    }
    SetSafetySpreadApplied(applied) {
        this.is_safety_spread_applied = applied;
    }
}
exports.Order = Order;
//# sourceMappingURL=Order.js.map