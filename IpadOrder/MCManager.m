//
//  MCManager.m
//  MCDemo
//
//  Created by Gabriel Theodoropoulos on 1/7/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "MCManager.h"
#import "LibraryAPI.h"
#import <KVNProgress.h>


@implementation MCManager

-(id)init{
    self = [super init];
    
    if (self) {
        _peerID = nil;
        _session = nil;
        _dbPath = nil;
        _tName = nil;
        _tIp = nil;
        _tCode = nil;
        _tStatus = nil;
        _clientSessionArray = [[NSMutableArray alloc] init];
        //_browser = nil;
        //_advertiser = nil;
    }
    
    return self;
}


#pragma mark - Public method implementation

-(void)setupPeerAndSessionWithDisplayName:(NSString *)displayName{
    /*
    _peerID = [[MCPeerID alloc] initWithDisplayName:displayName];
    
    _session = [[MCSession alloc] initWithPeer:_peerID];
    _session.delegate = self;
     */
    _connectedPeerArray = [[NSMutableArray alloc] init];
    _peerID = [[MCPeerID alloc]initWithDisplayName:displayName];
    _session = [[MCSession alloc]initWithPeer:_peerID];
    [_session setDelegate:self];
    //_ArrayInvitationHandler = [[NSArray alloc] init];
    
    
    
    
}


-(void)setupMCBrowser{
    //_browser = [[MCBrowserViewController alloc] initWithServiceType:@"chat-files" session:_session];
    
    //test
    _myBrowser = [[MCNearbyServiceBrowser alloc]initWithPeer:_peerID serviceType:@"connectMe"];
    [_myBrowser setDelegate:self];
    [_myBrowser startBrowsingForPeers];
    
}


-(void)advertiseSelf:(BOOL)shouldAdvertise{
    /*
    if (shouldAdvertise) {
        _advertiser = [[MCAdvertiserAssistant alloc] initWithServiceType:@"chat-files"
                                                           discoveryInfo:nil
                                                                 session:_session];
        [_advertiser start];
    }
    else{
        [_advertiser stop];
        _advertiser = nil;
    }
     */
    
    //test
    
    if (shouldAdvertise) {
        _myAdvertiser = [[MCNearbyServiceAdvertiser alloc]initWithPeer:_peerID discoveryInfo:nil serviceType:@"connectMe"];
        
        [_myAdvertiser setDelegate:self];
        [_myAdvertiser startAdvertisingPeer];
    }
    else{
        [_myAdvertiser stopAdvertisingPeer];
        _myAdvertiser = nil;
    }
    
}


#pragma mark - MCSession Delegate method implementation


-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    NSLog(@"%@",@"Step 2");
    //NSString *deviceCode;
    NSDictionary *dict = @{@"peerID": peerID,
                           @"state" : [NSNumber numberWithInt:state]
                           };
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MCDidChangeStateNotification"
                                                        object:nil
                                                      userInfo:dict];
    
    //NSLog(@"Peer did change state: %i", state);
    NSString *action = nil;
    
    //NSLog(@"Connected Status %d",connectedPeers.count);
    //NSMutableArray *peerArray = [[NSMutableArray alloc] init];
    switch (state) {
        case MCSessionStateConnected: {
            action = @"connected";
            _tAction = @"Connected";
            
            /*
            NSArray *connectedPeers = [_session connectedPeers];
            NSArray *arrayWithTwoStrings = [peerID.displayName componentsSeparatedByString:@","];
            
            deviceCode = [arrayWithTwoStrings objectAtIndex:2];
            NSArray *data;
            for (int i = 0; i < connectedPeers.count; i++) {
                //NSArray *allPeers = [_session connectedPeers];
                //NSString *connectedPeerName;
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                MCPeerID *onePeer = [connectedPeers objectAtIndex:i];
                
                [dict setObject:onePeer.displayName forKey:@"DisplayName"];
                //NSLog(@"Connected Status %@",deviceConnectStatus);
                [peerArray addObject:dict];
                dict = nil;
                
            }
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"DisplayName CONTAINS[cd] %@",
                                      deviceCode];
            
            data = [peerArray filteredArrayUsingPredicate:predicate];
            //NSLog(@"%d",data.count);
            if (data.count > 1) {
                _tDuplicate = @"False";
            }
            else
            {
                _tDuplicate = @"True";
            }
            
            peerArray = nil;
            data = nil;
            arrayWithTwoStrings = nil;
             */
            //[self showAlert:action];
        }
            break;
        case MCSessionStateConnecting: {
            action = @"is connecting";
            _tAction = @"Is Connecting";
        }
            break;
        case MCSessionStateNotConnected: {
            
            action = @"disconnected";
            _tAction = @"Disconnect";
        }
            break;
    }
    
    if ([peerID.displayName isEqualToString:@"Server"] && [action isEqualToString:@"connected"]) {
        NSLog(@"%@",@"i connect to server");
        //[[LibraryAPI sharedInstance] setServerConnectedStatusWithStatus:@"Connected"];
        //[KVNProgress dismiss];
        
    }
    else if(![peerID.displayName isEqualToString:@"Server"] &&[action isEqualToString:@"connected"])
    {
        //NSLog(@"%@",@"Other Device. Bui");
    }
    
    if([peerID.displayName isEqualToString:@"Server"] && [action isEqualToString:@"disconnected"])
    {
        NSLog(@"%@",@"Server Disconnected");
        //[[LibraryAPI sharedInstance] setServerConnectedStatusWithStatus:@"Disconnected"];
    }
    
    NSString *message = [NSString stringWithFormat:@"%@ %@...", peerID.displayName, action];
    NSLog(@"%@",message);
    
}


-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    NSDictionary *dict = @{@"data": data,
                           @"peerID": peerID
                           };
    
    NSDictionary *dict2 = @{
                           @"peerID": peerID
                           };
    
    [_connectedPeerArray removeAllObjects];
    [_connectedPeerArray addObject:dict2];
    //NSLog(@"%@",_testArray);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MCDidReceiveDataNotification"
                                                        object:nil
                                                      userInfo:dict];
}


-(void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress{
    
    NSDictionary *dict = @{@"resourceName"  :   resourceName,
                           @"peerID"        :   peerID,
                           @"progress"      :   progress
                           };
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"MCDidStartReceivingResourceNotification"
      //                                                  object:nil
        //                                              userInfo:dict];
    
    NSLog(@"%@",dict);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SyncMCDidStartReceivingResourceNotification"
                                                        object:nil
                                                      userInfo:dict];
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [progress addObserver:self
                   forKeyPath:@"fractionCompleted"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    });
}


-(void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error{
    
    NSDictionary *dict = @{@"resourceName"  :   resourceName,
                           @"peerID"        :   peerID,
                           @"localURL"      :   localURL
                           };
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"didFinishReceivingResourceNotification"
      //                                                  object:nil
        //                                              userInfo:dict];
    NSLog(@"%@",@"FinishReceive");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"syncdidFinishReceivingResourceNotification"
                                                        object:nil
                                                      userInfo:dict];
    
}


-(void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID{
    
    /*
    NSDictionary *dict = @{@"stream"  :   stream,
                           @"peerID"        :   peerID,
                           @"streamName"      :   streamName
                           };
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"didFinishReceivingStreamNotification"
                                                        object:nil
                                                      userInfo:dict];
     */
    
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"MCReceivingProgressNotification"
      //                                                  object:nil
        //                                              userInfo:@{@"progress": (NSProgress *)object}];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SyncMCReceivingProgressNotification"
                                                        object:nil
                                                      userInfo:@{@"progress": (NSProgress *)object}];
}

/*
-(void)session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void (^)(BOOL))certificateHandler
{
    certificateHandler(YES);
}
 */

#pragma mark - MCNearbyServiceAdvertiserDelegate

-(void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler
{
    NSLog(@"%@",@"Step 1");
    //[self showAlert:@"Step 1"];
    _peerID2 = peerID;
    _myIpAddress = [[LibraryAPI sharedInstance] getIpAddress];
    NSArray *arrayWithTwoStrings = [peerID.displayName componentsSeparatedByString:@","];
    _tName = [arrayWithTwoStrings objectAtIndex:0];
    _tIp = [arrayWithTwoStrings objectAtIndex:1];
    _tCode = [arrayWithTwoStrings objectAtIndex:2];
    _tStatus = [arrayWithTwoStrings objectAtIndex:3];
    
    NSArray *connectedPeers = [_session connectedPeers];
    //NSLog(@"lim : %d",connectedPeers.count);
    
    if (![self isValidForThisRoom:_tIp]) {
        // if the peer is not valid, decline the invitation
        invitationHandler(NO, _session);
        return;
    }
    NSMutableArray *peerArray = [[NSMutableArray alloc] init];
    
    if ([_tStatus isEqualToString:@"Sync"]) {
        NSArray *data;
        for (int i = 0; i < connectedPeers.count; i++) {
            //NSArray *allPeers = [_session connectedPeers];
            //NSString *connectedPeerName;
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            MCPeerID *onePeer = [connectedPeers objectAtIndex:i];
            
            [dict setObject:onePeer.displayName forKey:@"DisplayName"];
            //NSLog(@"Connected Status %@",deviceConnectStatus);
            [peerArray addObject:dict];
            dict = nil;
            
        }
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"DisplayName MATCHES[cd] %@",
                                  _tCode];
        
        data = [peerArray filteredArrayUsingPredicate:predicate];
        //NSLog(@"Connected Peer %d",data.count);
        NSLog(@"%@",connectedPeers);
        
        if (data.count > 1) {
            [self showAlert:@"Duplicate Device"];
            return;
        }
        
        [peerArray removeAllObjects];
        
        data = nil;
    }
    peerArray = nil;
    connectedPeers = nil;
    
    
    if ([self checkTerminalCode:_tCode]) {
        if ([self checkTerminalName:_tName]) {
            NSLog(@"CHECKING %@ %@",_tStatus,_tName);
            invitationHandler(YES, _session);
        }
        else
        {
            flag = @"Go";
            
            NSLog(@"%@",@"Step 1 - Server Ask Connection");
            
            _ArrayInvitationHandler = [NSArray arrayWithObject:[invitationHandler copy]];
            NSObject *clientName = _tName;
            NSString *clientMessage = [[NSString alloc] initWithFormat:@"%@ wants to connect. Accept ?", clientName];
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:@"Accept Connection ?"
                                      message:clientMessage
                                      delegate:self
                                      cancelButtonTitle:@"Yes"
                                      otherButtonTitles:@"No", nil];
            [alertView show];
        }
        
    }
    else
    {
        
        [self showAlert:@"Terminal id not found"];
        return;
    }

    
}

-(BOOL)isValidForThisRoom:(NSString *)ipAdd
{
    if ([ipAdd isEqualToString:_myIpAddress]) {
        return true;
    }
    else
    {
        return false;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([flag isEqualToString:@"Go"]) {
        BOOL accept = (buttonIndex == alertView.cancelButtonIndex) ? YES : NO;
        
        // respond
        MCSession *session2;
        if(accept) {
            
            session2 = [[MCSession alloc] initWithPeer:_peerID2];
            session2.delegate = self;
        }
        
        void (^invitationHandler)(BOOL, MCSession *) = [_ArrayInvitationHandler objectAtIndex:0];
        invitationHandler(accept, _session);
        
        //[_myAdvertiser stopAdvertisingPeer];
    }
    
}


/*
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler
{
    NSString *message = [NSString stringWithFormat:@"Received invitation from %@. Joining...", peerID.displayName];
    //[self ingestMessage:message attachmentURL:nil thumbnailURL:nil fromPeer:nil];
    NSLog(@"Receive : %@",message);
    invitationHandler(YES, self.session);    // In most cases you might want to give users an option to connect or not.
    [_myAdvertiser stopAdvertisingPeer];  //  Once invited, stop advertising
}
 */


- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
    NSLog(@"unable to advertise! %@", error);
    //[self showAlert:[NSString stringWithFormat:@"%@",error]];
}


#pragma mark - MCNearbyServiceBrowserDelegate

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
    NSString *message = [NSString stringWithFormat:@"Sending an invitation to %@ to join the chat...", peerID.displayName];
    
    //[self ingestMessage:message attachmentURL:nil thumbnailURL:nil fromPeer:nil];
    NSLog(@"Lim : %@",message);
    [_myBrowser invitePeer:peerID
              toSession:self.session
            withContext:nil
                timeout:30.0];
}

// A nearby peer has stopped advertising
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    NSString *message = [NSString stringWithFormat:@"%@ was Stop Adver...", peerID.displayName];
    NSLog(@"Lim : %@",message);
    //[self showAlert:message];
    //[self ingestMessage:message attachmentURL:nil thumbnailURL:nil fromPeer:nil];
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error {
    NSLog(@"error browsing!!! %@", error);
}

-(void)showAlert:(NSString *)msg
{
    flag = @"No";
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"Warning"
                              message:msg
                              delegate:self
                              cancelButtonTitle:@"No"
                              otherButtonTitles:nil, nil];
    [alertView show];
}

#pragma mark - alertView

-(void)showAlertView:(NSString *)msg title:(NSString *)title
{
    flag = @"No";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - sqlite

-(BOOL)checkTerminalCode:(NSString *)code
{
    dbTerminal = [FMDatabase databaseWithPath:_dbPath];
    
    //BOOL dbHadError;
    
    if (![dbTerminal open]) {
        NSLog(@"Fail To Open");
        return false;
    }
    
    FMResultSet *rs = [dbTerminal executeQuery:@"Select * from Terminal where T_Code = ?",code];
    
    if ([rs next]) {
        [rs close];
        [dbTerminal close];
        return true;
    }
    else
    {
        [rs close];
        [dbTerminal close];
        return false;
    }
    

}

-(BOOL)checkTerminalName:(NSString *)name
{
    dbTerminal = [FMDatabase databaseWithPath:_dbPath];
    
    //BOOL dbHadError;
    
    if (![dbTerminal open]) {
        NSLog(@"Fail To Open");
        return false;
    }
    
    FMResultSet *rs = [dbTerminal executeQuery:@"Select * from Terminal where T_DeviceName = ?",name];
    
    if ([rs next]) {
        [rs close];
        [dbTerminal close];
        return true;
    }
    else
    {
        [rs close];
        [dbTerminal close];
        return false;
    }
    
    
}





@end
