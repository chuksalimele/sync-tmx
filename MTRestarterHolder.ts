interface MTRestarterHolder{
    broker: string;
    account_number: string;
    signaled_closed_time:number;
    next_restart_time:number;
    restart_attempts:number;
    terminal_exe:string;
    errcallback: Function;
}