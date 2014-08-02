//
//  VNKey.m
//  VideoNews
//
//  Created by liuyi on 14-6-26.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNKey.h"

//NSString *const VNHost = @"http://zmysp.sinaapp.com/";
NSString *const VNHost = @"http://182.92.103.134:8080/engine/";
//SearchHistory
NSString *const kArchivingHistoryWord = @"kArchivingHistoryWord";
NSString *const VNHistoryDidAddNotification = @"kVNHistoryDidAddNotification";
NSString *const VNHistoryDidClearNotification = @"kVNHistoryDidClearNotification";
NSString *const VNSearchTypeDidChangeNotification = @"kVNSearchTypeDidChangeNotification";
NSString *const VNHomeCellDeleteNotification=@"KVNHomeCellDeleteNotification";
NSString *const VNCategoryCellDeleteNotification=@"KVNCategoryCellDeleteNotification";
NSString *const VNProfileCellDeleteNotification=@"KVNProfileCellDeleteNotification";
NSString *const VNMineProfileVideoCellDeleteNotification=@"KVNMineProfileVideoCellDeleteNotification";
NSString *const VNNotificationCellDeleteNotification=@"KVNNotificationCellDeleteNotification";
NSString *const VNMineProfileFavouriteCellDeleteNotification=@"KVNMineProfileFavouriteCellDeleteNotification";
NSString *const VNSignOutNotification=@"KVNSignOutNotification";

//NSUserDefault
NSString *const VNLoginUser = @"kVNLoginUser";
NSString *const isLogin = @"KIsLogin";
NSString *const VNLoginDate = @"kVNLoginDate";
NSString *const VNPushToken = @"kVNPushToken";
NSString *const VNUserToken = @"kVNUserToken";
NSString *const VNProfileInfo = @"kVNProfileInfo";
NSString *const VNIsWiFiAutoPlay = @"kVNIsWiFiAutoPlay";

//友盟相关
NSString *const UmengAppkey = @"53a91faf56240bf2de0016ef";
NSString *const WXAppkey = @"wxe0372fefc13da965";
NSString *const WXAppScrectkey = @"8335fd5e515fad953850d07f4642e205";
NSString *const QQAppID = @"1101719889";
NSString *const QQAppKey = @"xScM0nFWCPJqVlaD";
//FIXME: 替换上线后的AppID
NSString *const AppID = @"888245642";