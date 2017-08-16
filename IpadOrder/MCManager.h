//
//  MCManager.h
//  MCDemo
//
//  Created by Gabriel Theodoropoulos on 1/7/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <FMDB.h>

@interface MCManager : NSObject <MCSessionDelegate,MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate>
{
    NSString *flag;
    FMDatabase *dbTerminal;
    
}
@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) MCPeerID *peerID2;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) NSString *dbPath;
//@property (nonatomic, strong) MCBrowserViewController *browser;
//@property (nonatomic, strong) MCAdvertiserAssistant *advertiser;
@property (nonatomic,strong)MCNearbyServiceBrowser *myBrowser;
@property (nonatomic, strong)MCNearbyServiceAdvertiser *myAdvertiser;

-(void)setupPeerAndSessionWithDisplayName:(NSString *)displayName;
-(void)setupMCBrowser;
-(void)advertiseSelf:(BOOL)shouldAdvertise;

@property(nonatomic,strong)NSArray *ArrayInvitationHandler;
@property(nonatomic,strong)NSMutableArray *peerCollection;

@property (nonatomic, strong) NSString *terminalName;

@property(nonatomic,strong)NSMutableArray *connectedPeerArray;

@property (nonatomic, strong) NSString *tIp;
@property (nonatomic, strong) NSString *tCode;
@property (nonatomic, strong) NSString *tName;
@property (nonatomic, strong) NSString *myIpAddress;
@property (nonatomic, strong) NSString *tStatus;
@property (nonatomic, strong) NSString *tDuplicate;
@property (nonatomic, strong) NSString *tAction;
@property (nonatomic, strong) NSMutableArray *clientSessionArray;
@property (nonatomic, strong) NSMutableDictionary *clientSessionDict;


@end
