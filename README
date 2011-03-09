NSObject+NSCoding and Archiver
------------------------------

Mike Mayo
Rackspace Mobile Apps
mike@overhrd.com
twitter: @greenisus

These are some simple classes to make object persistence with NSCoding easier.  This code was extracted from
the Rackspace Cloud / OpenStack iOS app at http://launchpad.net/openstack-ios

INSTALLATION

To install, simply drag Archiver.h, Archiver.m, NSObject+NSCoding.h, and NSObject+NSCoding.m into your project.

Then, right click Frameworks in Groups & Files and choose Add -> Existing Frameworks... and choose libobjc.A.dylib.

USAGE

-- Archiver

This class will read and write objects that conform to the NSCoding protocol to disk.

Archiver Usage:

SomeClass *myObject = [[[SomeClass alloc] init] autorelease];
myObject.someProperty = @"Hello world";

[Archiver persist:myObject key:@"myObject"];

// later on somewhere else...

SomeClass *myObject = [Archiver retrieve:@"myObject"];

-- NSObject+NSCoding

This category simplifies implementing NSCoding by iterating over the properties of your
class and encoding/decoding them for you.  It persists primitives (such as ints and floats)
as well as any objects that conform to NSCoding.

NSObject+NSCoding Usage:

In your class header, conform to NSCoding:

@interface Model : NSObject <NSCoding> {
//...
}

In your class implementation, call the automatic methods:

- (void)encodeWithCoder:(NSCoder *)coder {
    [self autoEncodeWithCoder:coder];
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        [self autoDecode:coder];
    }
    return self;
}
