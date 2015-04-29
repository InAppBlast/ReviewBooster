//
//  RBTableWrapper.h
//  app
//
//  Created by Sasha on 23/04/15.
//  Copyright (c) 2015 InAppBlast. All rights reserved.
//

#import "RBTableWrapper.h"

#ifdef RB_ONLINE_MODE_WITH_INAPPBLAST
#import <InAppBlast/InAppBlast.h>
#endif

#define RB_OFFLINE_OPEN_COUNT               @"_rb_offline_open_count"
#define RB_OFFLINE_OPEN_IN_LAST_BUILD_COUNT @"_rb_offline_open_in_last_build_count"
#define RB_OFFLINE_BUILD_REVIEWED           @"_rb_offline_build_reviewed"
#define RB_OFFLINE_REVIEW_COMPLETE          @"_rb_offline_review_complete"
#define RB_OFFLINE_APP_BUILD                @"_rb_offline_app_build"

typedef enum {
    RBStageAsk = 1,
    RBStageYes = 2,
    RBStageNo = 3
} RBStage;

@interface RBTableWrapper ()

@property (nonatomic, weak) id<UITableViewDataSource> dataSource;
@property (nonatomic, weak) id<UITableViewDelegate> delegate;
@property (nonatomic, weak) UITableView * tableView;

@property (nonatomic, strong) UIColor * backgroundColor;
@property (nonatomic, strong) UIColor * accentColor;
@property (nonatomic, strong) UIFont * font;
@property (nonatomic, strong) UILabel * questionLabel;
@property (nonatomic, strong) UIButton * yesButton;
@property (nonatomic, strong) UIButton * noButton;

@property (atomic, assign) RBStage stage;
@property (atomic, assign) BOOL complete;

@end

@implementation RBTableWrapper

static RBTableWrapper * sharedInstance = nil;

+ (RBTableWrapper *) initSharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super alloc] initPrivate];
    });
    return sharedInstance;
}

+ (RBTableWrapper *) sharedInstance {
    if (sharedInstance == nil) {
        return nil;
    } else {
        return sharedInstance;
    }
}

- (instancetype) initPrivate {
    self = [self init];
    if (self) {
        _backgroundColor = [UIColor orangeColor];
        _accentColor = [UIColor whiteColor];
        _font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
        
        _stage = RBStageAsk;
        _complete = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void) setDataSource:(id<UITableViewDataSource>)dataSource andDelegate:(id<UITableViewDelegate>)delegate forTableView:(UITableView *)tableView {
    _dataSource = dataSource;
    _delegate = delegate;
    _tableView = tableView;
}

- (void) setBackgroundColor:(UIColor *)backgroundColor andAccentColor:(UIColor *)accentColor {
    _backgroundColor = backgroundColor;
    _accentColor = accentColor;
}

- (void) handleApplicationDidBecomeActive:(NSNotification *)notif {
    NSString * appBuild = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    if (![appBuild isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:RB_OFFLINE_APP_BUILD]]) {
        [[NSUserDefaults standardUserDefaults] setObject:appBuild forKey:RB_OFFLINE_APP_BUILD];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:RB_OFFLINE_OPEN_IN_LAST_BUILD_COUNT];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:RB_OFFLINE_BUILD_REVIEWED];
    }
    
    NSNumber * openCount = [[NSUserDefaults standardUserDefaults] objectForKey:RB_OFFLINE_OPEN_COUNT];
    if (openCount == nil) openCount = 0;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:openCount.intValue + 1] forKey:RB_OFFLINE_OPEN_COUNT];
    
    NSNumber * openInLastBuildCount = [[NSUserDefaults standardUserDefaults] objectForKey:RB_OFFLINE_OPEN_IN_LAST_BUILD_COUNT];
    if (openInLastBuildCount == nil) openInLastBuildCount = 0;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:openInLastBuildCount.intValue + 1] forKey:RB_OFFLINE_OPEN_IN_LAST_BUILD_COUNT];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:RB_OFFLINE_REVIEW_COMPLETE] == nil) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:RB_OFFLINE_REVIEW_COMPLETE];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:RB_OFFLINE_BUILD_REVIEWED] == nil) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:RB_OFFLINE_BUILD_REVIEWED];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (long) getInsertRow {
    long insertRow = INSERT_INDEX - 1;
    if ([self tableView:_tableView numberOfRowsInSection:0] <= insertRow) {
        insertRow = [self tableView:_tableView numberOfRowsInSection:0] / 2;
    }
    return insertRow;
}

- (NSIndexPath *) convertToOldIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && _complete == NO) {
        if (indexPath.row < [self getInsertRow]) {
            return indexPath;
        } else if (indexPath.row == [self getInsertRow]) {
            return nil;
        } else {
            return [NSIndexPath indexPathForRow:(indexPath.row - 1) inSection:indexPath.section];
        }
    } else {
        return indexPath;
    }
}

- (NSIndexPath *) convertToNewIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && _complete == NO) {
        if (indexPath.row < [self getInsertRow]) {
            return indexPath;
        } else {
            return [NSIndexPath indexPathForRow:(indexPath.row + 1) inSection:indexPath.section];
        }
    } else {
        return indexPath;
    }
}

#pragma mark - offline mode
- (void) offlineDialogPermissionForBlock:(void (^)(void))block {
    NSNumber * openCount = [[NSUserDefaults standardUserDefaults] objectForKey:RB_OFFLINE_OPEN_COUNT];
    NSNumber * openInLastBuildCount = [[NSUserDefaults standardUserDefaults] objectForKey:RB_OFFLINE_OPEN_IN_LAST_BUILD_COUNT];
    NSNumber * buildReviewed = [[NSUserDefaults standardUserDefaults] objectForKey:RB_OFFLINE_BUILD_REVIEWED];
    NSNumber * reviewComplete = [[NSUserDefaults standardUserDefaults] objectForKey:RB_OFFLINE_REVIEW_COMPLETE];
    
    NSLog(@"ReviewBoosterOffline: openCount = %@, openInLastBuildCount = %@, buildReviewed = %@, reviewComplete = %@", openCount, openInLastBuildCount, buildReviewed, reviewComplete);
    
    if ((openCount.intValue > 15) &&
        (openInLastBuildCount.intValue > 5) &&
        (buildReviewed.boolValue == NO) &&
        (reviewComplete.boolValue == NO))
    {
        NSLog(@"ReviewBoosterOffline: show dialog!");
        block();
    }
}

#pragma mark - interface construction
- (UIImage *) imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIButton *) makeButton {
    UIButton * button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    button.layer.masksToBounds = TRUE;
    button.layer.cornerRadius = 5;
    button.layer.borderWidth = 1;
    button.layer.borderColor = _accentColor.CGColor;
    
    button.titleLabel.font = _font;
    
    [button setTitleColor:_accentColor forState:UIControlStateNormal];
    [button setTitleColor:_accentColor forState:UIControlStateHighlighted];
    [button setTitleColor:_accentColor forState:UIControlStateSelected];
    
    [button setBackgroundImage:[[self imageWithColor:_accentColor] resizableImageWithCapInsets:UIEdgeInsetsZero] forState:UIControlStateHighlighted];
    
    return button;
}

- (UITableViewCell *) makeReviewCell {
    float width = _tableView.frame.size.width;
    
    UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"qq"];
    
    [cell.contentView setBackgroundColor:_backgroundColor];
    
    _yesButton = [self makeButton];
    _noButton = [self makeButton];
    _yesButton.frame = CGRectMake(width / 2 + 5, 38, width / 2 - 15, 44);
    _noButton.frame = CGRectMake(10, 38, width / 2 - 15, 44);
    
    [_yesButton addTarget:self action:@selector(yesButtonTap) forControlEvents:UIControlEventTouchUpInside];
    [_noButton addTarget:self action:@selector(noButtonTap) forControlEvents:UIControlEventTouchUpInside];
    
    [cell.contentView addSubview:_yesButton];
    [cell.contentView addSubview:_noButton];
    
    _questionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 40)];
    _questionLabel.textColor = _accentColor;
    _questionLabel.textAlignment = NSTextAlignmentCenter;
    _questionLabel.font = _font;
    
    [cell.contentView addSubview:_questionLabel];
    
    [self setCaptions];
    
    return cell;
}

- (void) setCaptions {
    if (_stage == RBStageAsk) {
        _questionLabel.text = NSLocalizedString(@"rb_like_app", nil);
        [_yesButton setTitle:NSLocalizedString(@"rb_yes_button", nil) forState:UIControlStateNormal];
        [_noButton setTitle:NSLocalizedString(@"rb_no_button", nil) forState:UIControlStateNormal];
        
    } else if (_stage == RBStageYes) {
        _questionLabel.text = NSLocalizedString(@"rb_ask_rate", nil);
        [_yesButton setTitle:NSLocalizedString(@"rb_ask_rate_yes", nil) forState:UIControlStateNormal];
        [_noButton setTitle:NSLocalizedString(@"rb_ask_rate_no", nil) forState:UIControlStateNormal];
        
    } else if (_stage == RBStageNo) {
        _questionLabel.text = NSLocalizedString(@"rb_ask_feedback", nil);
        [_yesButton setTitle:NSLocalizedString(@"rb_ask_feedback_yes", nil) forState:UIControlStateNormal];
        [_noButton setTitle:NSLocalizedString(@"rb_ask_feedback_no", nil) forState:UIControlStateNormal];
    }
}

#pragma mark - Button actions
- (void) yesButtonTap {
    if (_stage == RBStageAsk) {
        _stage = RBStageYes;
        [self setCaptions];
        
    } else if (_stage == RBStageYes) {
        _complete = YES;
        [_tableView reloadData];
#ifdef RB_ONLINE_MODE_WITH_INAPPBLAST
        [[InAppBlast sharedInstance] markLastTriggerCampaign:@"4"];
        [[InAppBlast sharedInstance] setUserProperties:@{@"_review_complete":[NSNumber numberWithBool:YES], @"_build_reviewed":[NSNumber numberWithBool:YES]}];
#endif
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:RB_OFFLINE_BUILD_REVIEWED];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:RB_OFFLINE_REVIEW_COMPLETE];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSString * iTunesLink = @"itms://itunes.apple.com/us/app/apple-store/id525256014?mt=8";
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
        
    } else if (_stage == RBStageNo) {
        _complete = YES;
        [_tableView reloadData];
#ifdef RB_ONLINE_MODE_WITH_INAPPBLAST
        [[InAppBlast sharedInstance] markLastTriggerCampaign:@"2"];
        [[InAppBlast sharedInstance] setUserProperties:@{@"_review_complete":[NSNumber numberWithBool:YES], @"_build_reviewed":[NSNumber numberWithBool:YES]}];
#endif
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:RB_OFFLINE_BUILD_REVIEWED];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:RB_OFFLINE_REVIEW_COMPLETE];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self createEmailWithSubject:@"Test subject" toRecipient:@"developers@yumixo.com" withBody:@"привет, приложение у вас не очень"];
    }
}

- (void) noButtonTap {
    if (_stage == RBStageAsk) {
        _stage = RBStageNo;
        [self setCaptions];
        
    } else if (_stage == RBStageYes) {
        _complete = YES;
        [_tableView reloadData];
#ifdef RB_ONLINE_MODE_WITH_INAPPBLAST
        [[InAppBlast sharedInstance] markLastTriggerCampaign:@"3"];
        [[InAppBlast sharedInstance] setUserProperties:@{@"_build_reviewed":[NSNumber numberWithBool:YES]}];
#endif
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:RB_OFFLINE_BUILD_REVIEWED];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    } else if (_stage == RBStageNo) {
        _complete = YES;
        [_tableView reloadData];
#ifdef RB_ONLINE_MODE_WITH_INAPPBLAST
        [[InAppBlast sharedInstance] markLastTriggerCampaign:@"1"];
        [[InAppBlast sharedInstance] setUserProperties:@{@"_build_reviewed":[NSNumber numberWithBool:YES]}];
#endif
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:RB_OFFLINE_BUILD_REVIEWED];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && _complete == NO) {
        if (indexPath.row < [self getInsertRow]) {
            return [_dataSource tableView:tableView cellForRowAtIndexPath:indexPath];
            
        } else if (indexPath.row == [self getInsertRow]) {
            return [self makeReviewCell];
            
        } else {
            NSIndexPath * newIndex = [NSIndexPath indexPathForRow:(indexPath.row-1) inSection:indexPath.section];
            return [_dataSource tableView:tableView cellForRowAtIndexPath:newIndex];
        }
        
    } else {
        return [_dataSource tableView:tableView cellForRowAtIndexPath:indexPath];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && _complete == NO) {
        return [_dataSource tableView:tableView numberOfRowsInSection:section] + 1;
    } else {
        return [_dataSource tableView:tableView numberOfRowsInSection:section];
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([_delegate respondsToSelector:@selector(tableView:heightForHeaderInSection:)]) {
        return [_delegate tableView:tableView heightForHeaderInSection:section];
    }
    return 0.0;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ([_delegate respondsToSelector:@selector(tableView:viewForHeaderInSection:)]) {
        return [_delegate tableView:tableView viewForHeaderInSection:section];
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([_dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
        return [_dataSource numberOfSectionsInTableView:tableView];
    } else {
        return 1;
    }
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == [self getInsertRow] && _complete == NO) {
        return 95.0;
    
    } else {
        if ([_delegate respondsToSelector:@selector(tableView: heightForRowAtIndexPath:)]) {
            return [_delegate tableView:tableView heightForRowAtIndexPath:[self convertToOldIndexPath:indexPath]];
        } else {
            return 44;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && _complete == NO) {
        if (indexPath.row > [self getInsertRow]) {
            [tableView selectRowAtIndexPath:[self convertToOldIndexPath:indexPath] animated:NO scrollPosition:UITableViewScrollPositionNone];
            if ([_delegate respondsToSelector:@selector(tableView: didSelectRowAtIndexPath:)]) {
                [_delegate tableView:tableView didSelectRowAtIndexPath:[self convertToOldIndexPath:indexPath]];
            }
        } else if (indexPath.row < [self getInsertRow]) {
            if ([_delegate respondsToSelector:@selector(tableView: didSelectRowAtIndexPath:)]) {
                [_delegate tableView:_tableView didSelectRowAtIndexPath:indexPath];
            }
        } else {
            // empty
        }
    } else {
        [_delegate tableView:_tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (void) tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == [self getInsertRow] && _complete == NO) {
        return;
    }
    if ([_delegate respondsToSelector:@selector(tableView: didHighlightRowAtIndexPath:)]) {
        [_delegate tableView:tableView didHighlightRowAtIndexPath:[self convertToOldIndexPath:indexPath]];
    }
}

- (void) tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == [self getInsertRow] && _complete == NO) {
        return;
    }
    if ([_delegate respondsToSelector:@selector(tableView: didUnhighlightRowAtIndexPath:)]) {
        [_delegate tableView:tableView didUnhighlightRowAtIndexPath:[self convertToOldIndexPath:indexPath]];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate
- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [((UIViewController *)_delegate) dismissViewControllerAnimated:YES completion:nil];
}

- (void) createEmailWithSubject:(NSString *)subject toRecipient:(NSString *)recipient withBody:(NSString*)body {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
        picker.mailComposeDelegate = self;
        
        [picker setSubject:subject];
        NSArray *toRecipients = [NSArray arrayWithObject:recipient];
        [picker setToRecipients:toRecipients];
        [picker setCcRecipients:nil];
        [picker setBccRecipients:nil];
        [picker setMessageBody:body isHTML:NO];
        [((UIViewController *)_delegate) presentViewController:picker animated:YES completion:nil];
        
    } else {
        NSString *recipients = [NSString stringWithFormat: @"mailto:%@?subject=%@", recipient, subject];
        
        NSString *email = [NSString stringWithFormat:@"%@%@", recipients, body];
        email = [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
    }
}

@end
