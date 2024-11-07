
const fs = require('fs');
var path = require('path');
const readline = require('readline');
const crypto = require('crypto');

import { ECDH } from "crypto";
import { clouderrorreporting } from "googleapis/build/src/apis/clouderrorreporting";
import { Config } from "./Config";
import guiMsgBox, { GetSyncService, ipcSend } from "./main";
import { SyncUtil } from "./SyncUtil";
import { TraderAccount } from "./TraderAccount";
import logger from "./Logger";




export class InstallX {
    
    private installationInProgress : boolean = false;
    private EX4_checksum: string = '';
    private EX5_checksum: string = '';
    private DLL4_checksum: string = '';
    private DLL5_checksum: string = '';

    private metadataJson:any = null;
    
    private disconnectedList : Array<TraderAccount> = [];

    constructor(){
        this.EX4_checksum = this.FileChecksum(Config.STMX_UPTODATE_EX4);
        this.EX5_checksum = this.FileChecksum(Config.STMX_UPTODATE_EX5);
        this.DLL4_checksum = this.FileChecksum(Config.STMX_UPTODATE_MT4_DLL);
        this.DLL5_checksum = this.FileChecksum(Config.STMX_UPTODATE_MT4_DLL);

        try {
            var metadata = fs.readFileSync(Config.STMX_UPTODATE_METADATA);
            this.metadataJson  = JSON.parse(metadata);
        } catch (error) {
            //do nothing
        }
    }

    private FileChecksum(file: string, completion: TaskCompletion = null){
        var checksum = ''
        try {

            if(!completion){
                var data = fs.readFileSync(file);
                checksum = this.GenerateChecksum(data);     
            }else{
                fs.readFile(file, (err, data)=>{
                    if(err){
                        completion.OnComplete({error:err})
                        return;
                    }
                    checksum = this.GenerateChecksum(data);                    
                    completion.OnComplete({success:"Successful", value:checksum})                    
                })
            }
                   
        } catch (error) {
            logger.error(error.message);
            console.log(error);
            throw error;
        }

        return checksum;
    }

    private formatDisconnectWarning():string{

        var strea = 'EA';
        var strwere = 'was';
        var stracc = 'account';

        if(this.disconnectedList.length === 0){
            return '';
        }else if(this.disconnectedList.length > 1){
             strea = 'EAs';
             strwere = 'were';
             stracc = 'accounts';
        }

        var format = `<br><br><p>ATTENTION:</p><p>${strea} of the following ${stracc} ${strwere} forcibly removed during this operation.</p>`;

        var count = 0;
        for (const account of this.disconnectedList) {
            count++;
            format += `<p>${count}. ${account.Broker()},  <strong>${account.AccountNumber()}</strong></p>`;
        }

        format += `<p>Kindly relaunch the ${strea} to continue.</p>`;

        return format;
    }

    private AddDisconnected(account: TraderAccount){

        var index = this.disconnectedList.findIndex((acc: TraderAccount) => acc.StrID() === account.StrID())
        if(index == -1){
            this.disconnectedList.push(account);
        }        
    }

    /**
     * We want to make sure that all EAs are removed before certain operations. 
     * This method is to ensure all EAs are removed.
     * 
     * @param callback 
     */
    private waitAllAccountsDisconnect(callback: Function){
        
        var accounts:Array<TraderAccount> = GetSyncService().getAccounts();          

        accounts.forEach(account => {            
            account.sendEACommand('reload_ea_ongoing_installation', {immediate : true});  //send command to forcibly remove the EA since loaded DLL will cause installation to fail              
            this.AddDisconnected(account);            
        });

        SyncUtil.AsyncWaitWhile(()=>{
            callback();
        },()=>GetSyncService().getAccounts().length > 0)//wait till all the EAs are removed

    }
    
    private GenerateChecksum(str:string, algorithm :string = 'md5', encoding:string = 'hex') {
        return crypto
            .createHash(algorithm)
            .update(str, 'utf8')
            .digest(encoding);
    }

    public EnsureInstallUptodate(finalize_installations: boolean = false){

        const C_ALERT = "ALERT";
        const C_NOTIFY = "NOTIFY";
        var feedback_type = C_ALERT;

        var accounts:Array<TraderAccount> = GetSyncService().getAccounts();          
        
        var that = this;

        var completion : TaskCompletion = {
            OnComplete: (response: any)=>{
                that.installationInProgress = false;
                var title = response.error ?
                            "Error" : response.success ?
                             response.success : "Cancelled";

                var value = response.error ?
                             response.error : response.success ?
                             response.value: response.cancel;

                if(feedback_type == C_ALERT){
                    guiMsgBox.alert({
                        title: title,
                        message: `<strong style="font-size:16px;">${value}</strong>` + that.formatDisconnectWarning(),
                        close: ()=>{                        
                        }
                    })
                    
                }else if(feedback_type == C_NOTIFY){
                    guiMsgBox.notify({
                        message:value + that.formatDisconnectWarning(),
                        type:'stm-notify',
                        duration: 10, 
                        close:()=>{                                    
                        }
                    })
                }
                
            }
        }


        var doInstall= () =>{

            if(this.installationInProgress){
                completion.OnComplete({cancel:'Operation already in progress.'})
                return;
            }
    
            this.installationInProgress = true;        
            
            this.disconnectedList = [];

            this.waitAllAccountsDisconnect(() => {
                this.EnsureInstallUptodate0(completion)
            });
        }

        if(finalize_installations && !this.metadataJson){// first time startup 
            feedback_type = C_ALERT;                
            guiMsgBox.alert({//TODO - USE BUSY LOADING AND BLOCK GUI UNTIL DONE
                    title: "Finalizing Installation",
                    message:'<p>We are finalizing the installations.</p>'
                            +"<p><strong>Please note that in order to finish this installation all running EAs wll be forcibly removed.</strong></p>"
                            +"<p>So, kindly relaunch any previous running EA when this process is done.</p>",
                    close:()=>{       
                        doInstall();                               
                    }
            })                
            
        }else if(!finalize_installations && accounts.length > 0 ){ //some accounts are connected

            var msg = '<p>In order to run updates, all running EAs will be forcibly removed.?</p>'
                         +'<p>Do you want to procceed?.</p>';

            guiMsgBox.confirm({
                title:'Confirm',
                message: msg,
                yes:()=>{
                    feedback_type = C_ALERT;
                    doInstall();
                },
                no:()=>{
                  //do nothing - just close confirm dialog box
                }
              })
            
        }else if(!finalize_installations && accounts.length == 0 ){
            feedback_type = C_NOTIFY;
            doInstall();            
        }
    }

    private EnsureInstallUptodate0(completion: TaskCompletion){        

        SyncUtil.checkFileExists(Config.STMX_UPTODATE_METADATA)
        .then((exists =>{
            if(exists){
                this.GetExpectedInstalledFileNames(completion);
                return;
            }

            //At this point the file does not exist so create it

            
            //according to doc - Open file for reading and writing.
            //The file is created(if it does not exist) or truncated(if it exists).
            //So since we known that at this point it does not we are not bothered about the truncation

            fs.open(Config.STMX_UPTODATE_METADATA, "w+",(err, result)=>{
                if(err){
                    completion.OnComplete({error:`Could not create Installations Metadata. Failed with error [${err}]`})
                    return;
                }
                this.GetExpectedInstalledFileNames(completion);
            });


        }))
    }

    private FinalizeInstallationUpdate(filenames, completion: TaskCompletion, message: string=null){

        var data = JSON.stringify(this.GenerateMeataJson(filenames, true));

        //overwrite the file content
        fs.writeFile(
            Config.STMX_UPTODATE_METADATA,
            data,
            { encoding: "utf8", flag: "w" },
             (err) => {
                if (err) {
                    completion.OnComplete({error:`Could not finalize installation update - With error [${err}]`});   
                }else{           
                    this.metadataJson = data;         
                    completion.OnComplete({success:'Success',
                                         value: !message? "Successfully completed all installations.":message});
                }

            }
        );
    }


    private GetExpectedInstalledFileNames(completion: TaskCompletion){
        
        SyncUtil.GetEAPaths(Config.MT_ALL_TERMINALS_DATA_ROOT, ((f_err, filenames)=>{
            this.ValidateFileCheckSum(filenames, completion);
        }));
    }

    private GenerateMeataJson(filenames: Array<string>, include_checksum: boolean = false){
        var jsonMeta: any = {};
        for (const name of filenames) {
            var checksum = ''
            if(include_checksum){
                if(name.endsWith('.ex4')){
                    checksum = this.EX4_checksum;
                }else if(name.endsWith('.ex5')){
                    checksum = this.EX5_checksum;
                }else if(name.endsWith('.dll')){
                    checksum = this.DLL4_checksum;
                }else if(name.endsWith('5.dll')){
                    checksum = this.DLL5_checksum;
                }
            }
            jsonMeta[name]=checksum;
        }        

        return jsonMeta;
    }

    tryCopy(from, to, callback){

        var trialCount = 0;
        var MAX_TRIAL = 10;
        
        var midwareFunc = (err, result) => {            
            trialCount++
            if(err && err.code === 'EBUSY' && trialCount < MAX_TRIAL){                                                       
                setTimeout(()=>{
                    this.waitAllAccountsDisconnect(doTrial);
                }, 500);                
            }else{
                callback.call(this, err, result);
            }                              
        }

        var doTrial = ()=>{
            fs.copyFile(from, to, midwareFunc);
        }

        doTrial();        
    }

    private copyFileToOwnDesc(file, callback:Function){

        this.waitAllAccountsDisconnect(()=>{
            if(file.endsWith('.ex4')){
                this.tryCopy(Config.STMX_UPTODATE_EX4, file, callback);
            }else if(file.endsWith('.ex5')){
                this.tryCopy(Config.STMX_UPTODATE_EX5, file, callback);
            }else if(file.endsWith('.dll') && !file.endsWith('5.dll')){                
                this.tryCopy(Config.STMX_UPTODATE_MT4_DLL, file, callback);
            }else if(file.endsWith('.dll') && file.endsWith('5.dll')){                
                this.tryCopy(Config.STMX_UPTODATE_MT5_DLL, file, callback);
            }
        })        
    }

    private ValidateFileCheckSum(filenames: Array<string>, completion: TaskCompletion){

        var done = 0;
        var uptodate_count = 0;
        var errors  = [];
        var that = this;

        var checkDone  = () =>{
                    
                if(done < filenames.length){
                    return;
                }

                //At this point operation is done

                if(uptodate_count == filenames.length){
                    this.FinalizeInstallationUpdate(filenames, completion, "All installations are uptodate.");
                }else if(errors.length == 0){
                    this.FinalizeInstallationUpdate(filenames, completion);
                }else{//have error(s)
                    completion.OnComplete({error:errors.join('\n')});
                }

          }

          
        var doneFunc = (err=null, data=null)=>{
                done++;
                if(err){
                    var errMsg = err;
                    if(err.code === 'EBUSY'){
                        errMsg = "<p>Could not complete update on existing installation due to file access denied."
                        +" Possibly cause by an EA still loaded or not completely unloaded</p>"
                        +"<br><p>HINT:<br> Remove all EAs or close all MetaTrader terminals and try again.</p>";
                    }

                    errors.push(errMsg);
                }
                checkDone();
          } 
        

        filenames.forEach((name)=>{

            var onChecksum = {
                OnComplete : (response)=>{                                      

                  if(response.error){
                    doneFunc(response.error);
                  }

                  if(response.success){
                    
                    var checksum = response.value;

                    if(checksum != that.EX4_checksum 
                        && checksum != that.EX5_checksum 
                        && checksum != that.DLL4_checksum 
                        && checksum != that.DLL5_checksum){

                        that.copyFileToOwnDesc(name, doneFunc);
                    }else{
                        uptodate_count++;
                        doneFunc(null);
                    }
                  }                       

                }
              }
            


            SyncUtil.checkFileExists(name)
            .then((exists =>{
                if(exists){
                    this.FileChecksum(name, onChecksum);
                }else{
                    this.copyFileToOwnDesc(name, doneFunc);
                }    
            }))


        })

    }

}




