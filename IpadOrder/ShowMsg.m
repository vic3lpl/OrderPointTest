#import "ShowMsg.h"
#import "ePOS-Print.h"

#define BITCNT_INT  32


@interface ShowMsg()
+ (void)show:(NSString*)msg;
+ (NSString*)getEposResultText:(int)result;
+ (NSString*)getEpsonIoResultText:(int)result;
+ (NSString*)getEposStatusText:(unsigned long)status;
+ (NSString*)getEposBtResultText:(int)result;
@end

@implementation ShowMsg

//show error code(EpsonIo Result)
+ (void)showExceptionEpsonIo:(int)result method:(NSString*)method
{
    NSString *msg = [NSString stringWithFormat:@"%@\n%@\n\n%@\n%@\n",
                     NSLocalizedString(@"methoderr_errcode", @""),
                     [self getEpsonIoResultText:result],
                     NSLocalizedString(@"methoderr_method", @""),
                     method];
    [self show:msg];
}

//show error code(EposPrint/EposBuilder Result)
+ (void)showExceptionEpos:(int)result method:(NSString*)method
{
    NSString *msg = [NSString stringWithFormat:@"%@\n%@\n\n%@\n%@\n",
                     NSLocalizedString(@"methoderr_errcode", @""),
                     [self getEposResultText:result],
                     NSLocalizedString(@"methoderr_method", @""),
                     method];
    [self show:msg];
}

//show error code(EposBluetoothConnection Result)
+ (void)showExceptionEposBt:(int)result method:(NSString*)method
{
    NSString *msg = [NSString stringWithFormat:@"%@\n%@\n\n%@\n%@\n",
                     NSLocalizedString(@"methoderr_errcode", @""),
                     [self getEposBtResultText:result],
                     NSLocalizedString(@"methoderr_method", @""),
                     method];
    [self show:msg];
}

//show error message
+ (void)showError:(NSString*)errMsg
{
    NSString *msg = NSLocalizedString(errMsg, @"");
    [self show:msg];
}

//show printer status(EposPrint.sendData)
+ (void)showStatus:(int)result status:(unsigned long)status battery:(unsigned long)battery
{
    NSString *msg = [NSString stringWithFormat:@"%@\n%@\n\n%@\n%@\n\n%@\n0x%04lX\n",
                     NSLocalizedString(@"statusmsg_result", @""),
                     [self getEposResultText:result],
                     NSLocalizedString(@"statusmsg_status", @""),
                     [self getEposStatusText:status],
                     NSLocalizedString(@"statusmsg_batterystatus", @""),
                     battery];
    [self show:msg];
}

//show printer name
+ (void)showPrinterName:(NSString*)printerName languageName:(NSString*)languageName
{
    NSString *msg = [NSString stringWithFormat:@"%@\n%@\n\n%@\n%@\n",
                     NSLocalizedString(@"namemsg_name", @""),
                     printerName,
                     NSLocalizedString(@"namemsg_language", @""),
                     languageName];
    [self show:msg];
}

//show status change event
+ (void)showStatusChangeEvent:(NSString*)deviceName Status:(unsigned long)status
{
    NSString *msg = [NSString stringWithFormat:@"%@\n%@\n\n%@\n%@\n",
                     NSLocalizedString(@"statusmsg_ipaddress", @""),
                     deviceName,
                     NSLocalizedString(@"statusmsg_status", @""),
                     [self getEposStatusText:status]];
    [self show:msg];
}

+ (void)showBatteryStatusChangeEvent:(NSString*)deviceName Battery:(unsigned long)battery
{
    NSString *msg = [NSString stringWithFormat:@"%@\n%@\n\n%@\n0x%04lX\n",
                     NSLocalizedString(@"statusmsg_ipaddress", @""),
                     deviceName,
                     NSLocalizedString(@"statusmsg_batterystatus", @""),
                     battery];
    [self show:msg];
}

//show alart view
+ (void)show:(NSString*)msg
{
    UIAlertView *alert = [[UIAlertView alloc]
                           initWithTitle:nil
                           message:msg
                           delegate:nil
                           cancelButtonTitle:nil
                           otherButtonTitles:@"OK", nil
                           ];
    [alert show];
    
}

//convert EposPrint/EposBuilder Result to text
+ (NSString*)getEposResultText:(int)result
{
    switch(result){
        case EPOS_OC_SUCCESS:
            return @"SUCCESS";
        case EPOS_OC_ERR_PARAM:
            return @"ERR_PARAM";
        case EPOS_OC_ERR_OPEN:
            return @"ERR_OPEN";
        case EPOS_OC_ERR_CONNECT:
            return @"ERR_CONNECT";
        case EPOS_OC_ERR_TIMEOUT:
            return @"ERR_TIMEOUT";
        case EPOS_OC_ERR_MEMORY:
            return @"ERR_MEMORY";
        case EPOS_OC_ERR_ILLEGAL:
            return @"ERR_ILLEGAL";
        case EPOS_OC_ERR_PROCESSING:
            return @"ERR_PROCESSING";
        case EPOS_OC_ERR_UNSUPPORTED:
            return @"ERR_UNSUPPORTED";
        case EPOS_OC_ERR_OFF_LINE:
            return @"ERR_OFF_LINE";
        case EPOS_OC_ERR_FAILURE:
            return @"ERR_FAILURE";
        default:
            return [NSString stringWithFormat:@"%d", result];
    }
}


//convert EpsonIo Result to text
+ (NSString*)getEpsonIoResultText:(int)result
{
    switch(result){
        case EPSONIO_OC_SUCCESS:
            return @"SUCCESS";
        case EPSONIO_OC_ERR_PARAM:
            return @"ERR_PARAM";
        case EPSONIO_OC_ERR_OPEN:
            return @"ERR_OPEN";
        case EPSONIO_OC_ERR_CONNECT:
            return @"ERR_CONNECT";
        case EPSONIO_OC_ERR_TIMEOUT:
            return @"ERR_TIMEOUT";
        case EPSONIO_OC_ERR_MEMORY:
            return @"ERR_MEMORY";
        case EPSONIO_OC_ERR_ILLEGAL:
            return @"ERR_ILLEGAL";
        case EPSONIO_OC_ERR_PROCESSING:
            return @"ERR_PROCESSING";
        case EPSONIO_OC_ERR_FAILURE:
            return @"ERR_FAILURE";
        default:
            return [NSString stringWithFormat:@"%d", result];
    }
}

//covnert EposPrint status to text
+ (NSString*)getEposStatusText:(unsigned long)status
{
    NSString *result = @"";
    
    for(int bit = 0; bit < BITCNT_INT; bit++){
        unsigned int value = 1 << bit;
        if((value & status) != 0){
            NSString *msg = @"";
            switch(value){
                case EPOS_OC_ST_NO_RESPONSE:
                    msg = @"NO_RESPONSE";
                    break;
                case EPOS_OC_ST_PRINT_SUCCESS:
                    msg = @"PRINT_SUCCESS";
                    break;
                case EPOS_OC_ST_DRAWER_KICK:
                    msg = @"DRAWER_KICK";
                    break;
                case EPOS_OC_ST_OFF_LINE:
                    msg = @"OFF_LINE";
                    break;
                case EPOS_OC_ST_COVER_OPEN:
                    msg = @"COVER_OPEN";
                    break;
                case EPOS_OC_ST_PAPER_FEED:
                    msg = @"PAPER_FEED";
                    break;
                case EPOS_OC_ST_WAIT_ON_LINE:
                    msg = @"WAIT_ON_LINE";
                    break;
                case EPOS_OC_ST_PANEL_SWITCH:
                    msg = @"PANEL_SWITCH";
                    break;
                case EPOS_OC_ST_MECHANICAL_ERR:
                    msg = @"MECHANICAL_ERR";
                    break;
                case EPOS_OC_ST_AUTOCUTTER_ERR:
                    msg = @"AUTOCUTTER_ERR";
                    break;
                case EPOS_OC_ST_UNRECOVER_ERR:
                    msg = @"UNRECOVER_ERR";
                    break;
                case EPOS_OC_ST_AUTORECOVER_ERR:
                    msg = @"AUTORECOVER_ERR";
                    break;
                case EPOS_OC_ST_RECEIPT_NEAR_END:
                    msg = @"RECEIPT_NEAR_END";
                    break;
                case EPOS_OC_ST_RECEIPT_END:
                    msg = @"RECEIPT_END";
                    break;
                case EPOS_OC_ST_BUZZER:
                    break;
                case EPOS_OC_ST_HEAD_OVERHEAT:
                    msg = @"HEAD_OVERHEAT";
                    break;
                case EPOS_OC_ST_MOTOR_OVERHEAT:
                    msg = @"MOTOR_OVERHEAT";
                    break;
                case EPOS_OC_ST_BATTERY_OVERHEAT:
                    msg = @"BATTERY_OVERHEAT";
                    break;
                case EPOS_OC_ST_WRONG_PAPER:
                    msg = @"WRONG_PAPER";
                    break;
                default:
                    return [NSString stringWithFormat:@"%d", value];
                    break;
            }
            if(msg.length != 0){
                if(result.length != 0){
                    result = [result stringByAppendingString:@"\n"];
                }
                result = [result stringByAppendingString:msg];
            }
        }
    }
    
    return result;
}


@end
