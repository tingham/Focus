//
//  NSAttributedString+hyperlinkFromString.h
//  Focus
//
//  Created by Brad Jasper on 12/20/13.
//
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (Hyperlink)
+(id)hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL;
@end
