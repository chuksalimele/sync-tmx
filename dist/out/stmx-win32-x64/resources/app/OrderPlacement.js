"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.OrderPlacement = void 0;
const Constants_1 = require("./Constants");
const SyncUtil_1 = require("./SyncUtil");
class OrderPlacement {
    constructor(uuid, symbol, position, lot_size, trade_split_group_id, trade_split_count, is_triggered = false) {
        this.id = SyncUtil_1.SyncUtil.Unique();
        this.trade_split_count = 0;
        this.lot_size = 0;
        this.spread_cost = 0;
        this.required_margin = 0;
        this.state = Constants_1.Constants.IN_PROGRESS;
        this.is_triggered = false;
        this.operation_complete_status = 0;
        this.paired_uuid = uuid;
        this.symbol = symbol;
        this.position = position;
        this.lot_size = lot_size;
        this.trade_split_group_id = trade_split_group_id;
        this.trade_split_count = trade_split_count;
        this.is_triggered = is_triggered;
    }
    SetValidateResult(valid, validationMsg) {
        this.state = valid ? Constants_1.Constants.VALIDATION_SUCCESS : Constants_1.Constants.VALIDATION_FAIL;
    }
    SetResult(ticket) {
        this.state = ticket > -1 ? Constants_1.Constants.SUCCESS : Constants_1.Constants.FAILED;
        this.ticket = ticket;
    }
    SetSpreadCost(spread_cost) {
        this.spread_cost = spread_cost;
    }
    SetRequiredMargin(required_margin) {
        this.required_margin = required_margin;
    }
    SetOperationCompleteStatus(operation_complete) {
        this.operation_complete_status = operation_complete;
    }
    OperationCompleteStatus() {
        return this.operation_complete_status;
    }
}
exports.OrderPlacement = OrderPlacement;
OrderPlacement.COMPLETE_FAIL = 1;
OrderPlacement.COMPLETE_SUCCESS = 2;
//# sourceMappingURL=OrderPlacement.js.map