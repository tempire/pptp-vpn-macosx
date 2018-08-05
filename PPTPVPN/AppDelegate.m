//
//  AppDelegate.m
//  PPTPVPN
//
//  Created by chen on 2018/8/4.
//  Copyright © 2018年 ___CXY___. All rights reserved.
//

#import "AppDelegate.h"
#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>
#import "ITSwitch.h"
#import "PreferencesWindow.h"
#import "VPNManager.h"

@interface AppDelegate ()
@property (weak) IBOutlet NSMenu *vpnMenu;
@property (nonatomic, strong) NSStatusItem *vpnItem;
@property (nonatomic, strong) PreferencesWindow *preferencesWindow;

@property (weak) IBOutlet ITSwitch *connectSwitch;

@end

@implementation AppDelegate
{
    AuthorizationRef _authRef;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
//    [self helperAuth];
    [self setupVPNItem];


}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}



- (void)setupVPNItem {
    self.vpnItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.vpnItem.title = @"vpn";
    self.vpnItem.menu = self.vpnMenu;
}

- (IBAction)onConnectSwitch:(id)sender {
    
    
    [[VPNManager shared] connect:nil];

}

- (IBAction)onConfigServer:(id)sender {
    self.preferencesWindow = [[PreferencesWindow alloc] initWithWindowNibName:@"PreferencesWindow"];
    [self.preferencesWindow showWindow:self];
}

- (IBAction)onQuit:(id)sender {
    [[VPNManager shared] disConnect:nil];
    [NSApp terminate:nil];
}




- (void)helperAuth {
    NSError *error = nil;
    
    OSStatus status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &self->_authRef);
    if (status != errAuthorizationSuccess) {
        /* AuthorizationCreate really shouldn't fail. */
        assert(NO);
        self->_authRef = NULL;
    }
    
    if (![self blessHelperWithLabel:@"com.cxy.PPTPVPN.HelpTool" error:&error]) {
        NSLog(@"Something went wrong! %@ / %d", [error domain], (int) [error code]);
    } else {
        /* At this point, the job is available. However, this is a very
         * simple sample, and there is no IPC infrastructure set up to
         * make it launch-on-demand. You would normally achieve this by
         * using XPC (via a MachServices dictionary in your launchd.plist).
         */
        NSLog(@"Job is available!");
        
        [self setupVPNItem];
        
        
    }
}

- (BOOL)blessHelperWithLabel:(NSString *)label error:(NSError **)errorPtr; {
    BOOL result = NO;
    NSError * error = nil;
    
    AuthorizationItem authItem        = { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
    AuthorizationRights authRights    = { 1, &authItem };
    AuthorizationFlags flags        =    kAuthorizationFlagDefaults                |
    kAuthorizationFlagInteractionAllowed    |
    kAuthorizationFlagPreAuthorize            |
    kAuthorizationFlagExtendRights;
    
    /* Obtain the right to install our privileged helper tool (kSMRightBlessPrivilegedHelper). */
    OSStatus status = AuthorizationCopyRights(self->_authRef, &authRights, kAuthorizationEmptyEnvironment, flags, NULL);
    if (status != errAuthorizationSuccess) {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
    } else {
        CFErrorRef  cfError;
        
        /* This does all the work of verifying the helper tool against the application
         * and vice-versa. Once verification has passed, the embedded launchd.plist
         * is extracted and placed in /Library/LaunchDaemons and then loaded. The
         * executable is placed in /Library/PrivilegedHelperTools.
         */
        result = (BOOL) SMJobBless(kSMDomainSystemLaunchd, (__bridge CFStringRef)label, self->_authRef, &cfError);
        if (!result) {
            error = CFBridgingRelease(cfError);
        }
    }
    if ( ! result && (errorPtr != NULL) ) {
        assert(error != nil);
        *errorPtr = error;
    }
    
    return result;
}
@end