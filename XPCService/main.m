#include <Foundation/Foundation.h>

#include "XPCService.h"

int main(int argc, const char *argv[])
{
    #pragma unused(argc)
    #pragma unused(argv)

    // We just create and start an instance of the main XPC service object and then 
    // have it resume the XPC service listener.

    @autoreleasepool {
        XPCService *        m;

        m = [[XPCService alloc] init];
        assert(m != nil);
        
        [m run];                // This never comes back...
    }
    
	return EXIT_FAILURE;        // ... so this should never be hit.
}
