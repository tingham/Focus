#import "AppDelegate.h"

#import "Focus.h"
#import "InstallerManager.h"
#import "ConnectionManager.h"
#import "HelperTool.h"
#import "FocusHTTProxy.h"
#import "RHStatusItemView.h"
#import "NSAttributedString+hyperlinkFromString.h"
#import <Sparkle/Sparkle.h>

@interface AppDelegate ()
@property (nonatomic, assign, readwrite) IBOutlet NSWindow *window;
@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) FocusHTTProxy *httpProxy;
@property (strong, nonatomic) ConnectionManager *helperConnectionManager;
@property (strong, nonatomic) InstallerManager *installerManager;
@property (strong, nonatomic) Focus *focus;
@property (strong, nonatomic) NSMenu *menu;
@property (strong, nonatomic) IBOutlet NSButton *launchCheckbox;
@property (strong, nonatomic) IBOutlet NSMenu *contextMenu;
@property (strong, nonatomic) RHStatusItemView *statusItemView;
@property (strong, nonatomic) IBOutlet NSTextField *versionLabel;
@property (strong, nonatomic) IBOutlet NSTextFieldCell *websiteLabel;
@property (strong, nonatomic) IBOutlet NSMenuItem *focusAction;
@property (strong, nonatomic) IBOutlet NSButton *menuToggleCheckbox;
@property (strong, nonatomic) IBOutlet NSButton *monochromeIconCheckbox;
@property (strong, nonatomic) IBOutlet NSTableView *blockedSitesTableView;
@property (strong, nonatomic) IBOutlet NSArrayController *blockedSitesArrayController;
@property (strong, nonatomic) NSMutableArray *blockedSites;
@property (strong, nonatomic) NSUserDefaults *userDefaults;
@property (strong, nonatomic) IBOutlet NSButton *removeBlockedSite;
@end

@implementation AppDelegate

@synthesize websiteLabel;

- (void)applicationDidFinishLaunching:(NSNotification *)note
{
    #pragma unused(note)
    [self startup];
    assert(self.window != nil);
    
    SUUpdater *sparkle = [[SUUpdater alloc] init];
    sparkle.delegate = self;
    [sparkle checkForUpdatesInBackground];
}

- (void)updater:(SUUpdater *)updater willInstallUpdate:(SUAppcastItem *)update
{
#pragma unused(updater)
    NSString *updateHelper = [update.propertiesDictionary objectForKey:@"updateHelper"];
    if ([updateHelper isEqualToString:@"true"]) {
        NSLog(@"We're updating the helper. Remove it so we can re-install on relaunch");
        [self uninstallHelper];
    }
}

- (void)uninstallHelper
{
    [self.helperConnectionManager connectAndExecuteCommandBlock:^(NSError *connectError) {
        if (connectError != nil) {
            [self error:[NSString stringWithFormat:@"Unable to connect to helper: %@", connectError]];
            return;
        }
        
        [[self.helperConnectionManager.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError *proxyError) {
            [self error:[NSString stringWithFormat:@"Proxy error: %@", proxyError]];
        }] uninstall:self.installerManager.authorization withReply:^(NSError *commandError) {
#pragma unused(commandError)
            if (commandError == nil) {
                NSLog(@"Helper tool successfully uninstalled");
            } else {
                [self error:@"There was a problem while trying to upgrade Focus. Please try again. If that doesn't work, you can re-open the app and click Uninstall in the menu (this will remove your settings). Then run the latest version. Sorry for any inconvenience."];
            }
        }];
    }];

}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    #pragma unused(notification)
    [self shutdown];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    #pragma unused(sender)
    return NO;
}

- (void)startup
{
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    
    long numRuns = [self.userDefaults integerForKey:@"numRuns"];
    [self.userDefaults setInteger:++numRuns forKey:@"numRuns"];
    [self.userDefaults synchronize];
    
    LogMessageCompat(@"Number of runs = %ld", numRuns);
    
    if (numRuns == 1) {
        [self firstRun];
    }
    
    self.installerManager = [[InstallerManager alloc] init];
    [self.installerManager run];
    
    // If we're not installed—just quit
    if (!self.installerManager.installed) {
        [self error:@"We're sorry, but Focus couldn't install it's helper correctly so we're exiting. Please try running Focus again to try re-installing."];
        [[NSApplication sharedApplication] terminate:nil];
        return;
    }
    
    // Setup connection
    ConnectionManager *connection = [[ConnectionManager alloc] init];
    [connection connectToHelperTool];
    
    // Connect to helper
    self.helperConnectionManager = [[ConnectionManager alloc] init];
    [self.helperConnectionManager connectToHelperTool];
    
    // Init Focus manager
    self.focus = [[Focus alloc] initWithHosts:[self.userDefaults arrayForKey:@"blockedSites"]];
    
    // Setup http proxy daemon
    [FocusHTTProxy killZombiedProxies];
    self.httpProxy = [[FocusHTTProxy alloc] init];
    [self.httpProxy start];
    
    // Setup launch agent toggle checkbox
    self.launchCheckbox.state = [self.installerManager willAutoLaunch];
    
    LogMessageCompat(@"willAutoLaunch = %d", self.installerManager.willAutoLaunch);
    
    // Setup menu icon toggle checkbox
    self.menuToggleCheckbox.state = [self.userDefaults boolForKey:@"menuIconTogglesFocus"];
    
    // Setup monochrome toggle checkbox
    self.monochromeIconCheckbox.state = [self.userDefaults boolForKey:@"monochromeIcon"];

    // Set active version on about screen
    [self.versionLabel setStringValue:[NSString stringWithFormat:@"v%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]];
    
    // Setup website link in about
    [self setupWebsiteLabel];
    
    [self loadBlockedSitesData];
    [self.removeBlockedSite setEnabled:NO];
    
    // Setup menubar
    [self createMenuBarItem];
    
    // This shouldn't ever really happen unless Focus crashes
    if ([self.focus isFocusing]) {
        LogMessageCompat(@"Focus was active when it started. Deactivating");
        [self goUnfocus];
    }
}

- (void)firstRun
{
    LogMessageCompat(@"Performing first time run setup");
    [self.userDefaults setObject:[Focus getDefaultHosts] forKey:@"blockedSites"];
    [self.userDefaults synchronize];
}

- (void)loadBlockedSitesData
{
    for (NSString *host in self.focus.hosts) {
        [self.blockedSitesArrayController addObject:[[NSMutableDictionary alloc] initWithDictionary:@{@"name": host}]];
    }
    
    [self.blockedSitesTableView reloadData];
}

- (void)saveBlockedSitesData
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        
        NSArray *blockedSites = [self.blockedSitesArrayController arrangedObjects];
        NSMutableArray *container = [[NSMutableArray alloc] init];
        
        for (NSDictionary *host in blockedSites)
        {
            [container addObject:[host objectForKey:@"name"]];
        }
        
        [self.userDefaults setObject:container forKey:@"blockedSites"];
        [self.userDefaults synchronize];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.focus.hosts = container;
            
            if ([self.focus isFocusing]) {
                [self toggleFocus];
                [self toggleFocus];
            }
        });
    });
}

- (void)resetBlockedSitesData
{
    NSRange range = NSMakeRange(0, [[self.blockedSitesArrayController arrangedObjects] count]);
    [self.blockedSitesArrayController removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];
}

- (void)setupWebsiteLabel
{
    NSURL* url = [NSURL URLWithString:@"http://heyfocus.com/?utm_source=focus_about"];
    
    NSMutableAttributedString* string = [[NSMutableAttributedString alloc] init];
    [string appendAttributedString:[NSAttributedString hyperlinkFromString:@"http://heyfocus.com" withURL:url]];
    
    [self.websiteLabel setAttributedStringValue:string];
    [self.websiteLabel setAllowsEditingTextAttributes:YES];
    [self.websiteLabel setSelectable:YES];
    [self.websiteLabel setAlignment:NSCenterTextAlignment];
}

- (void)shutdown
{
    LogMessageCompat(@"Shutting down");
    
    if ([self.focus isFocusing]) {
        [self goUnfocus];
    }
    
    [self.httpProxy stop];
}

- (void)createMenuBarItem {
    
    if (self.statusItem != nil) return;
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:24];

    self.statusItem.highlightMode = NO;
    
    self.statusItemView = [[RHStatusItemView alloc] initWithStatusBarItem:self.statusItem];
    [self.statusItem setView:self.statusItemView];
    [self.statusItemView setRightMenu:self.contextMenu];
    [self.statusItemView setRightAction:@selector(rightClickMenu)];
    [self setStatusItemViewIconOff];
    
    if (self.menuToggleCheckbox.state) {
        [self.statusItemView setAction:@selector(toggleFocus)];
    } else {
        [self.statusItemView setAction:@selector(rightClickMenu)];
    }
}

- (void)setStatusItemViewIconOff
{
    [self.statusItemView setImage:[NSImage imageNamed:@"menu-icon-off"]];
    [self.statusItemView setAlternateImage:[NSImage imageNamed:@"menu-icon-off-alt"]];
    [self.statusItemView setToolTip:@"Focus"];
    [self.focusAction setTitle:@"Focus"];
    self.statusItem.title = @"Focus";
}

- (void)setStatusItemViewIconOn
{
    if ([self.userDefaults boolForKey:@"monochromeIcon"]) {
        [self.statusItemView setImage:[NSImage imageNamed:@"menu-icon-on-gray"]];
    } else {
        [self.statusItemView setImage:[NSImage imageNamed:@"menu-icon-on"]];
    }
    
    [self.statusItemView setAlternateImage:[NSImage imageNamed:@"menu-icon-off-alt"]];
    [self.statusItemView setToolTip:@"Unfocus"];
    [self.focusAction setTitle:@"Unfocus"];
    self.statusItem.title = @"Unfocus";
}

- (void)rightClickMenu
{
    [self.statusItemView popUpRightMenu];
}

- (void)toggleFocus
{
    if ([self.statusItemView.toolTip isEqualToString:@"Focus"]) {
        [self goFocus];
    } else if ([self.statusItemView.toolTip isEqualToString:@"Unfocus"]) {
        [self goUnfocus];
    } else {
        [self error:@"Unknown Focus state"];
    }
}

- (bool)windowShouldClose
{
    return NO;
}

- (void)goFocus
{
    
    if (![FocusHTTProxy isRunning]) {
        LogMessageCompat(@"HTTP Proxy IS NOT RUNNING...starting it!");
        [self.httpProxy start];
    }
    
    LogMessageCompat(@"goFocusing with hosts = %@", self.focus.hosts);
    
    [self setStatusItemViewIconOn];

    [self.helperConnectionManager connectAndExecuteCommandBlock:^(NSError *connectError) {
        if (connectError != nil) {
            [self error:[NSString stringWithFormat:@"Unable to connect to helper: %@", connectError]];
            [self setStatusItemViewIconOff];
            return;
        }
        
        [[self.helperConnectionManager.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError *proxyError) {
            [self error:[NSString stringWithFormat:@"Proxy error: %@", proxyError]];
        }] focus:self.installerManager.authorization blockedHosts:self.focus.hosts withReply:^(NSError *commandError) {
            if (commandError != nil) {
                [self error:[NSString stringWithFormat:@"Error response from helper: %@", commandError]];
            }
        }];
    }];
}

- (void)goUnfocus
{
    LogMessageCompat(@"goUnfocusing");
    
    [self setStatusItemViewIconOff];
 
    [self.helperConnectionManager connectAndExecuteCommandBlock:^(NSError *connectError) {
        if (connectError != nil) {
            [self error:[NSString stringWithFormat:@"Unable to connect to helper: %@", connectError]];
            [self setStatusItemViewIconOn];
            return;
        }
        
        [[self.helperConnectionManager.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError *proxyError) {
            [self error:[NSString stringWithFormat:@"Proxy error: %@", proxyError]];
        }] unfocus:self.installerManager.authorization withReply:^(NSError *commandError) {
            if (commandError != nil) {
                [self error:[NSString stringWithFormat:@"Error response from helper: %@", commandError]];
            }
        }];
    }];
}

- (void)error:(NSString *)msg
{
    LogMessageCompat(@"ERROR = %@", msg);

    NSAlert *alertBox = [[NSAlert alloc] init];
    [alertBox setMessageText:@"An Error Occurred"];
    [alertBox setInformativeText:msg];
    [alertBox addButtonWithTitle:@"OK"];
    [alertBox runModal];
}

- (void)uninstall
{
    [self goUnfocus];
    
    // Reset NSUserDefaults — has to be done here rather than on helper
    NSString *domainName = [[NSBundle mainBundle] bundleIdentifier];
    [self.userDefaults removePersistentDomainForName:domainName];
    
    // Uninstall auto launch
    [self.installerManager uninstallAutoLaunch];
    
    [self.helperConnectionManager connectAndExecuteCommandBlock:^(NSError *connectError) {
        if (connectError != nil) {
            [self error:[NSString stringWithFormat:@"Unable to connect to helper: %@", connectError]];
            self.statusItem.title = @"Unfocus";
            [self setStatusItemViewIconOn];
            return;
        }
        
        [[self.helperConnectionManager.helperToolConnection remoteObjectProxyWithErrorHandler:^(NSError *proxyError) {
            [self error:[NSString stringWithFormat:@"Proxy error: %@", proxyError]];
        }] uninstall:self.installerManager.authorization withReply:^(NSError *commandError) {
#pragma unused(commandError)
            [[NSApplication sharedApplication] terminate:nil];
        }];
    }];
}

-(void)turnOnMenuIconTogglesFocus
{
    [self.userDefaults setObject:@YES forKey:@"menuIconTogglesFocus"];
    [self.userDefaults synchronize];
    [self.statusItemView setAction:@selector(toggleFocus)];
}

-(void)turnOffMenuIconTogglesFocus
{
    [self.userDefaults setObject:@NO forKey:@"menuIconTogglesFocus"];
    [self.userDefaults synchronize];
    [self.statusItemView setAction:@selector(rightClickMenu)];
}

- (void)turnMonochromeIconOn
{
    [self.userDefaults setObject:@YES forKey:@"monochromeIcon"];
    [self.userDefaults synchronize];
    
    if ([self.focus isFocusing]) {
        [self.statusItemView setImage:[NSImage imageNamed:@"menu-icon-on-gray"]];
    }
}

- (void)turnMonochromeIconOff
{
    [self.userDefaults setObject:@NO forKey:@"monochromeIcon"];
    [self.userDefaults synchronize];
    
    if ([self.focus isFocusing]) {
        [self.statusItemView setImage:[NSImage imageNamed:@"menu-icon-on"]];
    }
}

# pragma mark - IBAction

- (IBAction)clickedFocusMenuItem:(id)sender {
#pragma unused(sender)
    [self toggleFocus];
}

- (IBAction)clickedToggleFocusMenuIconCheckbox:(NSButton *)checkbox {
    if (checkbox.state) {
        [self turnOnMenuIconTogglesFocus];
    } else {
        [self turnOffMenuIconTogglesFocus];
    }
}

- (IBAction)clickedMonochromeIconCheckbox:(NSButton *)checkbox {
    if (checkbox.state) {
        [self turnMonochromeIconOn];
    } else {
        [self turnMonochromeIconOff];
    }
}

- (IBAction)toggledLaunchAtStartupCheckbox:(NSButton *)checkbox
{
    bool isChecked = [checkbox state];
    
    if (isChecked) {
        [self.installerManager installAutoLaunch];
    } else {
        [self.installerManager uninstallAutoLaunch];
    }
}

- (IBAction)clickedUninstallFocus:(id)sender {
#pragma unused(sender)
    
    NSAlert *alertBox = [[NSAlert alloc] init];
    [alertBox setMessageText:@"Are you sure you want to uninstall Focus?"];
    [alertBox setInformativeText:@"We will deactivate Focus, close it & uninstall, are you sure you want to continue?"];
    [alertBox addButtonWithTitle:@"OK"];
    [alertBox addButtonWithTitle:@"Cancel"];
    [alertBox setAlertStyle:NSWarningAlertStyle];
    NSInteger buttonClicked = [alertBox runModal];
    
    if (buttonClicked == NSAlertFirstButtonReturn) {
        [self.window close];
        [self uninstall];
    }
}

- (IBAction)clickedSettings:(id)sender {
#pragma unused(sender)
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)clickedExit:(id)sender {
#pragma unused(sender)
    [self applicationWillTerminate:nil];
    exit(0);
}

- (IBAction)clickedAddBlockedSiteButton:(NSButton *)button {
#pragma unused(button)
    LogMessageCompat(@"Clicked add site button");
    
    [self.window makeFirstResponder:nil];
    
    NSArray *blockedSites = [self.blockedSitesArrayController arrangedObjects];
    unsigned long lastRowIndex = [blockedSites count];
    
    [self.blockedSitesArrayController addObject:[[NSMutableDictionary alloc] initWithDictionary:@{@"name": @""}]];
    [self.blockedSitesTableView scrollToEndOfDocument:self];
    [self.blockedSitesTableView editColumn:0 row:(NSInteger)lastRowIndex withEvent:nil select:NO];
}

- (IBAction)clickedRemoveBlockedSiteButton:(NSButton *)button {
#pragma unused(button)
    
    LogMessageCompat(@"Clicked remove site button");
    [self.blockedSitesArrayController removeObjectsAtArrangedObjectIndexes:[self.blockedSitesTableView selectedRowIndexes]];
    [self.blockedSitesTableView deselectAll:self];
    
    [self saveBlockedSitesData];
}

- (IBAction)clickedResetToDefaultsBlockedSitesButton:(NSButton *)button {
#pragma unused(button)
    
    NSAlert *alertBox = [[NSAlert alloc] init];
    [alertBox setMessageText:@"Are you sure you want to reset your blocked sites?"];
    [alertBox setInformativeText:@"All current sites will be removed and replaced with what is shipped by default. This can't be undone."];
    [alertBox addButtonWithTitle:@"OK"];
    [alertBox addButtonWithTitle:@"Cancel"];
    [alertBox setAlertStyle:NSWarningAlertStyle];
    NSInteger buttonClicked = [alertBox runModal];
    
    if (buttonClicked == NSAlertFirstButtonReturn) {
        LogMessageCompat(@"Resetting to blocked sites defaults");
        
        self.focus.hosts = [Focus getDefaultHosts];
        [self resetBlockedSitesData];
        [self loadBlockedSitesData];
        [self saveBlockedSitesData];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
#pragma unused(notification)
    long selectedRow = [self.blockedSitesTableView selectedRow];
    if (selectedRow >= 0) {
        [self.removeBlockedSite setEnabled:YES];
    } else {
        [self.removeBlockedSite setEnabled:NO];
    }
}


- (void)controlTextDidEndEditing:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSTextView *aView = [userInfo valueForKey:@"NSFieldEditor"];
    NSString *savedObject = [aView string];
    NSLog(@"controlTextDidEndEditing %@", savedObject);
    
    long selectedRow = [self.blockedSitesTableView selectedRow];
    NSLog(@"Selected row = %ld", selectedRow);
    
    bool empty = [[savedObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0;
    
    if (empty) {
        LogMessageCompat(@"Row is empty, let's delete it");
        [self.blockedSitesArrayController removeObjectAtArrangedObjectIndex:(NSUInteger)selectedRow];
    } else {
        [self saveBlockedSitesData];
    }
}

@end
