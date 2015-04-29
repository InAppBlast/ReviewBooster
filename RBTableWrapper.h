//
//  RBTableWrapper.h
//  app
//
//  Created by Sasha on 23/04/15.
//  Copyright (c) 2015 InAppBlast. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#define INSERT_INDEX 5 // default row to insert dialog

#define RB_ONLINE_MODE_WITH_INAPPBLAST

@interface RBTableWrapper : NSObject <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate>

+ (RBTableWrapper *) initSharedInstance;
+ (RBTableWrapper *) sharedInstance;
- (void) setDataSource:(id<UITableViewDataSource>)dataSource andDelegate:(id<UITableViewDelegate>)delegate forTableView:(UITableView *)tableView;
- (void) setBackgroundColor:(UIColor *)backgroundColor andAccentColor:(UIColor *)accentColor;
- (NSIndexPath *) convertToOldIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *) convertToNewIndexPath:(NSIndexPath *)indexPath;
- (void) offlineDialogPermissionForBlock:(void (^)(void))block;

@end
