// #import <cocoa/cocoa.h>
#import <CoreLocation/CoreLocation.h>
#include <node.h>

using namespace v8;

@interface LLHolder : NSObject {
    double latitude;
    double longitude;
    int worked;
}

- (void)reset;
- (int)useData;
- (void)latitude:(double*)lat longitude:(double*)log;

- (void)logLonLat:(CLLocation*)location;
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation;
    - (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;
    @end

    @implementation LLHolder

    - (void)reset {
    worked = 0;
}

- (int)useData {
    return worked;
}

- (void)latitude:(double*)lat longitude:(double*)log {
    *lat = latitude;
    *log = longitude;
}

- (void)logLonLat:(CLLocation*)location {
    worked = 1;
    CLLocationCoordinate2D coordinate = location.coordinate;
    latitude = coordinate.latitude;
    longitude = coordinate.longitude;

    CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        [self logLonLat:newLocation];
        [pool drain];
    }

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    latitude = 0.0;
    longitude = 0.0;
    CFRunLoopStop(CFRunLoopGetCurrent());
}
@end

id g_lm = nil;

int int_coreloc_enable() {
    if ([CLLocationManager locationServicesEnabled]) {
        g_lm = [[CLLocationManager alloc] init];
        return 1;
    }
    return 0;
}

int int_coreloc_get(double* lat, double* log) {
    LLHolder* obj = [[LLHolder alloc] init];
    [g_lm setDelegate:obj];
    [g_lm startUpdatingLocation];

    CFRunLoopRun();

    [g_lm stopUpdatingLocation];

    if([obj useData] == 1) {
        [obj latitude: lat longitude: log];
        [obj release];
        return 1;
    }

    [obj release];
    return 0;
}

// int main(int ac,char *av[])
// {
//     id obj = [[NSObject alloc] init];
//     id lm = nil;
//     if ([CLLocationManager locationServicesEnabled]) {
//         printf("location service enabled\n");
//         lm = [[CLLocationManager alloc] init];
//         [lm setDelegate:obj];
//         [lm startUpdatingLocation];
//     }
//     CFRunLoopRun();
//     [lm release];
//     [obj release];
//     return 0;
// }

// This function returns a JavaScript number that is either 0 or 1.
Handle<Value> GetLocation(const Arguments& args) {
    // At the top of every function that uses anything about v8, include a
    // definition like this. It ensures that any v8 handles you create in that
    // function are properly cleaned up. If you see memory rising in your
    // application, chances are that a scope isn't properly cleaned up.
    HandleScope scope;


    id obj = [[NSObject alloc] init];
    id lm = nil;
    if ([CLLocationManager locationServicesEnabled]) {
        printf("location service enabled\n");
        lm = [[CLLocationManager alloc] init];
        [lm setDelegate:obj];
        [lm startUpdatingLocation];
    }
    CFRunLoopRun();
    [lm release];
    [obj release];


    // When returning a value from a function, make sure to wrap it in
    // scope.Close(). This ensures that the handle stays valid after the current
    // scope (declared with the previous statement) is cleaned up.
    return scope.Close(
        // Creating a new JavaScript integer is as simple as passing a C int
        // (technically a int32_t) to this function.
        Integer::New(rand() % 2)
    );
}

void RegisterModule(v8::Handle<v8::Object> target) {
    // You can add properties to the module in this function. It is called
    // when the module is required by node.
    srand(time(NULL));

    // target is the module object you see when require()ing the .node file.
    target->Set(String::NewSymbol("getLocation"),
        FunctionTemplate::New(GetLocation)->GetFunction());
}

// Register the module with node. Note that "modulename" must be the same as
// the basename of the resulting .node file. You can specify that name in
// binding.gyp ("target_name"). When you change it there, change it here too.
NODE_MODULE(node_corelocation, RegisterModule);
