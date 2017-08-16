#import <Foundation/Foundation.h>
#import "MsgMaker.h"
#import "ePOS-Print.h"
//#import "ePOSBluetoothConnection.h"

static const int BATTERY_NEAR_END = 0x3131;
static const int BATTERY_REAL_END = 0x3130;

@interface MsgMaker()
    //private method
+ (NSString *)makePrinterStatusErrorHandlingText:(Result *)result;
+ (NSString *)makeEposPrintAPIErrorHandlingText:(Result *)result;
+ (NSString *)makeEpsonIoAPIErrorHandlingText:(Result *)result;
//+ (NSString *)makeEposBtAPIErrorHandlingText:(Result *)result;
@end

@implementation MsgMaker

+ (NSString *)makeErrorMessage:(Result *)result
{
    NSString *ErrMsg = nil;
    
    switch(result.errType){
        case RESULT_ERR_EPOSPRINT:
            ErrMsg = [self makeEposPrintAPIErrorHandlingText:result];
            break;
            
        case RESULT_ERR_EPSONIO:
            ErrMsg = [self makeEpsonIoAPIErrorHandlingText:result];
            break;
            
        case RESULT_ERR_EPOSBT:
            //ErrMsg = [self makeEposBtAPIErrorHandlingText:result];
            break;
            
        default:
            ErrMsg = [self makePrinterStatusErrorHandlingText:result];
            break;
    }

    return ErrMsg;
}

+ (NSString *)makeWarningMessage:(Result *)result
{
    NSMutableString *WarningMsg = [[NSMutableString alloc] init];
    if(WarningMsg == nil){
        return nil;
    }

    if(IS_INCLUDE_STATUS(result.printerStatus, EPOS_OC_ST_RECEIPT_NEAR_END)) {
        [WarningMsg appendString:NSLocalizedString(@"handlingmsg_warn_receipt_near_end", @"")];
    }
    
    if(result.batteryStatus == BATTERY_NEAR_END) {
        [WarningMsg appendString:NSLocalizedString(@"handlingmsg_warn_battery_near_end", @"")];
    }

    return WarningMsg;
}

+ (NSString *)makeEposPrintAPIErrorHandlingText:(Result *)result
{
    NSMutableString *retMsg = [[NSMutableString alloc] init];
    if(retMsg == nil){
        return nil;
    }
    
    NSMutableString *printerMsg = [[NSMutableString alloc] init];
    if(printerMsg == nil){
        //[retMsg release];
        return nil;
    }

    //get EposPrint API error handling text
    switch(result.errStatus) {
        case EPOS_OC_ERR_PARAM:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_application_error", @"")];
            break;
            
        case EPOS_OC_ERR_OPEN:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_open", @"")];
            break;
            
        case EPOS_OC_ERR_CONNECT:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_connect", @"")];
            break;
            
        case EPOS_OC_ERR_TIMEOUT:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_timeout", @"")];
            break;
            
        case EPOS_OC_ERR_MEMORY:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_application_error", @"")];
            break;
            
        case EPOS_OC_ERR_ILLEGAL:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_application_error", @"")];
            break;
            
        case EPOS_OC_ERR_PROCESSING:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_application_error", @"")];
            break;
            
        case EPOS_OC_ERR_UNSUPPORTED:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_application_error", @"")];
            break;
            
        case EPOS_OC_ERR_OFF_LINE:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_off_line", @"")];
            break;
            
        case EPOS_OC_ERR_FAILURE:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_application_error", @"")];
            break;
            
        default:
            //Should not reach
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_failure", @"")];
            break;
    }
    
    [retMsg appendString:@"\n"];

    //get printer error handling text
    [retMsg appendString:NSLocalizedString(@"handlingmsg_notice_printer_problems", @"")];
    
    [printerMsg setString:[self makePrinterStatusErrorHandlingText:result]];
    
    if([printerMsg length] == 0) {
        //Failed to get printer error
        [printerMsg setString:NSLocalizedString(@"handlingmsg_notice_failed", @"")];
    }
    
    [retMsg appendString:printerMsg];

    //release temporary string
    //[printerMsg release];

    return retMsg;
}

+ (NSString *)makeEpsonIoAPIErrorHandlingText:(Result *)result
{
    NSMutableString *retMsg = [[NSMutableString alloc] init];
    if(retMsg == nil){
        return nil;
    }
    
    switch(result.errStatus) {
        case EPSONIO_OC_ERR_PARAM:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_application_error", @"")];
            break;
            
        case EPSONIO_OC_ERR_OPEN:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_open", @"")];
            break;
            
        case EPSONIO_OC_ERR_CONNECT:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_connect", @"")];
            break;
            
        case EPSONIO_OC_ERR_TIMEOUT:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_timeout", @"")];
            break;
            
        case EPSONIO_OC_ERR_MEMORY:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_application_error", @"")];
            break;
            
        case EPSONIO_OC_ERR_ILLEGAL:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_application_error", @"")];
            break;
            
        case EPSONIO_OC_ERR_PROCESSING:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_application_error", @"")];
            break;
            
        case EPSONIO_OC_ERR_FAILURE:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_failure", @"")];
            break;
            
        default:
            //Should not reach
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_failure", @"")];
            break;
    }

    return retMsg;
}

/*
+ (NSString *)makeEposBtAPIErrorHandlingText:(Result *)result
{
    NSMutableString *retMsg = [[NSMutableString alloc] init];
    if(retMsg == nil){
        return nil;
    }
    
    switch(result.errStatus) {
        case EPOS_BT_ERR_PARAM:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_application_error", @"")];
            break;
            
        case EPOS_BT_ERR_CONNECT:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_connect", @"")];
            break;
            
        case EPOS_BT_ERR_MEMORY:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_application_error", @"")];
            break;
            
        case EPOS_BT_ERR_ILLEGAL:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_application_error", @"")];
            break;
            
        case EPOS_BT_ERR_UNSUPPORTED:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_application_error", @"")];
            break;
            
        case EPOS_BT_ERR_CANCEL:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_cancel", @"")];
            break;
            
        case EPOS_BT_ERR_ALREADY_CONNECT:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_already_connect", @"")];
            break;
            
        case EPOS_BT_ERR_ILLEGAL_DEVICE:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_illegal_device", @"")];
            break;
            
        case EPOS_BT_ERR_FAILURE:
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_failure", @"")];
            break;
            
        default:
            //Should not reach
            [retMsg setString:NSLocalizedString(@"handlingmsg_ex_failure", @"")];
            break;
    }

    return retMsg;
}
*/

+ (NSString *)makePrinterStatusErrorHandlingText:(Result *)result
{
    NSMutableString *msg = [[NSMutableString alloc] init];
    if(msg == nil){
        return nil;
    }
    
    unsigned long status = result.printerStatus;
    unsigned long battery = result.batteryStatus;

    //Create printer error handling message
    if(IS_INCLUDE_STATUS(status, EPOS_OC_ST_NO_RESPONSE)) {
        [msg appendString:NSLocalizedString(@"handlingmsg_err_no_response", @"")];
    }
    
    if(IS_INCLUDE_STATUS(status, EPOS_OC_ST_COVER_OPEN)) {
        [msg appendString:NSLocalizedString(@"handlingmsg_err_cover_open", @"")];
    }
    
    if(IS_INCLUDE_STATUS(status, EPOS_OC_ST_PAPER_FEED) || IS_INCLUDE_STATUS(status, EPOS_OC_ST_PANEL_SWITCH)) {
        [msg appendString:NSLocalizedString(@"handlingmsg_err_paper_feed", @"")];
    }
    
    if(IS_INCLUDE_STATUS(status, EPOS_OC_ST_AUTOCUTTER_ERR) || IS_INCLUDE_STATUS(status, EPOS_OC_ST_MECHANICAL_ERR)) {
        [msg appendString:NSLocalizedString(@"handlingmsg_err_autocutter", @"")];
    }
    
    if(IS_INCLUDE_STATUS(status, EPOS_OC_ST_UNRECOVER_ERR)) {
        [msg appendString:NSLocalizedString(@"handlingmsg_err_unrecover", @"")];
    }
    
    if(IS_INCLUDE_STATUS(status, EPOS_OC_ST_RECEIPT_END)) {
        [msg appendString:NSLocalizedString(@"handlingmsg_err_receipt_end", @"")];
    }
    
    if(IS_INCLUDE_STATUS(status, EPOS_OC_ST_HEAD_OVERHEAT)) {
        [msg appendString:NSLocalizedString(@"handlingmsg_err_overheat", @"")];
        [msg appendString:NSLocalizedString(@"handlingmsg_err_head", @"")];
    }
    
    if(IS_INCLUDE_STATUS(status, EPOS_OC_ST_MOTOR_OVERHEAT)) {
        [msg appendString:NSLocalizedString(@"handlingmsg_err_overheat", @"")];
        [msg appendString:NSLocalizedString(@"handlingmsg_err_motor", @"")];
    }
    
    if(IS_INCLUDE_STATUS(status, EPOS_OC_ST_BATTERY_OVERHEAT)) {
        [msg appendString:NSLocalizedString(@"handlingmsg_err_overheat", @"")];
        [msg appendString:NSLocalizedString(@"handlingmsg_err_battery", @"")];
    }
    
    if(IS_INCLUDE_STATUS(status, EPOS_OC_ST_WRONG_PAPER)) {
        [msg appendString:NSLocalizedString(@"handlingmsg_err_wrong_paper", @"")];
    }
    
    if(battery == BATTERY_REAL_END) {
        [msg appendString:NSLocalizedString(@"handlingmsg_err_battery_real_end", @"")];
    }

    return msg;
}

@end
