@interface UIStatusBarForegroundView : UIView
@property(readonly) int foregroundStyle;
@end

@interface SBWiFiManager : NSObject
+ (id)sharedInstance;
- (void)_primaryInterfaceChanged:(BOOL)arg1;
- (id)_wifiInterface;
- (BOOL)isPrimaryInterface;
- (void)resetSettings;
- (id)knownNetworks;
- (void)updateSignalStrength;
- (void)updateSignalStrengthFromRawRSSI:(int)arg1 andScaledRSSI:(float)arg2;
- (int)signalStrengthRSSI;
- (int)signalStrengthBars;
- (void)setWiFiEnabled:(BOOL)arg1;
- (BOOL)wiFiEnabled;
- (BOOL)isPowered;
- (id)currentNetworkName;
- (BOOL)_cachedIsAssociated;
- (BOOL)isAssociatedToIOSHotspot;
- (BOOL)isAssociated;
- (void)_updateCurrentNetwork;
- (void)_updateWiFiDevice:(id)arg1;
- (void)_linkDidChange;
- (void)_powerStateDidChange;
- (void)_updateWiFiState;
//- (struct __WiFiManagerClient *)_manager;
//- (void)_setWiFiDevice:(struct __WiFiDeviceClient *)arg1;
- (id)init;

@end

@interface UIStatusBarDataNetworkItemView : UIView
@end

#import <objc/runtime.h>

#include <ifaddrs.h>
#include <arpa/inet.h>


inline NSString *GetIPAddress()
{
        NSString *result = nil;
        struct ifaddrs *interfaces;
        char str[INET_ADDRSTRLEN];
        if (getifaddrs(&interfaces))
                return nil;
        struct ifaddrs *test_addr = interfaces;
        while (test_addr) {
                if(test_addr->ifa_addr->sa_family == AF_INET) {
                        if (strcmp(test_addr->ifa_name, "en0") == 0) {
                                inet_ntop(AF_INET, &((struct sockaddr_in *)test_addr->ifa_addr)->sin_addr, str, INET_ADDRSTRLEN);
                                result = [NSString stringWithUTF8String:str];
                                break;
                        }
                }
                test_addr = test_addr->ifa_next;
        }
        freeifaddrs(interfaces);
        return result;
}

inline NSString *WiFiInfoString()
{
	NSString *network = [[objc_getClass("SBWiFiManager") sharedInstance] currentNetworkName] ?: @"Not connected";
	NSString *ip = GetIPAddress() ?: @"";
	return [NSString stringWithFormat:@"%@ %@",network,ip];
}


%hook UIStatusBarDataNetworkItemView
-(void)setUserInteractionEnabled:(BOOL)set
{
	%orig(YES);
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (![[objc_getClass("SBWiFiManager") sharedInstance] wiFiEnabled]) return;


	UIView *overlayView = [[UIView alloc] initWithFrame:self.superview.bounds];
	overlayView.backgroundColor = [UIColor clearColor];
	overlayView.alpha = 0.f;

	UILabel *infoLabel = [[UILabel alloc] initWithFrame:overlayView.bounds];
	infoLabel.backgroundColor = [UIColor clearColor];
	infoLabel.font = [UIFont boldSystemFontOfSize:13];
	infoLabel.textColor = [UIColor whiteColor];
	infoLabel.textAlignment = NSTextAlignmentCenter;
	infoLabel.text = WiFiInfoString();
	[overlayView addSubview:infoLabel];
	[infoLabel release];

	[self.superview addSubview:overlayView];

	//Fade overlay in
	[UIView animateWithDuration:0.2 animations:^{
		for (UIView *item in self.superview.subviews)
		{
			item.alpha = 0.f;
		}
	} completion:^(BOOL meh){
		[UIView animateWithDuration:0.2 animations:^{
			overlayView.alpha = 1.f;
		}];
	}];

	//After delay
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
		//Fade overlay out
		[UIView animateWithDuration:0.2 animations:^{
			overlayView.alpha = 0.f;
		} completion:^(BOOL meh){
			[overlayView removeFromSuperview];
			[overlayView release];
			[UIView animateWithDuration:0.2 animations:^{
				for (UIView *item in self.superview.subviews)
				{
					item.alpha = 1.f;
				}
			}];
		}];
	});
}
%end

