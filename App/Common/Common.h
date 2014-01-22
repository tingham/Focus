#include <Foundation/Foundation.h>

@interface Common : NSObject

+ (NSString *)authorizationRightForCommand:(SEL)command;
+ (void)setupAuthorizationRights:(AuthorizationRef)authRef;

@end
