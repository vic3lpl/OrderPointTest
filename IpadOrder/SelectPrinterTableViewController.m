//
//  SelectPrinterTableViewController.m
//  IpadOrder
//
//  Created by IRS on 10/21/15.
//  Copyright (c) 2015 IrsSoftware. All rights reserved.
//

#import "SelectPrinterTableViewController.h"

@interface SelectPrinterTableViewController ()
{
    NSMutableArray *printerArray;
}
@end

@implementation SelectPrinterTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.preferredContentSize = CGSizeMake(320, 393);
    printerArray = [[NSMutableArray alloc]init];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self getExistPrinterType];
    
}

-(void)getExistPrinterType
{
    /*
    NSMutableDictionary *printerBrand1 = [NSMutableDictionary dictionary];
    [printerBrand1 setObject:@"Star TSP Line Mode" forKey:@"Field1"];
    [printerBrand1 setObject:@"Line" forKey:@"Field2"];
    [printerBrand1 setObject:@"Star" forKey:@"Field3"];
    NSMutableDictionary *printerBrand2 = [NSMutableDictionary dictionary];
    [printerBrand2 setObject:@"Star TSP Raster Mode" forKey:@"Field1"];
    [printerBrand2 setObject:@"Raster" forKey:@"Field2"];
    [printerBrand2 setObject:@"Star" forKey:@"Field3"];
     */
    /*
    NSMutableDictionary *printerBrand3 = [NSMutableDictionary dictionary];
    [printerBrand3 setObject:@"Asterix ST-EP Raster Mode" forKey:@"Field1"];
    [printerBrand3 setObject:@"Raster" forKey:@"Field2"];
    [printerBrand3 setObject:@"Asterix" forKey:@"Field3"];
     */
    NSMutableDictionary *printerBrand4 = [NSMutableDictionary dictionary];
    [printerBrand4 setObject:@"FlyTech 9C" forKey:@"Field1"];
    [printerBrand4 setObject:@"Raster" forKey:@"Field2"];
    [printerBrand4 setObject:@"FlyTech" forKey:@"Field3"];
    NSMutableDictionary *printerBrand5 = [NSMutableDictionary dictionary];
    [printerBrand5 setObject:@"XP900" forKey:@"Field1"];
    [printerBrand5 setObject:@"Raster" forKey:@"Field2"];
    [printerBrand5 setObject:@"XinYe" forKey:@"Field3"];
    
    //[printerArray addObject:printerBrand1];
    //[printerArray addObject:printerBrand2];
    //[printerArray addObject:printerBrand3];
    [printerArray addObject:printerBrand4];
    [printerArray addObject:printerBrand5];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return printerArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *Identifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    
    if (cell == nil) {
        //        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:Identifier] autorelease];
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:Identifier];
    }
    cell.textLabel.text = [[printerArray objectAtIndex:indexPath.row] objectForKey:@"Field1"];
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_delegate != nil) {
        
        [_delegate getSelectedPrinter:[[printerArray objectAtIndex:indexPath.row]objectForKey:@"Field1"] field2:[[printerArray objectAtIndex:indexPath.row]objectForKey:@"Field2"] field3:[[printerArray objectAtIndex:indexPath.row]objectForKey:@"Field3"]];
        //[self dismissViewControllerAnimated:YES completion:nil];
    }
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
