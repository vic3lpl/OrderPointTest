//
//  PaymentViewController.h
//  IpadOrder
//
//  Created by IRS on 8/20/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumericKeypadDelegate.h"
#import "ChangeAmtViewController.h"
#import "AppUtility.h"
#import "PosCommand.h"
#import "TscCommand.h"
#import "ImageTranster.h"
#import "XYSDK.h"
#import "PublicSqliteMethod.h"

@protocol PaymentViewDelegate <NSObject>

@required
-(void)successMakePayment:(NSString *)payLeftOrRight;
-(void)cancelPayment:(NSString *)soOldNo;

@end

@interface PaymentViewController : UIViewController <NumericKeypadDelegate,UITextFieldDelegate,UITableViewDataSource,UITableViewDelegate,ChangeAmtDelegate,UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,POS_APIDelegate,XYWIFIManagerDelegate>

//@property NSString *docNo;
@property (strong, nonatomic) IBOutlet UILabel *labelTotalAmt;
@property (strong, nonatomic) IBOutlet UILabel *labelChangeAmt;
@property (strong, nonatomic) IBOutlet UILabel *labelTotalDiscount;
@property (strong, nonatomic) IBOutlet UILabel *labelTotalTax;
@property (strong, nonatomic) IBOutlet UILabel *labelSubtotal;
@property (strong, nonatomic) IBOutlet UILabel *labelRounding;
@property (strong, nonatomic) IBOutlet UILabel *labelServiceCharge;

@property (strong, nonatomic) IBOutlet UITextField *textRef;

- (IBAction)btnCancelPayment:(id)sender;
@property (strong, nonatomic) IBOutlet NumericKeypadTextField *textPayAmt;

@property (strong, nonatomic) IBOutlet UITableView *paymentModeTableView;
//@property (strong, nonatomic) IBOutlet UITableView *paymentTypeTableView;



@property (strong, nonatomic) IBOutlet UIButton *btnTen;
@property (strong, nonatomic) IBOutlet UIButton *btnTwenty;
@property (strong, nonatomic) IBOutlet UIButton *btnFity;
@property (strong, nonatomic) IBOutlet UIButton *btnExact;

- (IBAction)btnKeyPad:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *btnC;

//--------------------------------

@property (strong, nonatomic) IBOutlet UIButton *btnMakePayment;

@property(nonatomic,weak)NSString *splitBill_YN;
@property(nonatomic,weak)NSString *splitBillTotalAmt;
@property(nonatomic,weak)NSString *splitBillTotalTaxAmt;
@property(nonatomic,weak)NSString *splitBillTotalDiscAmt;
@property(nonatomic,weak)NSString *splitBillSubTotalAmt;

@property (weak,nonatomic)id<PaymentViewDelegate>delegate;
@property (strong, nonatomic) IBOutlet UIButton *btnPayCash;
@property (strong, nonatomic) IBOutlet UIButton *btnPayCard;
//@property (strong, nonatomic) IBOutlet UILabel *labelPayment;
@property(nonatomic,weak)NSString *soStatus;
@property(nonatomic,strong)NSString *tbName;
//@property (weak, nonatomic) IBOutlet UILabel *labelTotalAmtBlue;

@property(nonatomic,weak)NSString *terminalType;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionViewPayMethod;

@property (weak, nonatomic) IBOutlet UIImageView *imgAddPayment;
@property (weak, nonatomic) IBOutlet UITextField *labelLeftChange;
@property (weak, nonatomic) IBOutlet UITextField *textTotalAmtNeedToPay;

//@property (weak, nonatomic) IBOutlet UILabel *labelMultiPayVisible;
@property (nonatomic, strong) XYWIFIManager *wifiManager;

- (IBAction)btnTestPrinter:(id)sender;
@property(nonatomic,strong)NSString *finalPaxNo;
@property(nonatomic,strong)NSString *payDocType;
@property(nonatomic, copy)NSMutableDictionary *dictPayCust;
@end
